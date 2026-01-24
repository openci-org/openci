import { onRequest } from "firebase-functions/https";
import * as logger from "firebase-functions/logger";

export const githubApp = onRequest(
  {
    region: "asia-northeast1",
    memory: "512MiB",
  },
  (_, response) => {
    logger.info("Hello logs, this is OpenCI.", { structuredData: true });
    response.send("Hello. This is OpenCI.");
  },
);
