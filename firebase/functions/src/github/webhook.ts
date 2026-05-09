import { Webhooks } from "@octokit/webhooks";
import { defineSecret } from "firebase-functions/params";
import { logger } from "firebase-functions/v2";
import { onRequest } from "firebase-functions/v2/https";

import { addBuildJob } from "../buildJob/addBuildJob.js";
import { processImaGitHubAppWebhook } from "../issues/githubWebhookHandlers.js";
import { routeWebhookEvent, webhookEventFromRequest } from "./buildTrigger.js";

const githubWebhookSecret = defineSecret("GITHUB_WEBHOOK_SECRET");

export const githubWebhook = onRequest(
  { secrets: [githubWebhookSecret] },
  async (request, response) => {
    const eventType = request.header("x-github-event");
    if (!eventType) {
      response.status(400).send("Missing x-github-event header");
      return;
    }

    const payload = request.rawBody?.toString("utf8");
    if (!payload) {
      response.status(400).send("Missing request body");
      return;
    }

    const signatureHeader = request.header("x-hub-signature-256");
    if (!signatureHeader) {
      response.status(400).send("Missing x-hub-signature-256 header");
      return;
    }

    const deliveryId = request.header("x-github-delivery");
    if (!deliveryId) {
      response.status(400).send("Missing x-github-delivery header");
      return;
    }

    const webhooks = new Webhooks({ secret: githubWebhookSecret.value() });

    webhooks.on(["pull_request.opened", "pull_request.synchronize"], async ({ payload }) => {
      const installationId = payload.installation?.id;
      if (!installationId) {
        response.status(400).send("Missing installation ID in webhook payload");
        return;
      }
      await addBuildJob({
        installationId,
        commitSha: payload.pull_request.head.sha,
        branch: payload.pull_request.head.ref,
        owner: payload.repository.owner.login,
        repo: payload.repository.name,
      });
      // const body = payload as unknown as Record<string, unknown>;
      // await routeWebhookEvent(webhookEventFromRequest(name, body));
    });

    webhooks.on(
      [
        "pull_request.opened",
        "pull_request.synchronize",
        "pull_request.closed",
        "pull_request.reopened",
        "pull_request.edited",
      ],
      async ({ name, payload }) => {
        const body = payload as unknown as Record<string, unknown>;
        await processImaGitHubAppWebhook(name, body);
      },
    );

    webhooks.on("push", async ({ name, payload }) => {
      const body = payload as unknown as Record<string, unknown>;
      await routeWebhookEvent(webhookEventFromRequest(name, body));
      await processImaGitHubAppWebhook(name, body);
    });

    // Issue Board: sync GitHub issues
    webhooks.on(
      ["issues.opened", "issues.edited", "issues.closed", "issues.reopened"],
      async ({ name, payload }) => {
        const body = payload as unknown as Record<string, unknown>;
        await processImaGitHubAppWebhook(name, body);
      },
    );

    try {
      await webhooks.verifyAndReceive({
        id: deliveryId,
        name: eventType as any,
        payload,
        signature: signatureHeader,
      });
      response.status(200).json({ status: "ok" });
    } catch (error) {
      logger.error("GitHub webhook processing failed", { error });
      response.status(500).send("GitHub webhook processing failed");
    }
  },
);
