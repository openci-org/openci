import Stripe from "stripe";
import { error } from "firebase-functions/logger";
import { defineSecret } from "firebase-functions/params";
import { HttpsError, onCall, onRequest } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as sdk from "@openci/billing-admin";
import * as secrets from "@openci/secrets-admin";
import { isolatedConnector } from "./executor/store.js";
import { billingConfig } from "./billing/config.js";
import { BillingError } from "./billing/model.js";
import { Billing } from "./billing/service.js";
import { BillingStore } from "./billing/store.js";
import { StripeBilling } from "./billing/stripe.js";
import { receiveStripeWebhook } from "./billing/webhook.js";
import { ManagedSecretVault } from "./secrets/vault.js";
import { GitHubCredentialVault } from "./github_connection/vault.js";

const stripeKey = defineSecret("STRIPE_SECRET_KEY");
const webhookSecret = defineSecret("STRIPE_WEBHOOK_SECRET");
let cached: Billing | undefined;
function runtime(): Billing {
  if (!cached) {
    const config = billingConfig(process.env);
    const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || "unconfigured", {
      timeout: 10000,
      maxNetworkRetries: 0,
      telemetry: false,
    });
    cached = new Billing(
      new BillingStore(isolatedConnector(sdk.connectorConfig)),
      new StripeBilling(stripe, config),
      config,
    );
  }
  return cached;
}
const options = {
  region: "asia-northeast1",
  memory: "128MiB" as const,
  cpu: 1,
  concurrency: 1,
  minInstances: 0,
  timeoutSeconds: 300,
};

export const teamBilling = onCall({ ...options, secrets: [stripeKey] }, async (request) => {
  if (!request.auth || request.auth.token.firebase?.sign_in_provider === "anonymous")
    throw new HttpsError("unauthenticated", "Sign in to manage billing");
  try {
    return await runtime().execute(request.auth.uid, request.data);
  } catch (cause) {
    if (cause instanceof BillingError)
      throw new HttpsError(cause.code, "Billing operation could not be completed", {
        reason: cause.reason,
      });
    // Stripe/FSC exceptions may contain keys, purchase URLs or personal data.
    error("Billing operation failed");
    throw new HttpsError("unavailable", "Billing operation failed; try again");
  }
});

export const stripeWebhook = onRequest(
  { ...options, invoker: "public", secrets: [stripeKey, webhookSecret] },
  async (request, response) => {
    response.set("Cache-Control", "no-store");
    try {
      const status = await receiveStripeWebhook(
        {
          method: request.method,
          rawBody: request.rawBody,
          signature: request.get("stripe-signature"),
        },
        runtime(),
        webhookSecret.value(),
      );
      if (status === 405) response.set("Allow", "POST");
      response
        .status(status)
        .send(status === 204 ? undefined : "Stripe webhook could not be processed");
    } catch {
      error("Stripe billing synchronization failed");
      response.status(503).send("Stripe webhook requires retry");
    }
  },
);

export const cleanDeletedTeamCredentials = onSchedule(
  { ...options, maxInstances: 1, schedule: "every 60 minutes" },
  async () => {
    const dc = isolatedConnector(sdk.connectorConfig);
    const secretDc = isolatedConnector(secrets.connectorConfig);
    const project = process.env.SECRET_MANAGER_PROJECT ?? process.env.GCLOUD_PROJECT ?? "";
    const vault = new ManagedSecretVault(project);
    const github = new GitHubCredentialVault(project);
    const deadline = Date.now() + 240000;
    try {
      for (const deletion of (await sdk.getDueBillingTeamDeletions(dc)).data.deletions) {
        try {
          if (
            !Array.isArray(deletion.secretPaths) ||
            !deletion.secretPaths.every((p) => typeof p === "string") ||
            !Array.isArray(deletion.githubPaths) ||
            !deletion.githubPaths.every((p) => typeof p === "string")
          )
            throw new Error("Invalid credential cleanup paths");
          for (const path of deletion.secretPaths) {
            if (Date.now() >= deadline) return;
            if (
              (await secrets.getSecretVersionReferences(secretDc, { path })).data.references.length
            )
              throw new Error("Secret is still referenced");
            await vault.destroy(path);
            await sdk.acknowledgeBillingCredentialCleanup(dc, {
              teamId: deletion.teamId,
              path,
              kind: "secret",
            });
          }
          for (const path of deletion.githubPaths) {
            if (Date.now() >= deadline) return;
            await github.destroy(path);
            await sdk.acknowledgeBillingCredentialCleanup(dc, {
              teamId: deletion.teamId,
              path,
              kind: "github",
            });
          }
          await sdk.completeBillingTeamCleanup(dc, { teamId: deletion.teamId });
        } catch {
          error("Deleted team credential cleanup needs retry");
          await sdk.deferBillingTeamCleanup(dc, { teamId: deletion.teamId });
        }
      }
    } finally {
      await vault.close();
      await github.client.close();
    }
  },
);
