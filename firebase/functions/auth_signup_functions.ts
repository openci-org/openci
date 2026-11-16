import type { UserRecord } from "firebase-admin/auth";
import { error, info } from "firebase-functions/logger";
import { defineSecret } from "firebase-functions/params";
import { region } from "firebase-functions/v1";
import { apiServiceAccount } from "./function_identity.js";

const slackSignupWebhookUrl = defineSecret("SLACK_SIGNUP_WEBHOOK_URL");
const retryWindowMs = 24 * 60 * 60 * 1_000;

function field(label: string, value?: string) {
  // Plain text keeps user-controlled names from becoming links or mentions.
  // Bound Unicode code points so each field stays below Slack's 2,000-char limit.
  const text = [...(value?.trim() || "Not provided")].slice(0, 800).join("");
  return { type: "plain_text", text: `${label}\n${text}`, emoji: false };
}

function signupMessage(user: UserRecord) {
  return {
    // Keep the notification fallback free of user-controlled Slack markup too.
    text: "New OpenCI signup",
    blocks: [
      {
        type: "header",
        text: { type: "plain_text", text: "New OpenCI signup", emoji: false },
      },
      {
        type: "section",
        fields: [
          field("Name", user.displayName),
          field("Email", user.email),
          field(
            "Sign-in providers",
            [...new Set(user.providerData.map((p) => p.providerId))].join(", "),
          ),
          field("Created (UTC)", user.metadata.creationTime),
          field("Firebase UID", user.uid),
        ],
      },
    ],
    unfurl_links: false,
    unfurl_media: false,
  };
}

// Use the established Auth trigger; second-generation Auth events are in preview.
export const notifyAuthUserCreated = region("asia-northeast1")
  .runWith({
    serviceAccount: apiServiceAccount,
    secrets: [slackSignupWebhookUrl],
    memory: "256MB",
    minInstances: 0,
    timeoutSeconds: 30,
    failurePolicy: true,
  })
  .auth.user()
  .onCreate(async (user, context) => {
    if (Date.now() - Date.parse(context.timestamp) >= retryWindowMs) {
      error("Signup notification expired without confirmed delivery", { eventId: context.eventId });
      return;
    }

    let httpStatus: number | undefined;
    try {
      const webhookUrl = new URL(slackSignupWebhookUrl.value().trim());
      if (
        webhookUrl.origin !== "https://hooks.slack.com" ||
        webhookUrl.username ||
        webhookUrl.password ||
        webhookUrl.search ||
        webhookUrl.hash ||
        !/^\/services\/[^/]+\/[^/]+\/[^/]+$/.test(webhookUrl.pathname)
      ) {
        throw new Error("Invalid Slack signup webhook configuration");
      }

      const response = await fetch(webhookUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(signupMessage(user)),
        signal: AbortSignal.timeout(10_000),
        redirect: "error",
      });
      httpStatus = response.status;
      const acknowledgement = await response.text();
      if (!response.ok || acknowledgement.trim() !== "ok") {
        throw new Error("Slack did not acknowledge the signup notification");
      }
    } catch {
      // Fetch errors and response bodies can expose the webhook URL or user data.
      error("Signup notification failed", { eventId: context.eventId, httpStatus });
      throw new Error("Signup notification failed; retry required");
    }

    info("Signup notification delivered", { eventId: context.eventId });
  });
