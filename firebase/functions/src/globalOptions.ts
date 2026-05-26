import { setGlobalOptions } from "firebase-functions/v2";

setGlobalOptions({
  region: "asia-northeast1",
  maxInstances: 10,
  secrets: ["GITHUB_APP_ID", "GITHUB_PRIVATE_KEY", "GITHUB_WEBHOOK_SECRET", "GEMINI_API_KEY"],
});
