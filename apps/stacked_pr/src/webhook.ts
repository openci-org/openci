import { createNodeMiddleware, Webhooks } from "@octokit/webhooks";
import type { Request, Response } from "firebase-functions/v2/https";
import { isSelfUpdate } from "./events.js";
import { type Job, type Json, object } from "./models.js";

// Retain routing and authorization inputs, never PR bodies, patches or commit lists.
export function compactPayload(raw: Json): Json {
  const previous = object(object(object(raw.changes).base).ref).from;
  return {
    action: raw.action,
    ...(raw.ref == null ? {} : { ref: raw.ref }),
    ...(typeof previous === "string" ? { previous_base: previous } : {}),
    installation: { id: object(raw.installation).id },
    repository: { id: object(raw.repository).id, full_name: object(raw.repository).full_name },
    sender: { login: object(raw.sender).login, type: object(raw.sender).type },
    ...(raw.pull_request == null
      ? {}
      : { pull_request: { number: object(raw.pull_request).number } }),
    ...(raw.issue == null
      ? {}
      : {
          issue: {
            number: object(raw.issue).number,
            ...(object(raw.issue).pull_request == null ? {} : { pull_request: {} }),
          },
        }),
    ...(raw.comment == null ? {} : { comment: { body: object(raw.comment).body } }),
    ...(raw.check_run == null
      ? {}
      : {
          check_run: {
            app: { id: object(object(raw.check_run).app).id },
            external_id: object(raw.check_run).external_id,
            head_sha: object(raw.check_run).head_sha,
          },
        }),
    ...(raw.requested_action == null
      ? {}
      : { requested_action: { identifier: object(raw.requested_action).identifier } }),
  };
}
export function createWebhookHandler(
  enqueue: (job: Job) => Promise<boolean>,
  secret: string,
  limit = 2 * 1024 * 1024,
  botLogin?: string,
) {
  if (secret.length < 32) throw new Error("Use a webhook secret of at least 32 characters");
  const webhooks = new Webhooks({ secret });
  webhooks.on(
    [
      "pull_request.opened",
      "pull_request.reopened",
      "pull_request.synchronize",
      "pull_request.edited",
      "pull_request.closed",
      "pull_request.ready_for_review",
      "pull_request.converted_to_draft",
      "push",
      "issue_comment.created",
      "check_run.requested_action",
      "installation.created",
      "installation.unsuspend",
      "installation.deleted",
      "installation.suspend",
      "installation_repositories.added",
      "installation_repositories.removed",
    ],
    async ({ id, name, payload }) => {
      // This runs only after Octokit has verified the delivery signature.
      if (isSelfUpdate(name, payload, botLogin)) return;
      if (name === "push" && !payload.ref?.startsWith("refs/heads/")) return;
      if (
        name === "issue_comment" &&
        (!payload.issue?.pull_request || payload.comment?.body?.trim() !== "/stack sync")
      )
        return;
      if (
        name === "check_run" &&
        !["restack", "merge-stack", "cancel-merge"].includes(
          payload.requested_action?.identifier ?? "",
        )
      )
        return;
      const installation = payload.installation?.id;
      if (!/^[\w-]{1,128}$/.test(id) || !Number.isSafeInteger(installation) || installation! <= 0)
        throw Object.assign(new Error("Invalid delivery or installation"), { status: 400 });
      try {
        await enqueue({ id, event: name, payload: compactPayload(payload) });
      } catch {
        console.error(JSON.stringify({ event: "webhook_enqueue_failed", delivery: id }));
        throw Object.assign(new Error("Task enqueue failed"), { status: 503 });
      }
    },
  );
  const middleware = createNodeMiddleware(webhooks, {
    path: "/",
    // Above the Function's 30s limit: never send the SDK's early 202 before enqueue succeeds.
    timeout: 60_000,
    // SDK errors carry full webhook payloads; log only the sanitized enqueue failure above.
    log: { debug() {}, info() {}, warn() {}, error() {} },
  });
  return async (request: Request, response: Response): Promise<void> => {
    response.set("cache-control", "no-store");
    if (request.method === "POST") {
      if (
        !request.rawBody ||
        !request.body ||
        typeof request.body !== "object" ||
        Array.isArray(request.body)
      ) {
        response.sendStatus(400);
        return;
      }
      if (request.rawBody.length > limit) {
        response.sendStatus(413);
        return;
      }
    }
    await middleware(request, response, () => response.sendStatus(404));
  };
}
