import assert from "node:assert/strict";
import { test } from "node:test";
import { requireGoogleSignup } from "../../lib/functions/auth_signup_policy.js";

test("restricts creation only, leaving existing password sign-ins unaffected", () => {
  assert.equal(
    requireGoogleSignup.__endpoint.blockingTrigger.eventType,
    "providers/cloud.auth/eventTypes/user.beforeCreate",
  );
});

test("allows a new Google user", async () => {
  await requireGoogleSignup.run({ additionalUserInfo: { providerId: "google.com" } });
});

for (const providerId of ["password", "emailLink", "anonymous", "github.com", undefined]) {
  test(`rejects new accounts from ${providerId ?? "missing provider"}`, async () => {
    await assert.rejects(
      async () => requireGoogleSignup.run({ additionalUserInfo: { providerId } }),
      { code: "permission-denied" },
    );
  });
}

test("does not infer Google ownership from an email address or user profile", async () => {
  await assert.rejects(
    async () =>
      requireGoogleSignup.run({
        data: { email: "user@gmail.com", providerData: [{ providerId: "google.com" }] },
      }),
    { code: "permission-denied" },
  );
});
