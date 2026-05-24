import { Webhooks } from "@octokit/webhooks";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { defineSecret } from "firebase-functions/params";
import { logger } from "firebase-functions/v2";
import { onRequest } from "firebase-functions/v2/https";

import { addBuildJob } from "../buildJob/addBuildJob/addBuildJob.js";
import { linkGitHubIssueToPullRequest } from "../dashboard/linkGitHubIssueToPullRequest/linkGitHubIssueToPullRequest.js";
import { syncGitHubPullRequestStatusToDashboardIssueStatus } from "../dashboard/syncGitHubPullRequestStatusToDashboardIssueStatus/syncGitHubPullRequestStatusToDashboardIssueStatus.js";
import { processImaGitHubAppWebhook } from "../issues/githubWebhookHandlers.js";
import { autoCreatePullRequest } from "../issues/imaHandlers.js";
import { githubAppId, githubPrivateKey } from "./githubApp.js";
import { notifyPullRequestCiPassedIfReady } from "./pullRequestCiNotifications.js";
import { branchFromRef, ownerFromFullName, parseWebhookRequest } from "./webhookPayloadHelpers.js";

const githubWebhookSecret = defineSecret("GITHUB_WEBHOOK_SECRET");

function asRecord(value: unknown): Record<string, unknown> | undefined {
  return typeof value === "object" && value !== null
    ? (value as Record<string, unknown>)
    : undefined;
}

function asString(value: unknown): string | undefined {
  return typeof value === "string" && value.length > 0 ? value : undefined;
}

function asNumber(value: unknown): number | undefined {
  return typeof value === "number" && Number.isFinite(value) ? value : undefined;
}

function firstCheckRunPullRequestNumber(
  pullRequests: Array<{ number?: number }> | undefined,
): number | undefined {
  return pullRequests?.find((pullRequest) => typeof pullRequest.number === "number")?.number;
}

function requireWebhookInstallationId(installation: { id?: number } | undefined): number {
  const installationId = installation?.id;
  if (!installationId) {
    throw new Error("Missing installation ID in webhook payload");
  }
  return installationId;
}

function iterableErrors(value: unknown): unknown[] | undefined {
  if (Array.isArray(value)) {
    return value;
  }
  if (
    typeof value === "object" &&
    value !== null &&
    Symbol.iterator in value &&
    typeof value[Symbol.iterator] === "function"
  ) {
    return [...(value as Iterable<unknown>)];
  }
  return undefined;
}

function summarizeWebhookPayload(payload: unknown): Record<string, unknown> {
  const body = asRecord(payload);
  const repository = asRecord(body?.repository);
  const installation = asRecord(body?.installation);
  const pullRequest = asRecord(body?.pull_request);
  const issue = asRecord(body?.issue);

  return {
    action: asString(body?.action),
    repository: asString(repository?.full_name),
    installationId: asNumber(installation?.id),
    ref: asString(body?.ref),
    after: asString(body?.after),
    pullRequestNumber: asNumber(pullRequest?.number),
    issueNumber: asNumber(issue?.number),
  };
}

function webhookLogData({
  deliveryId,
  eventType,
  payload,
}: {
  deliveryId: string;
  eventType: string;
  payload: unknown;
}): Record<string, unknown> {
  return {
    deliveryId,
    eventType,
    ...summarizeWebhookPayload(payload),
  };
}

export function serializeError(error: unknown): unknown {
  if (error instanceof Error) {
    const serialized: Record<string, unknown> = {
      name: error.name,
      message: error.message,
      stack: error.stack,
    };
    const record = error as unknown as Record<string, unknown>;
    for (const key of ["status", "code"]) {
      if (record[key] !== undefined) {
        serialized[key] = record[key];
      }
    }
    if (error.cause !== undefined) {
      serialized.cause = serializeError(error.cause);
    }
    const errors = iterableErrors((error as { errors?: unknown }).errors);
    if (errors !== undefined) {
      serialized.errors = errors.map((innerError) => serializeError(innerError));
    }
    const event = asRecord((error as { event?: unknown }).event);
    if (event !== undefined) {
      serialized.event = {
        id: asString(event.id),
        name: asString(event.name),
        payload: summarizeWebhookPayload(event.payload),
      };
    }
    return serialized;
  }

  const record = asRecord(error);
  if (record !== undefined) {
    const serialized: Record<string, unknown> = {};
    for (const key of ["name", "message", "stack", "status", "code"]) {
      if (record[key] !== undefined) {
        serialized[key] = record[key];
      }
    }
    const errors = iterableErrors(record.errors);
    if (errors !== undefined) {
      serialized.errors = errors.map((innerError) => serializeError(innerError));
    }
    const event = asRecord(record.event);
    if (event !== undefined) {
      serialized.event = {
        id: asString(event.id),
        name: asString(event.name),
        payload: summarizeWebhookPayload(event.payload),
      };
    }
    return Object.keys(serialized).length > 0 ? serialized : String(error);
  }

  return error;
}

