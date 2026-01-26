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
          await saveBuildJob(app, eventData);
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

const buildJobCollectionPath = "build_jobs_v0";
const secretsCollectionPath = "secrets_v0";

async function saveBuildJob(
  app: App,
  params: {
    event: string;
    action: string;
    repository: string;
    sender: string;
    payload: any;
  },
) {
  const { payload } = params;
  const documentId = uuidv4();

  const installationId = payload.installation?.id;
  const commitSha = payload.pull_request?.head?.sha || null;
  const pullRequestNumber = payload.pull_request?.number || payload.issue?.number;

  let installationToken: string | null = null;
  let tokenExpiresAt: string | null = null;
  let checkRunId: number | null = null;

  if (installationId) {
    try {
      const octokit = await app.getInstallationOctokit(installationId);

      // Get installation token
      const {
        data: { token, expires_at },
      } = await octokit.request("POST /app/installations/{installation_id}/access_tokens", {
        installation_id: installationId,
      });
      installationToken = token;
      tokenExpiresAt = expires_at;

      // Create Check Run if we have a commit SHA
      if (commitSha) {
        const { data: checkRun } = await octokit.request("POST /repos/{owner}/{repo}/check-runs", {
          owner: params.repository.split("/")[0],
          repo: params.repository.split("/")[1],
          name: "OpenCI",
          head_sha: commitSha,
          status: "queued",
          started_at: new Date().toISOString(),
        });
        checkRunId = checkRun.id;
      }
    } catch (error) {
      logger.error("Failed to authenticate or create check run", error);
    }
  }

  await db
    .collection(buildJobCollectionPath)
    .doc(documentId)
    .set({
      ...params,
      updatedAt: FieldValue.serverTimestamp(),
      createdAt: FieldValue.serverTimestamp(),
      status: "queued",
      id: documentId,
      installationId,
      commitSha,
      pullRequestNumber,
      owner: params.repository.split("/")[0],
      repo: params.repository.split("/")[1],
      installationToken,
      tokenExpiresAt,
      checkRunId,
    });
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

      return { success: true, secretId: documentId };
    } catch (error: any) {
      if (error.code === 6) {
        await secretManagerClient.addSecretVersion({
          parent: `${parent}/secrets/${secretId}`,
          payload: {
            data: Buffer.from(value, "utf8"),
          },
        });

        logger.info(`Secret updated: ${secretId}`, { userId, name });
        return { success: true, message: "Secret updated" };
      }

      logger.error("Failed to create secret", error);
      throw new Error(`Failed to create secret: ${error.message}`);
    }
  },
);
