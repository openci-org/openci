import { onRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";

import { getTeamById, linkGitHubInstallation } from "@openci/dataconnect-admin";

export const githubSetup = onRequest(async (request, response) => {
  try {
    const installationId = request.query.installation_id;
    const teamId = request.query.state;
    const setupAction = request.query.setup_action;

    logger.info("GitHub Setup callback received", { installationId, teamId, setupAction });

    if (typeof installationId !== "string" || typeof teamId !== "string") {
      response.status(400).send("Missing installation_id or state (teamId)");
      return;
    }

    const team = await getTeamById({ teamId });
    if (!team.data.team) {
      response.status(404).send("Team not found");
      return;
    }

    const newId = Number.parseInt(installationId, 10);
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
    logger.error("Failed to link GitHub installation", { error });
    response.status(500).send("Internal server error");
  }
});