async function runWebhookHandler({
  handlerName,
  deliveryId,
  eventType,
  payload,
  handler,
}: {
  handlerName: string;
  deliveryId: string;
  eventType: string;
  payload: unknown;
  handler: () => Promise<void>;
}): Promise<void> {
  try {
    await handler();
  } catch (error) {
    logger.error("GitHub webhook handler failed", {
      handlerName,
      ...webhookLogData({ deliveryId, eventType, payload }),
      error: serializeError(error),
    });
  }
}

async function handleBranchCreate(
  db: FirebaseFirestore.Firestore,
  installationId: number,
  repository: string,
  branch: string,
): Promise<void> {
  logger.info("handleBranchCreate started", { installationId, repository, branch });
  const repositoryId = repository.replace("/", ":");
  const teamsSnapshot = await db
    .collection("teams_v0")
    .where("installationIds", "array-contains", installationId)
    .get();

  logger.info("Found teams matching installation", { count: teamsSnapshot.size });

  for (const teamDoc of teamsSnapshot.docs) {
    const repoRef = db
      .collection("teams_v0")
      .doc(teamDoc.id)
      .collection("repositories_v0")
      .doc(repositoryId);

    await db.runTransaction(async (transaction) => {
      const doc = await transaction.get(repoRef);
      if (doc.exists) {
        logger.info("Updating branches array with new branch (union)", { teamId: teamDoc.id, branch });
        transaction.update(repoRef, {
          branches: FieldValue.arrayUnion(branch),
          updatedAt: new Date().toISOString(),
        });
      } else {
        logger.info("Skipped branch creation sync: repo cache document does not exist", { teamId: teamDoc.id, repositoryId });
      }
    });
  }
}

async function handleBranchDelete(
  db: FirebaseFirestore.Firestore,
  installationId: number,
  repository: string,
  branch: string,
): Promise<void> {
  logger.info("handleBranchDelete started", { installationId, repository, branch });
  const repositoryId = repository.replace("/", ":");
  const teamsSnapshot = await db
    .collection("teams_v0")
    .where("installationIds", "array-contains", installationId)
    .get();

  logger.info("Found teams matching installation", { count: teamsSnapshot.size });

  for (const teamDoc of teamsSnapshot.docs) {
    const repoRef = db
      .collection("teams_v0")
      .doc(teamDoc.id)
      .collection("repositories_v0")
      .doc(repositoryId);

    await db.runTransaction(async (transaction) => {
      const doc = await transaction.get(repoRef);
      if (doc.exists) {
        logger.info("Updating branches array by removing branch", { teamId: teamDoc.id, branch });
        transaction.update(repoRef, {
          branches: FieldValue.arrayRemove(branch),
          updatedAt: new Date().toISOString(),
        });
      } else {
        logger.info("Skipped branch deletion sync: repo cache document does not exist", { teamId: teamDoc.id, repositoryId });
      }
    });
  }
}

