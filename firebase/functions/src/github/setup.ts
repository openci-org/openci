import { createHmac, randomUUID, timingSafeEqual } from "node:crypto";

import { getTeamById, linkGitHubInstallation } from "../firestoreData.js";
import { onRequest } from "firebase-functions/v2/https";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { defineSecret } from "firebase-functions/params";

import { verifyTeamMembership } from "../team/teamAuth.js";
import { getBaseUrlFromTeamData } from "./githubUrls.js";

const stateTtlMs = 10 * 60 * 1000;
const githubAppSlug = "openci-org";

const githubWebhookSecret = defineSecret("GITHUB_WEBHOOK_SECRET");

interface CreateGitHubSetupUrlRequest {
  teamId: string;
}

interface CreateGitHubSetupUrlResponse {
  url: string;
}

interface GitHubSetupStatePayload {
  teamId: string;
  uid: string;
  expiresAt: number;
  nonce: string;
}

function requireNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.length === 0) {
    throw new HttpsError("invalid-argument", `${field} is required`);
  }
  return value;
}

function signStatePayload(encodedPayload: string, secret: string): string {
  return createHmac("sha256", secret).update(encodedPayload).digest("base64url");
}

function createSetupState(payload: GitHubSetupStatePayload): string {
  const encodedPayload = Buffer.from(JSON.stringify(payload), "utf8").toString("base64url");
  return `${encodedPayload}.${signStatePayload(encodedPayload, githubWebhookSecret.value())}`;
}

function verifySetupState(state: string): GitHubSetupStatePayload {
  const [encodedPayload, signature, ...extra] = state.split(".");
  if (!encodedPayload || !signature || extra.length > 0) {
    throw new HttpsError("invalid-argument", "Invalid setup state");
  }

  const expectedSignature = signStatePayload(encodedPayload, githubWebhookSecret.value());
  const signatureBuffer = Buffer.from(signature, "base64url");
  const expectedBuffer = Buffer.from(expectedSignature, "base64url");
  if (
    signatureBuffer.length !== expectedBuffer.length ||
    !timingSafeEqual(signatureBuffer, expectedBuffer)
  ) {
    throw new HttpsError("permission-denied", "Invalid setup state signature");
  }

  let payload: Partial<GitHubSetupStatePayload>;
  try {
    payload = JSON.parse(
      Buffer.from(encodedPayload, "base64url").toString("utf8"),
    ) as Partial<GitHubSetupStatePayload>;
  } catch {
    throw new HttpsError("invalid-argument", "Invalid setup state payload");
  }
  if (
    typeof payload.teamId !== "string" ||
    payload.teamId.length === 0 ||
    typeof payload.uid !== "string" ||
    payload.uid.length === 0 ||
    typeof payload.expiresAt !== "number" ||
    typeof payload.nonce !== "string" ||
    payload.nonce.length === 0
  ) {
    throw new HttpsError("invalid-argument", "Invalid setup state payload");
  }
  if (payload.expiresAt <= Date.now()) {
    throw new HttpsError("deadline-exceeded", "Setup state has expired");
  }

  return {
    teamId: payload.teamId,
    uid: payload.uid,
    expiresAt: payload.expiresAt,
    nonce: payload.nonce,
  };
}

function statusCodeForHttpsError(error: HttpsError): number {
  switch (error.code) {
    case "invalid-argument":
      return 400;
    case "deadline-exceeded":
      return 410;
    case "permission-denied":
    case "unauthenticated":
      return 403;
    default:
      return 500;
  }
}

export const createGitHubSetupUrl = onCall<
  CreateGitHubSetupUrlRequest,
  Promise<CreateGitHubSetupUrlResponse>
>({ secrets: [githubWebhookSecret] }, async (request) => {
  const teamId = requireNonEmptyString(request.data?.teamId, "teamId");
  const team = await verifyTeamMembership(request.auth, teamId);
  const state = createSetupState({
    teamId,
    uid: request.auth!.uid,
    expiresAt: Date.now() + stateTtlMs,
    nonce: randomUUID(),
  });
  const url = new URL(`/apps/${githubAppSlug}/installations/new`, getBaseUrlFromTeamData(team));
  url.searchParams.set("state", state);
  return { url: url.toString() };
});

export const githubSetup = onRequest({ secrets: [githubWebhookSecret] }, async (request, response) => {
  try {
    const installationId = request.query.installation_id;
    const state = request.query.state;
    const setupAction = request.query.setup_action;

    if (typeof installationId !== "string" || typeof state !== "string") {
      response.status(400).send("Missing installation_id or state");
      return;
    }

    const setupState = verifySetupState(state);
    const { teamId } = setupState;
    logger.info("GitHub Setup callback received", {
      installationId,
      teamId,
      setupAction,
      requestedByUid: setupState.uid,
    });

    const team = await getTeamById({ teamId });
    if (!team.data.team) {
      response.status(404).send("Team not found");
      return;
    }

    const newId = Number.parseInt(installationId, 10);
    if (!Number.isInteger(newId) || newId <= 0) {
      response.status(400).send("Invalid installation_id");
      return;
    }

    await linkGitHubInstallation({ teamId, installationId: newId });
    response.status(200).set("Content-Type", "text/html").send(`<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>OpenCI - GitHub Connected</title>
    <style>
      body { font-family: -apple-system, sans-serif; display: flex; justify-content: center; align-items: center; min-height: 100dvh; margin: 0; background: #0d1117; color: #f0f6fc; }
      .container { text-align: center; padding: 24px; }
      h1 { font-size: 24px; margin-bottom: 8px; }
      p { color: #8b949e; font-size: 16px; }
    </style>
  </head>
  <body>
    <div class="container">
      <h1>✅ GitHub Connected!</h1>
      <p>You can close this page and return to the app.</p>
    </div>
  </body>
</html>`);
  } catch (error) {
    if (error instanceof HttpsError) {
      logger.warn("Rejected GitHub setup callback", { code: error.code, message: error.message });
      response.status(statusCodeForHttpsError(error)).send(error.message);
      return;
    }
    logger.error("Failed to link GitHub installation", { error });
    response.status(500).send("Internal server error");
  }
});
