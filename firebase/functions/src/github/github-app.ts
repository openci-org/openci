import { FieldValue } from "firebase-admin/firestore";
import { onRequest } from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import { defineSecret } from "firebase-functions/params";
import { App } from "octokit";
import { v4 as uuidv4 } from "uuid";

import { db } from "../firebase";
import { buildJobsCollectionPath, workflowFilesCollectionPath } from "../firestore-collection-paths";
import { OPENCI_DIR_QUERY, OpenciDirEntry } from "./queries";
import { syncWorkflowFilesToFirestore, workflowFileDocId } from "./sync-workflow-files";

const GITHUB_APP_ID = defineSecret("GITHUB_APP_ID");
const GITHUB_PRIVATE_KEY = defineSecret("GITHUB_PRIVATE_KEY");
const GITHUB_WEBHOOK_SECRET = defineSecret("GITHUB_WEBHOOK_SECRET");

export const githubApp = onRequest(
  {
    region: "asia-northeast1",
    memory: "512MiB",
    secrets: [GITHUB_APP_ID, GITHUB_PRIVATE_KEY, GITHUB_WEBHOOK_SECRET],
  },
  async (request, response) => {
    const app = new App({
      appId: GITHUB_APP_ID.value(),
      privateKey: GITHUB_PRIVATE_KEY.value(),
      webhooks: {
        secret: GITHUB_WEBHOOK_SECRET.value(),
      },
    });

    const signature = request.headers["x-hub-signature-256"] as string;
    const payload = (request as any).rawBody
      ? (request as any).rawBody.toString()
      : JSON.stringify(request.body);

    try {
      const verified = await app.webhooks.verify(payload, signature);
      if (!verified) {
        logger.error("Invalid signature");
        response.status(401).send("Unauthorized");
        return;
      }

      const event = request.headers["x-github-event"] as string;
      const body = JSON.parse(payload);

      const eventData = {
        event,
        action: body.action ?? null,
        repository: body.repository?.full_name,
        sender: body.sender?.login,
        createdAt: FieldValue.serverTimestamp(),
        payload: body,
      };

      let result: BuildJobsResult = { createdJobs: 0, errors: 0 };

      if (event === "pull_request") {
        if (body.action === "opened" || body.action === "synchronize") {
          logger.info(`PR ${body.action}`, { structuredData: true });
          result = await createBuildJobs(app, eventData);
        }
      } else if (event === "push") {
        if (body.ref.startsWith("refs/tags/")) {
          logger.info(`Skipping push event for tag ${body.ref}`, { structuredData: true });
        } else {
          logger.info(`Push to ${body.ref}`, { structuredData: true });
          result = await createBuildJobs(app, eventData);

          // Sync .openci/ workflow files to Firestore
          const pushBranch = body.ref.replace("refs/heads/", "");
          const pushRepo = body.repository?.full_name;
          const pushInstallationId = body.installation?.id;
          if (pushRepo && pushInstallationId) {
            try {
              const pushTeamId = await findTeamIdForInstallation(pushInstallationId);
              if (pushTeamId) {
                const octokit = await app.getInstallationOctokit(pushInstallationId);
                await syncWorkflowFilesToFirestore({
                  teamId: pushTeamId,
                  repository: pushRepo,
                  branch: pushBranch,
                  octokit,
                });
              }
            } catch (syncError) {
              logger.error("Failed to sync workflow files on push", syncError);
            }
          }
        }
      } else if (event === "create") {
        if (body.ref_type === "tag") {
          logger.info(`Tag created: ${body.ref}`, { structuredData: true });
          result = await createBuildJobs(app, eventData);
        }
      } else if (event === "release") {
        if (body.action === "published") {
          logger.info(`Release published: ${body.release?.tag_name}`, { structuredData: true });
          result = await createBuildJobs(app, eventData);

          // Auto-update Worker CLI version in Firestore
          await updateWorkerCliVersion(body);
        }
      } else if (event === "issue_comment") {
        if (body.action === "created" && body.comment.body.includes("@openci rerun")) {
          logger.info("Rerun requested via comment", { structuredData: true });
        }
      }

      response.send({ status: "ok", ...result });
    } catch (error) {
      logger.error(error);
      response.status(500).send("Error");
    }
  },
);

interface BuildJobsResult {
  createdJobs: number;
  errors: number;
}

