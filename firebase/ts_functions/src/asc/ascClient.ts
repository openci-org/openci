import { createSign } from "node:crypto";

import { HttpsError } from "firebase-functions/v2/https";
import type { CallableRequest } from "firebase-functions/v2/https";

import { getSecretsByNamesForTeam } from "@openci/dataconnect-admin";
import { accessSecret } from "../secretManager";

const ascBaseUrl = "https://api.appstoreconnect.apple.com/v1";

export interface AscCredentials {
  issuerId: string;
  keyId: string;
  privateKey: string;
}

function base64UrlEncode(input: string | Buffer): string {
  return Buffer.from(input).toString("base64url");
}

function readDerLength(signature: Buffer, offset: number): { length: number; offset: number } {
  let length = signature[offset]!;
  offset += 1;
  if (length & 0x80) {
    const bytes = length & 0x7f;
    length = 0;
    for (let i = 0; i < bytes; i += 1) {
      length = (length << 8) | signature[offset + i]!;
    }
    offset += bytes;
  }
  return { length, offset };
}

function normalizeInteger(input: Buffer): Buffer {
  let value = input;
  while (value.length > 32 && value[0] === 0) {
    value = value.subarray(1);
  }
  if (value.length > 32) {
    throw new Error("Invalid ES256 signature length");
  }
  return Buffer.concat([Buffer.alloc(32 - value.length), value]);
}

function derToJose(signature: Buffer): Buffer {
  let offset = 0;
  if (signature[offset] !== 0x30) {
    throw new Error("Invalid DER signature");
  }
  offset += 1;
  const sequence = readDerLength(signature, offset);
  offset = sequence.offset;

  if (signature[offset] !== 0x02) {
    throw new Error("Invalid DER signature");
  }
  offset += 1;
  const rLength = readDerLength(signature, offset);
  offset = rLength.offset;
  const r = normalizeInteger(signature.subarray(offset, offset + rLength.length));
  offset += rLength.length;

  if (signature[offset] !== 0x02) {
    throw new Error("Invalid DER signature");
  }
  offset += 1;
  const sLength = readDerLength(signature, offset);
  offset = sLength.offset;
  const s = normalizeInteger(signature.subarray(offset, offset + sLength.length));

  return Buffer.concat([r, s]);
}

export function generateAscJwt({ issuerId, keyId, privateKey }: AscCredentials): string {
  const nowSeconds = Math.floor(Date.now() / 1000);
  const header = { alg: "ES256", kid: keyId, typ: "JWT" };
  const payload = {
    iss: issuerId,
    aud: "appstoreconnect-v1",
    iat: nowSeconds,
    exp: nowSeconds + 20 * 60,
  };
  const signingInput = `${base64UrlEncode(JSON.stringify(header))}.${base64UrlEncode(
    JSON.stringify(payload),
  )}`;
  const derSignature = createSign("SHA256").update(signingInput).sign(privateKey);
  return `${signingInput}.${base64UrlEncode(derToJose(derSignature))}`;
}

function secretIdFromPath(pathToSecret: string): string {
  const parts = pathToSecret.split("/");
  if (parts.length >= 4 && parts[2] === "secrets" && parts[3]) {
    return parts[3];
  }
  throw new HttpsError("failed-precondition", `Invalid secret path: ${pathToSecret}`);
}

export async function getAscCredentials(
  teamId: string,
  authClaims: NonNullable<CallableRequest["auth"]>["token"],
): Promise<AscCredentials> {
  const result = await getSecretsByNamesForTeam(
    {
      teamId,
      names: ["OPENCI_ASC_ISSUER_ID", "OPENCI_ASC_KEY_ID", "OPENCI_ASC_PRIVATE_KEY"],
    },
    { impersonate: { authClaims } },
  );

  if (result.data.secrets.length < 3) {
    throw new HttpsError(
      "failed-precondition",
      "ASC API credentials not configured. Please set up your App Store Connect API key first.",
    );
  }

  const secrets: Record<string, string> = {};
  for (const secret of result.data.secrets) {
    if (secret.pathToSecret) {
      secrets[secret.name] = await accessSecret(secretIdFromPath(secret.pathToSecret));
    }
  }

  const issuerId = secrets.OPENCI_ASC_ISSUER_ID;
  const keyId = secrets.OPENCI_ASC_KEY_ID;
  const privateKey = secrets.OPENCI_ASC_PRIVATE_KEY;
  if (!issuerId || !keyId || !privateKey) {
    throw new HttpsError("failed-precondition", "ASC API credentials are incomplete.");
  }

  return { issuerId, keyId, privateKey };
}

export async function ascApiFetch<T = Record<string, unknown>>({
  token,
  path,
  method = "GET",
  body,
}: {
  token: string;
  path: string;
  method?: string;
  body?: unknown;
}): Promise<T> {
  const url = path.startsWith("http") ? path : `${ascBaseUrl}${path}`;
  const response = await fetch(url, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });

  const text = await response.text();
  if (!response.ok) {
    throw new HttpsError(
      "internal",
      `App Store Connect API error (${response.status}): ${text || "Unknown"}`,
    );
  }
  if (response.status === 204 || text.length === 0) {
    return {} as T;
  }
  return JSON.parse(text) as T;
}