export const githubWebhook = onRequest(
  { secrets: [githubWebhookSecret, githubAppId, githubPrivateKey] },
  async (request, response) => {
    const webhookRequest = parseWebhookRequest(request, response);
    if (!webhookRequest) return;

    const webhooks = new Webhooks({ secret: githubWebhookSecret.value() });
    const db = getFirestore();

    webhooks.on(["pull_request.opened", "pull_request.synchronize"], async ({ name, payload }) => {
      await runWebhookHandler({
        handlerName: "addBuildJob",
        deliveryId: webhookRequest.deliveryId,
        eventType: name,
        payload,
        handler: async () => {
          const installationId = requireWebhookInstallationId(payload.installation);
          await addBuildJob({
            installationId,
            commitSha: payload.pull_request.head.sha,
            branch: payload.pull_request.head.ref,
            triggerBranch: payload.pull_request.base.ref,
            pullRequestNumber: payload.pull_request.number,
            owner: payload.repository.owner.login,
            repo: payload.repository.name,
            appId: githubAppId.value(),
            privateKey: githubPrivateKey.value(),
            triggerType: "pull_request",
          });
        },
      });
    });

    webhooks.on("pull_request.opened", async ({ name, payload }) => {
      await runWebhookHandler({
        handlerName: "syncGitHubPullRequestStatusToDashboardIssueStatus",
        deliveryId: webhookRequest.deliveryId,
        eventType: name,
        payload,
        handler: async () => {
          await syncGitHubPullRequestStatusToDashboardIssueStatus(db, payload);
        },
      });
    });

    webhooks.on("check_run.completed", async ({ name, payload }) => {
      await runWebhookHandler({
        handlerName: "notifyPullRequestCiPassedIfReady",
        deliveryId: webhookRequest.deliveryId,
        eventType: name,
        payload,
        handler: async () => {
          if (payload.check_run.conclusion !== "success") return;
          const installationId = requireWebhookInstallationId(payload.installation);
          await notifyPullRequestCiPassedIfReady({
            installationId,
            owner: payload.repository.owner.login,
            repo: payload.repository.name,
            headSha: payload.check_run.head_sha,
            pullRequestNumber: firstCheckRunPullRequestNumber(payload.check_run.pull_requests),
          });
        },
      });
    });

    webhooks.on("pull_request.opened", async ({ name, payload }) => {
      await runWebhookHandler({
        handlerName: "linkGitHubIssueToPullRequest",
        deliveryId: webhookRequest.deliveryId,
        eventType: name,
        payload,
        handler: async () => {
          await linkGitHubIssueToPullRequest(db, payload);
        },
      });
    });

    webhooks.on("pull_request.edited", async ({ name, payload }) => {
      await runWebhookHandler({
        handlerName: "processImaGitHubAppWebhook",
        deliveryId: webhookRequest.deliveryId,
        eventType: name,
        payload,
        handler: async () => {
          const body = payload as unknown as Record<string, unknown>;
          await processImaGitHubAppWebhook(name, body);
        },
      });
    });

    webhooks.on("push", async ({ name, payload }) => {
      await runWebhookHandler({
        handlerName: "addBuildJob",
        deliveryId: webhookRequest.deliveryId,
        eventType: name,
        payload,
        handler: async () => {
          const installationId = requireWebhookInstallationId(payload.installation);
          if (!payload.deleted) {
            const branch = branchFromRef(payload.ref);
            await addBuildJob({
              installationId,
              commitSha: payload.head_commit?.id ?? payload.after,
              branch,
              triggerBranch: branch,
              pullRequestNumber: null,
              owner: ownerFromFullName(payload.repository.full_name),
              repo: payload.repository.name,
              appId: githubAppId.value(),
              privateKey: githubPrivateKey.value(),
              triggerType: "push",
            });
          }
        },
      });
      await runWebhookHandler({
        handlerName: "autoCreatePullRequest",
        deliveryId: webhookRequest.deliveryId,
        eventType: name,
        payload,
        handler: async () => {
          if (!payload.deleted) {
            const branch = branchFromRef(payload.ref);
            await autoCreatePullRequest({
              repository: payload.repository.full_name,
              branch,
            });
          }
        },
      });
      await runWebhookHandler({
        handlerName: "processImaGitHubAppWebhook",
        deliveryId: webhookRequest.deliveryId,
        eventType: name,
        payload,
        handler: async () => {
          const body = payload as unknown as Record<string, unknown>;
          await processImaGitHubAppWebhook(name, body);
        },
      });
    });

    webhooks.on(
      ["issues.opened", "issues.edited", "issues.closed", "issues.reopened"],
      async ({ name, payload }) => {
        await runWebhookHandler({
          handlerName: "processImaGitHubAppWebhook",
          deliveryId: webhookRequest.deliveryId,
          eventType: name,
          payload,
          handler: async () => {
            const body = payload as unknown as Record<string, unknown>;
            await processImaGitHubAppWebhook(name, body);
          },
        });
      },
    );

    webhooks.on("create", async ({ name, payload }) => {
      await runWebhookHandler({
        handlerName: "syncGitHubBranchCreate",
        deliveryId: webhookRequest.deliveryId,
        eventType: name,
        payload,
        handler: async () => {
          if (payload.ref_type !== "branch") return;
          const installationId = requireWebhookInstallationId(payload.installation);
          const repository = payload.repository.full_name;
          const branch = payload.ref;
          await handleBranchCreate(db, installationId, repository, branch);
        },
      });
    });

    webhooks.on("delete", async ({ name, payload }) => {
      await runWebhookHandler({
        handlerName: "syncGitHubBranchDelete",
        deliveryId: webhookRequest.deliveryId,
        eventType: name,
        payload,
        handler: async () => {
          if (payload.ref_type !== "branch") return;
          const installationId = requireWebhookInstallationId(payload.installation);
          const repository = payload.repository.full_name;
          const branch = payload.ref;
          await handleBranchDelete(db, installationId, repository, branch);
        },
      });
    });

    try {
      await webhooks.verifyAndReceive({
        id: webhookRequest.deliveryId,
        name: webhookRequest.eventType as any,
        payload: webhookRequest.payload,
        signature: webhookRequest.signatureHeader,
      });
      response.status(200).json({ status: "ok" });
    } catch (error) {
      logger.warn("GitHub webhook verification failed", {
        deliveryId: webhookRequest.deliveryId,
        eventType: webhookRequest.eventType,
        error: serializeError(error),
      });
      response.status(401).send("GitHub webhook verification failed");
    }
  },
);