async function createBuildJobs(
  app: App,
  params: {
    event: string;
    action: string;
    repository: string;
    sender: string;
    payload: any;
  },
): Promise<BuildJobsResult> {
  const { payload, event } = params;
  const [owner, repo] = params.repository.split("/");

  let branch: string | null = null;
  let triggerBranch: string | null = null;
  let triggerType: string | null = null;
  let tagName: string | null = null;
  let releaseName: string | null = null;

  if (event === "pull_request") {
    branch = payload.pull_request.head.ref;
    triggerBranch = payload.pull_request.base.ref;
    triggerType = "pullRequest";
  } else if (event === "push") {
    branch = payload.ref.replace("refs/heads/", "");
    triggerBranch = branch;
    triggerType = "push";
  } else if (event === "create" && payload.ref_type === "tag") {
    tagName = payload.ref;
    triggerType = "tag";
  } else if (event === "release" && payload.action === "published") {
    tagName = payload.release?.tag_name ?? null;
    releaseName = payload.release?.name ?? null;
    triggerType = "release";
  }

  if (!triggerType || (!["tag", "release"].includes(triggerType) && !triggerBranch)) {
    logger.info(`Skipping event ${event}: unable to determine trigger type`);
    return { createdJobs: 0, errors: 0 };
  }

  const installationId = payload.installation?.id;
  let installationToken: string | null = null;
  let tokenExpiresAt: string | null = null;
  let octokit: any = null;

  if (installationId) {
    try {
      octokit = await app.getInstallationOctokit(installationId);
      const {
        data: { token, expires_at },
      } = await octokit.request("POST /app/installations/{installation_id}/access_tokens", {
        installation_id: installationId,
      });
      installationToken = token;
      tokenExpiresAt = expires_at;
    } catch (error) {
      logger.error("Failed to authenticate with GitHub", error);
    }
  }

  let commitSha =
    event === "pull_request"
      ? payload.pull_request?.head?.sha
      : payload.head_commit?.id || payload.after;

  if ((triggerType === "tag" || triggerType === "release") && tagName && octokit) {
    try {
      const { data: commit } = await octokit.request("GET /repos/{owner}/{repo}/commits/{ref}", {
        owner,
        repo,
        ref: tagName,
      });
      commitSha = commit.sha;
    } catch (error) {
      logger.error("Failed to fetch commit SHA for tag", error);
    }
  }

  const pullRequestNumber = payload.pull_request?.number || null;
  let createdJobCount = 0;
  let errorCount = 0;

  // --- .openci/ YAML workflows (GraphQL: single request) ---
  if (octokit) {
    try {
      const ref =
        commitSha ||
        (triggerType === "push" || triggerType === "pullRequest"
          ? `heads/${triggerBranch}`
          : undefined);

      let entries: OpenciDirEntry[] = [];
      try {
        const result = await octokit.graphql(OPENCI_DIR_QUERY, {
          owner,
          repo,
          expression: `${ref}:.openci`,
        });
        entries = result.repository.object?.entries ?? [];
      } catch (e: any) {
        if (!e.message?.includes("Could not resolve to an object")) {
          logger.warn("Failed to list .openci/ directory", e);
        }
      }

      const yamlEntries = entries.filter(
        (entry) =>
          entry.type === "blob" &&
          (entry.name.endsWith(".yaml") || entry.name.endsWith(".yml")) &&
          entry.object?.text,
      );

      for (const entry of yamlEntries) {
        try {
          const yaml = await import("js-yaml");
          const parsed = yaml.load(entry.object!.text) as any;
          if (!parsed || typeof parsed !== "object") continue;

          const workflowName = parsed.name || entry.name.replace(/\.(yaml|yml)$/, "");

          if (!matchesTrigger(parsed, triggerType, triggerBranch)) {
            logger.info(
              `Workflow ${entry.name} does not match trigger ${triggerType}/${triggerBranch}`,
            );
            continue;
          }

          const steps = extractSteps(parsed);
          if (steps.length === 0) {
            logger.info(`Workflow ${entry.name} has no steps, skipping`);
            continue;
          }

          const teamId = await findTeamIdForInstallation(installationId);

          // Check if workflow is disabled in Firestore
          if (teamId) {
            const wfBranch = triggerBranch ?? "HEAD";
            const docId = workflowFileDocId(teamId, params.repository, wfBranch, entry.name);
            const wfDoc = await db.collection(workflowFilesCollectionPath).doc(docId).get();
            if (wfDoc.exists && wfDoc.data()?.enabled === false) {
              logger.info(`Workflow ${entry.name} is disabled, skipping`);
              continue;
            }
          }

          logger.info(`Matched .openci/${entry.name} with ${steps.length} steps`);

          let checkRunId: number | null = null;
          if (commitSha) {
            try {
              const { data: checkRun } = await octokit.request(
                "POST /repos/{owner}/{repo}/check-runs",
                {
                  owner,
                  repo,
                  name: workflowName,
                  head_sha: commitSha,
                  status: "queued",
                  started_at: new Date().toISOString(),
                },
              );
              checkRunId = checkRun.id;
            } catch (error) {
              logger.error(`Failed to create check run for ${entry.name}`, error);
            }
          }

          const documentId = uuidv4();
          const jobData = { ...params };
          delete jobData.payload;

          await db
            .collection(buildJobsCollectionPath)
            .doc(documentId)
            .set({
              ...jobData,
              updatedAt: FieldValue.serverTimestamp(),
              createdAt: FieldValue.serverTimestamp(),
              status: "queued",
              id: documentId,
              teamId,
              workflowFileName: entry.name,
              installationId,
              commitSha,
              pullRequestNumber,
              owner,
              repo,
              installationToken,
              tokenExpiresAt,
              checkRunId,
              runCount: 0,
              latestRunId: null,
              tagName,
              branch,
              releaseName,
            });

          createdJobCount++;
        } catch (e) {
          logger.error(`Failed to process .openci/${entry.name}`, e);
          errorCount++;
        }
      }
    } catch (error) {
      logger.error("Failed to read .openci/ workflows", error);
    }
  }

  if (createdJobCount === 0) {
    logger.info(`No workflows found for ${params.repository} on ${branch} (${triggerType})`);
  } else {
    logger.info(`Created ${createdJobCount} build jobs for ${params.repository}`);
  }

  return { createdJobs: createdJobCount, errors: errorCount };
}

