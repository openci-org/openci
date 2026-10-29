import type { WebhookEventName } from "@octokit/webhooks/types";
import type { Request } from "firebase-functions/v2/https";
import { ConflictingWebhookDeliveryError, type WebhookDelivery } from "./webhook_queue.js";

interface WebhookDependencies {
  secret: string;
  enqueue: (delivery: WebhookDelivery) => Promise<"created" | "duplicate">;
  reportError: (context: { reason: string; deliveryId?: string; eventType?: string }) => void;
}

export async function receiveGitHubWebhook(
  request: Request,
  dependencies: WebhookDependencies,
): Promise<number> {
  if (request.method !== "POST") return 405;
  if (!dependencies.secret) {
    dependencies.reportError({ reason: "webhook_secret_missing" });
    return 503;
  }

  const deliveryId = request.get("x-github-delivery");
  const eventType = request.get("x-github-event");
  if (!deliveryId || !/^[\x21-\x7e]{1,255}$/.test(deliveryId) || !eventType) return 400;

  const body = request.body;
  if (!body || typeof body !== "object" || Array.isArray(body)) return 400;
  if (eventType === "pull_request" && body.action != null && typeof body.action !== "string") {
    return 400;
  }

  let payload: string;
  try {
    if (!request.rawBody) return 400;
    payload = new TextDecoder("utf-8", { fatal: true, ignoreBOM: true }).decode(request.rawBody);
  } catch {
    return 400;
  }

  const { Webhooks } = await import("@octokit/webhooks");
  const webhooks = new Webhooks({ secret: dependencies.secret });
  webhooks.on(
    ["push", "pull_request.opened", "pull_request.synchronize", "pull_request.reopened"],
    async ({ id, name }) => {
      try {
        await dependencies.enqueue({ deliveryId: id, eventType: name, payload });
      } catch (error) {
        if (error instanceof ConflictingWebhookDeliveryError) throw error;
        // Octokit errors include payloads; only log our safe context.
        dependencies.reportError({
          reason: "webhook_persistence_failed",
          deliveryId: id,
          eventType: name,
        });
        throw new Error("Failed to persist webhook delivery");
      }
    },
  );

  try {
    await webhooks.verifyAndReceive({
      id: deliveryId,
      name: eventType as WebhookEventName,
      payload,
      signature: request.get("x-hub-signature-256") ?? "",
    });
    return 200;
  } catch (error) {
    const cause = error instanceof AggregateError ? error.errors[0] : error;
    if (cause instanceof ConflictingWebhookDeliveryError) return 409;
    return (cause as { status?: number })?.status === 400 ? 400 : 503;
  }
}
