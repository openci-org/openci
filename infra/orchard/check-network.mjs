import assert from "node:assert/strict";
import https from "node:https";
import { setTimeout } from "node:timers/promises";

// Run in a temporary Cloud Run Job with Direct VPC egress. Credentials are
// Secret Manager bindings; never print headers, response bodies or exceptions.
const endpoint = process.env.ORCHARD_API_URL ?? "https://10.77.0.2:443";
const ca = process.env.ORCHARD_CA_CERT;
const token = process.env.ORCHARD_SERVICE_ACCOUNT_TOKEN;
assert.ok(ca && token, "Orchard secret bindings are required");

function get(path, authenticated) {
  return new Promise((resolve, reject) => {
    const request = https.get(
      new URL(path, endpoint),
      {
        ca,
        rejectUnauthorized: true,
        auth: authenticated ? `build-executor:${token}` : undefined,
        signal: AbortSignal.timeout(15000),
      },
      (response) => {
        let body = "";
        response.setEncoding("utf8");
        response.on("data", (chunk) => (body += chunk));
        response.on("error", reject);
        response.on("end", () => resolve({ status: response.statusCode, body }));
      },
    );
    request.on("error", reject);
  });
}

let ready = false;
for (let attempt = 0; attempt < 6 && !ready; attempt++) {
  try {
    const anonymous = await get("/v1/workers", false);
    assert.equal(anonymous.status, 401);
    for (const path of ["/v1/workers", "/v1/vms"]) {
      const response = await get(path, true);
      assert.equal(response.status, 200);
      const rows = JSON.parse(response.body);
      assert.ok(Array.isArray(rows));
      console.log(JSON.stringify({ path, status: response.status, count: rows.length }));
    }
    ready = true;
  } catch {
    if (attempt < 5) await setTimeout(2000);
  }
}
if (!ready) throw new Error("Orchard private network verification failed");
console.log(
  "ORCHARD_PRIVATE_NETWORK_OK: TLS verified; anonymous rejected; authenticated reads passed",
);
