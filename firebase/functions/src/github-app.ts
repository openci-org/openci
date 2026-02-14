import { FieldValue } from "firebase-admin/firestore";
import { onRequest } from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import { defineSecret } from "firebase-functions/params";
import { App } from "octokit";
import { v4 as uuidv4 } from "uuid";

import { db } from "./firebase";
import { buildJobsCollectionPath, workflowsCollectionPath } from "./firestore-collection-paths";

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

      if (event === "pull_request") {
        if (body.action === "opened" || body.action === "synchronize") {
          logger.info(`PR ${body.action}`, { structuredData: true });
          await createBuildJobs(app, eventData);
        }
      } else if (event === "push") {
        if (body.ref.startsWith("refs/tags/")) {
          logger.info(`Skipping push event for tag ${body.ref}`, { structuredData: true });
        } else {
          logger.info(`Push to ${body.ref}`, { structuredData: true });
          await createBuildJobs(app, eventData);
        }
      } else if (event === "create") {
        if (body.ref_type === "tag") {
          logger.info(`Tag created: ${body.ref}`, { structuredData: true });
          await createBuildJobs(app, eventData);
        }
      } else if (event === "issue_comment") {
        if (body.action === "created" && body.comment.body.includes("@openci rerun")) {
          logger.info("Rerun requested via comment", { structuredData: true });
        }
      }

      response.send("ok");
    } catch (error) {
      logger.error(error);
      response.status(500).send("Error");
    }
  },
);

async function createBuildJobs(
  app: App,
  params: {
    event: string;
    action: string;
    repository: string;
    sender: string;
    payload: any;
  },
) {
  const { payload, event } = params;

  let branch: string | null = null;
  let triggerBranch: string | null = null;
  let triggerType: string | null = null;
  let tagName: string | null = null;

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
  }

  if (!triggerType || (triggerType !== "tag" && !triggerBranch)) {
    logger.info(`Skipping event ${event}: unable to determine trigger type`);
    return;
  }

  let workflowQuery = db
    .collection(workflowsCollectionPath)
    .where("workflowConfig.selectedRepository", "==", params.repository)
    .where("workflowConfig.selectedTriggerType", "==", triggerType);

  if (triggerType !== "tag" && triggerBranch) {
    workflowQuery = workflowQuery.where(
      "workflowConfig.selectedTriggerBranch",
      "==",
      triggerBranch,
    );
  }

  const workflowSnapshot = await workflowQuery.get();

  if (workflowSnapshot.empty) {
    logger.info(`No workflows found for ${params.repository} on ${branch} (${triggerType})`);
    return;
  }

  logger.info(
    `Found ${workflowSnapshot.size} workflows matching ${params.repository} on ${branch}`,
  );

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

  if (triggerType === "tag" && tagName && octokit) {
    try {
      const { data: commit } = await octokit.request("GET /repos/{owner}/{repo}/commits/{ref}", {
        owner: params.repository.split("/")[0],
        repo: params.repository.split("/")[1],
        ref: tagName,
      });
      commitSha = commit.sha;
    } catch (error) {
      logger.error("Failed to fetch commit SHA for tag", error);
    }
  }
  const pullRequestNumber = payload.pull_request?.number || null;

  for (const doc of workflowSnapshot.docs) {
    const workflow = doc.data();
    const workflowId = doc.id;
    const teamId = workflow.teamId ?? null;
    const checkRunName = workflow.name;

    let checkRunId: number | null = null;

    if (octokit && commitSha) {
      try {
        const { data: checkRun } = await octokit.request("POST /repos/{owner}/{repo}/check-runs", {
          owner: params.repository.split("/")[0],
          repo: params.repository.split("/")[1],
          name: checkRunName,
          head_sha: commitSha,
          status: "queued",
          started_at: new Date().toISOString(),
        });
        checkRunId = checkRun.id;
      } catch (error) {
        logger.error(`Failed to create check run for workflow ${workflowId}`, error);
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
        workflowId,
        installationId,
        commitSha,
        pullRequestNumber,
        owner: params.repository.split("/")[0],
        repo: params.repository.split("/")[1],
        installationToken,
        tokenExpiresAt,
        checkRunId,
        runCount: 0,
        latestRunId: null,
        tagName,
        branch,
      });
  }
}
