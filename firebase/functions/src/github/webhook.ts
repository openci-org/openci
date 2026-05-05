import { logger } from "firebase-functions/v2";
import { onRequest } from "firebase-functions/v2/https";

import { accessSecret } from "../secretManager";
import { routeWebhookEvent, webhookEventFromRequest } from "./buildTrigger";
import { verifyGitHubSignature } from "./webhookVerifier";

export const githubWebhook = onRequest(async (request, response) => {
  try {
    const payload =
      typeof request.rawBody !== "undefined"
        ? request.rawBody.toString("utf8")
        : JSON.stringify(request.body ?? {});
    const secret = await accessSecret("GITHUB_WEBHOOK_SECRET");
    const valid = await verifyGitHubSignature({
      payload,
      signatureHeader: request.header("x-hub-signature-256"),
      secret,
    });

    if (!valid) {
      response.status(401).json({ error: "Invalid signature" });
      return;
    }

    const eventType = request.header("x-github-event");
    if (!eventType) {
      response.status(400).send("Missing x-github-event header");
      return;
    }

    logger.info("GitHub webhook received", {
      eventType,
      action: typeof request.body?.action === "string" ? request.body.action : undefined,
      repository: request.body?.repository?.full_name,
    });

    const body =
      typeof request.body === "object" && request.body !== null
        ? (request.body as Record<string, unknown>)
        : (JSON.parse(payload) as Record<string, unknown>);
    await routeWebhookEvent(webhookEventFromRequest(eventType, body));
    let issueBoardResult: Record<string, number> | undefined;
    try {
      const { processImaGitHubAppWebhook } = await import("../issues/githubWebhookHandlers.js");
      issueBoardResult = await processImaGitHubAppWebhook(eventType, body);
    } catch (issueBoardError) {
      logger.error("IMA webhook processing failed after OpenCI routing", { issueBoardError });
    }

    response.status(200).json({ status: "ok", issueBoard: issueBoardResult });
  } catch (error) {
    logger.error("Webhook processing failed", { error });
    response.status(500).send("Error");
  }
});