function matchesTrigger(parsed: any, triggerType: string, triggerBranch: string | null): boolean {
  const on = parsed.on;
  if (!on) return false;

  const yamlTriggerKey = triggerType === "pullRequest" ? "pull_request" : triggerType;

  if (typeof on === "string") {
    return on === yamlTriggerKey;
  }

  if (Array.isArray(on)) {
    return on.includes(yamlTriggerKey);
  }

  if (typeof on === "object") {
    const triggerConfig = on[yamlTriggerKey];
    if (triggerConfig === undefined) return false;
    if (triggerConfig === null) return true;

    if (typeof triggerConfig === "object" && triggerConfig.branches) {
      const branches: string[] = Array.isArray(triggerConfig.branches)
        ? triggerConfig.branches
        : [triggerConfig.branches];
      if (triggerBranch && !branches.includes(triggerBranch)) {
        return false;
      }
    }

    return true;
  }

  return false;
}

function extractSteps(
  parsed: any,
): Array<{ name: string; run?: string; uses?: string; with?: Record<string, string> }> {
  const steps: Array<{ name: string; run?: string; uses?: string; with?: Record<string, string> }> =
    [];
  const jobs = parsed.jobs;
  if (!jobs || typeof jobs !== "object") return steps;

  for (const jobKey of Object.keys(jobs)) {
    const job = jobs[jobKey];
    if (!job || !Array.isArray(job.steps)) continue;

    for (const step of job.steps) {
      if (!step || typeof step !== "object") continue;

      const entry: { name: string; run?: string; uses?: string; with?: Record<string, string> } = {
        name: step.name || "",
      };

      if (step.uses) {
        entry.uses = step.uses;
        if (step.with && typeof step.with === "object") {
          entry.with = {};
          for (const [k, v] of Object.entries(step.with)) {
            entry.with[k] = String(v);
          }
        }
      } else if (step.run) {
        entry.run = step.run;
      }

      steps.push(entry);
    }
  }

  return steps;
}

async function findTeamIdForInstallation(installationId: number): Promise<string | null> {
  try {
    const teamsSnapshot = await db
      .collection("teams_v0")
      .where("installationIds", "array-contains", installationId)
      .limit(1)
      .get();

    if (teamsSnapshot.empty) return null;
    return teamsSnapshot.docs[0].id;
  } catch (e) {
    logger.error("Failed to find team for installation", e);
    return null;
  }
}

async function updateWorkerCliVersion(body: any): Promise<void> {
  try {
    const repoFullName = body.repository?.full_name;
    if (repoFullName !== "open-ci-io/openci") return;

    const assets = body.release?.assets ?? [];
    const hasWorkerAsset = assets.some(
      (a: any) => (a.name as string).startsWith("openci-worker-"),
    );
    if (!hasWorkerAsset) return;

    const tagName = body.release?.tag_name as string | undefined;
    if (!tagName) return;

    const version = tagName.startsWith("v") ? tagName.substring(1) : tagName;

    await db.collection("config").doc("workerCli").set(
      {
        latestVersion: version,
        updatedAt: FieldValue.serverTimestamp(),
        releaseUrl: body.release?.html_url ?? null,
      },
      { merge: true },
    );

    logger.info(`Updated Worker CLI version to ${version}`);
  } catch (e) {
    logger.error("Failed to update Worker CLI version", e);
  }
}
