import { FieldValue } from "firebase-admin/firestore";
import { onRequest } from "firebase-functions/https";
import * as logger from "firebase-functions/logger";

import { db } from "./firebase";
import { teamsCollectionPath } from "./firestore-collection-paths";

export const githubSetup = onRequest(
  {
    region: "asia-northeast1",
  },
  async (req, res) => {
    const installationId = req.query.installation_id as string | undefined;
    const teamId = req.query.state as string | undefined;
    const setupAction = req.query.setup_action as string | undefined;

    logger.info("GitHub Setup callback received", {
      installationId,
      teamId,
      setupAction,
    });

    if (!installationId || !teamId) {
      res.status(400).send("Missing installation_id or state (teamId)");
      return;
    }

    try {
      const teamRef = db.collection(teamsCollectionPath).doc(teamId);
      const teamDoc = await teamRef.get();

      if (!teamDoc.exists) {
        res.status(404).send("Team not found");
        return;
      }

      await teamRef.update({
        installationIds: FieldValue.arrayUnion(Number(installationId)),
        updatedAt: FieldValue.serverTimestamp(),
      });

      logger.info(`Linked installationId ${installationId} to team ${teamId}`);

      // Return a success page
      res.status(200).send(`
        <!DOCTYPE html>
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
        </html>
      `);
    } catch (error) {
      logger.error("Failed to link GitHub installation", error);
      res.status(500).send("Internal server error");
    }
  },
);
