import { beforeUserCreated, HttpsError } from "firebase-functions/v2/identity";
import { apiServiceAccount } from "./function_identity.js";

// Only registration is restricted. Existing password users must still be able
// to sign in, so this must never be registered as a beforeSignIn handler.
export const requireGoogleSignup = beforeUserCreated(
  { region: "asia-northeast1", serviceAccount: apiServiceAccount },
  (event) => {
    if (event.additionalUserInfo?.providerId !== "google.com") {
      throw new HttpsError("permission-denied", "Create your account with Google.");
    }
  },
);
