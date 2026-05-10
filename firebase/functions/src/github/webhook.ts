import { Webhooks } from "@octokit/webhooks";
import { getFirestore } from "firebase-admin/firestore";
import { defineSecret } from "firebase-functions/params";
import { logger } from "firebase-functions/v2";
import { onRequest } from "firebase-functions/v2/https";

import { addBuildJob } from "../buildJob/addBuildJob/addBuildJob.js";
import { syncGitHubPullRequestStatusToDashboardIssueStatus } from "../dashboard/syncGitHubPullRequestStatusToDashboardIssueStatus.js";
import { processImaGitHubAppWebhook } from "../issues/githubWebhookHandlers.js";
import { githubAppId, githubPrivateKey } from "./githubApp.js";
import {
  branchFromRef,
  ownerFromFullName,
  parseWebhookRequest,
  requireInstallationId,
} from "./webhookPayloadHelpers.js";

const githubWebhookSecret = defineSecret("GITHUB_WEBHOOK_SECRET");

export const githubWebhook = onRequest(
  { secrets: [githubWebhookSecret, githubAppId, githubPrivateKey] },
  async (request, response) => {
    const webhookRequest = parseWebhookRequest(request, response);
    if (!webhookRequest) return;

    const webhooks = new Webhooks({ secret: githubWebhookSecret.value() });
    const db = getFirestore();

    webhooks.on(["pull_request.opened", "pull_request.synchronize"], async ({ payload }) => {
      const installationId = requireInstallationId(payload.installation, response);
      if (!installationId) return;
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
    });

    webhooks.on("pull_request.opened", async ({ payload }) => {
      await syncGitHubPullRequestStatusToDashboardIssueStatus(db, payload);
    });

    webhooks.on("push", async ({ name, payload }) => {
      const body = payload as unknown as Record<string, unknown>;
      const installationId = requireInstallationId(payload.installation, response);
      if (!installationId) return;
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
      await processImaGitHubAppWebhook(name, body);
    });

    webhooks.on(
      ["issues.opened", "issues.edited", "issues.closed", "issues.reopened"],
      async ({ name, payload }) => {
        const body = payload as unknown as Record<string, unknown>;
        await processImaGitHubAppWebhook(name, body);
      },
    );

    try {
      await webhooks.verifyAndReceive({
        id: webhookRequest.deliveryId,
        name: webhookRequest.eventType as any,
        payload: webhookRequest.payload,
        signature: webhookRequest.signatureHeader,
      });
      response.status(200).json({ status: "ok" });
    } catch (error) {
      logger.error("GitHub webhook processing failed", { error });
      response.status(500).send("GitHub webhook processing failed");
    }
  },
);
