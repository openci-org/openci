import * as crypto from "crypto";
import { mkdtemp, rm, writeFile } from "fs/promises";
import { tmpdir } from "os";
import { join } from "path";
import { afterEach, describe, expect, it, vi } from "vitest";

import { generateAscJwt } from "../src/asc";

let tempDir: string | undefined;

afterEach(async () => {
  vi.restoreAllMocks();
  if (tempDir) {
    await rm(tempDir, { recursive: true, force: true });
    tempDir = undefined;
  }
});

describe("generateAscJwt", () => {
  it("creates an ES256 App Store Connect JWT with the expected claims", async () => {
    vi.spyOn(Date, "now").mockReturnValue(1_700_000_000_000);
    tempDir = await mkdtemp(join(tmpdir(), "flutter-cd-asc-"));

    const { privateKey, publicKey } = crypto.generateKeyPairSync("ec", {
      namedCurve: "P-256",
    });
    const privateKeyPath = join(tempDir, "AuthKey.p8");
    await writeFile(privateKeyPath, privateKey.export({ format: "pem", type: "pkcs8" }).toString());

    const jwt = generateAscJwt("KEY1234567", "issuer-id", privateKeyPath);
    const [encodedHeader, encodedPayload, encodedSignature] = jwt.split(".");

    expect(JSON.parse(Buffer.from(encodedHeader, "base64url").toString("utf8"))).toEqual({
      alg: "ES256",
      kid: "KEY1234567",
      typ: "JWT",
    });
    expect(JSON.parse(Buffer.from(encodedPayload, "base64url").toString("utf8"))).toEqual({
      iss: "issuer-id",
      iat: 1_700_000_000,
      exp: 1_700_001_200,
      aud: "appstoreconnect-v1",
    });

    expect(
      crypto.verify(
        "SHA256",
        Buffer.from(`${encodedHeader}.${encodedPayload}`),
        { key: publicKey, dsaEncoding: "ieee-p1363" },
        Buffer.from(encodedSignature, "base64url"),
      ),
    ).toBe(true);
  });
});
