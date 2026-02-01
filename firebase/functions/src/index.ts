import { SecretManagerServiceClient } from "@google-cloud/secret-manager";
import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { onCall, onRequest } from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import { defineSecret } from "firebase-functions/params";
import { App } from "octokit";

import { v4 as uuidv4 } from "uuid";

initializeApp();
const db = getFirestore();
const secretManagerClient = new SecretManagerServiceClient();

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
        action: body.action,
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
        logger.info(`Push to ${body.ref}`, { structuredData: true });
        await createBuildJobs(app, eventData);
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

const buildJobCollectionPath = "build_jobs_v0";
const secretsCollectionPath = "secrets_v0";

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
  let triggerType: string | null = null;

  if (event === "pull_request") {
    branch = payload.pull_request.base.ref;
    triggerType = "pullRequest";
  } else if (event === "push") {
    branch = payload.ref.replace("refs/heads/", "");
    triggerType = "push";
  }

  if (!branch || !triggerType) {
    logger.info(`Skipping event ${event}: unable to determine branch or trigger type`);
    return;
  }

  const workflowSnapshot = await db
    .collection("workflows_v1")
    .where("workflowConfig.selectedRepository", "==", params.repository)
    .where("workflowConfig.selectedTriggerType", "==", triggerType)
    .where("workflowConfig.selectedTriggerBranch", "==", branch)
    .get();

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

  const commitSha =
    event === "pull_request"
      ? payload.pull_request?.head?.sha
      : payload.head_commit?.id || payload.after;
  const pullRequestNumber = payload.pull_request?.number || null;

  for (const doc of workflowSnapshot.docs) {
    const workflow = doc.data();
    const workflowId = doc.id;
    const userId = workflow.userId ?? null;
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
    await db
      .collection(buildJobCollectionPath)
      .doc(documentId)
      .set({
        ...params,
        updatedAt: FieldValue.serverTimestamp(),
        createdAt: FieldValue.serverTimestamp(),
        status: "queued",
        id: documentId,
        userId,
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
      });
  }
}

export const createSecretV1 = onCall(
  {
    region: "asia-northeast1",
  },
  async (request) => {
    if (!request.auth) {
      throw new Error("Unauthenticated");
    }

    const userId = request.auth.uid;
    const { name, value } = request.data as { name: string; value: string };

    if (!name || !value) {
      throw new Error("Missing name or value");
    }

    const projectId = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT;
    if (!projectId) {
      throw new Error("Project ID not found");
    }

    const secretId = `user-${userId}-${name}`;
    const parent = `projects/${projectId}`;

    try {
      await secretManagerClient.createSecret({
        parent,
        secretId,
        secret: {
          replication: {
            automatic: {},
          },
        },
      });

      await secretManagerClient.addSecretVersion({
        parent: `${parent}/secrets/${secretId}`,
        payload: {
          data: Buffer.from(value, "utf8"),
        },
      });

      const documentId = uuidv4();
      await db
        .collection(secretsCollectionPath)
        .doc(documentId)
        .set({
          id: documentId,
          name,
          userId,
          pathToSecret: `${parent}/secrets/${secretId}`,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });

      logger.info(`Secret created: ${secretId}`, { userId, name });

      return { success: true, documentId };
    } catch (error: any) {
      if (error.code === 6) {
        await secretManagerClient.addSecretVersion({
          parent: `${parent}/secrets/${secretId}`,
          payload: {
            data: Buffer.from(value, "utf8"),
          },
        });

        const existingDocs = await db
          .collection(secretsCollectionPath)
          .where("userId", "==", userId)
          .where("name", "==", name)
          .limit(1)
          .get();

        let documentId: string;
        if (existingDocs.empty) {
          documentId = uuidv4();
          await db
            .collection(secretsCollectionPath)
            .doc(documentId)
            .set({
              id: documentId,
              name,
              userId,
              pathToSecret: `${parent}/secrets/${secretId}`,
              createdAt: FieldValue.serverTimestamp(),
              updatedAt: FieldValue.serverTimestamp(),
            });
          logger.info(`Secret document created for existing secret: ${secretId}`, { userId, name });
        } else {
          documentId = existingDocs.docs[0].id;
        }

        logger.info(`Secret updated: ${secretId}`, { userId, name });
        return { success: true, documentId };
      }

      logger.error("Failed to create secret", error);
      throw new Error(`Failed to create secret: ${error.message}`);
    }
  },
);
