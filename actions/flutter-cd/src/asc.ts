import * as crypto from "crypto";
import * as fs from "fs";
import * as https from "https";
import { exec, execAndCapture } from "./helpers";

const ASC_API_BASE = "https://api.appstoreconnect.apple.com/v1";

// ══════════════════════════════════════════════════════════════
// ASC JWT
// ══════════════════════════════════════════════════════════════

export function generateAscJwt(keyId: string, issuerId: string, privateKeyPath: string): string {
  const b64url = (data: Buffer | string) =>
    (typeof data === "string" ? Buffer.from(data) : data).toString("base64url");

  const header = b64url(JSON.stringify({ alg: "ES256", kid: keyId, typ: "JWT" }));
  const now = Math.floor(Date.now() / 1000);
  const payload = b64url(
    JSON.stringify({
      iss: issuerId,
      iat: now,
      exp: now + 1200,
      aud: "appstoreconnect-v1",
    }),
  );

  const signInput = `${header}.${payload}`;
  const privateKey = fs.readFileSync(privateKeyPath, "utf8");
  const derSignature = crypto.sign("SHA256", Buffer.from(signInput), {
    key: privateKey,
    dsaEncoding: "ieee-p1363",
  });
  const signature = derSignature.toString("base64url");

  return `${signInput}.${signature}`;
}

// ══════════════════════════════════════════════════════════════
// ASC API
// ══════════════════════════════════════════════════════════════

export async function ascApi(
  jwt: string,
  endpoint: string,
  method: "GET" | "POST" | "DELETE" = "GET",
  body?: object,
): Promise<any> {
  const url = `${ASC_API_BASE}${endpoint}`;
  const parsedUrl = new URL(url);

  const options: https.RequestOptions = {
    hostname: parsedUrl.hostname,
    path: parsedUrl.pathname + parsedUrl.search,
    method,
    headers: {
      Authorization: `Bearer ${jwt}`,
      "Content-Type": "application/json",
    },
  };

  const bodyData = body ? JSON.stringify(body) : undefined;
  if (bodyData) {
    options.headers = {
      ...options.headers,
      "Content-Length": Buffer.byteLength(bodyData).toString(),
    };
  }

  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = "";
      res.on("data", (chunk) => {
        data += chunk;
      });
      res.on("end", () => {
        if (res.statusCode && res.statusCode >= 400) {
          reject(new Error(`ASC API ${method} ${endpoint} returned ${res.statusCode}: ${data}`));
          return;
        }
        if (!data.trim()) {
          resolve(null);
          return;
        }
        try {
          resolve(JSON.parse(data));
        } catch {
          reject(new Error(`Failed to parse ASC API response: ${data}`));
        }
      });
    });
    req.on("error", (e) => reject(new Error(`ASC API request failed: ${e.message}`)));
    if (bodyData) req.write(bodyData);
    req.end();
  });
}

// ══════════════════════════════════════════════════════════════
// Preflight check - version & build number
// ══════════════════════════════════════════════════════════════

const BLOCKED_STATES = new Set([
  "READY_FOR_SALE",
  "PENDING_DEVELOPER_RELEASE",
  "PROCESSING_FOR_APP_STORE",
]);

const REVIEW_STATES = new Set(["IN_REVIEW", "WAITING_FOR_REVIEW"]);

export async function preflightCheck(
  jwt: string,
  bundleId: string,
  version: string,
  buildNumber: string,
): Promise<void> {
  console.log(`  Checking version ${version}+${buildNumber} for ${bundleId}...`);

  const appsResponse = await ascApi(jwt, `/apps?filter[bundleId]=${bundleId}`);
  const apps = appsResponse?.data ?? [];
  if (apps.length === 0) {
    throw new Error(
      `App not found in App Store Connect for bundle ID: ${bundleId}. Create the app in ASC first.`,
    );
  }
  const appId = apps[0].id as string;
  console.log(`  ✅ App found in ASC (ID: ${appId})`);

  const versionsResponse = await ascApi(
    jwt,
    `/apps/${appId}/appStoreVersions?filter[versionString]=${version}&limit=1`,
  );
  const versions = versionsResponse?.data ?? [];

  if (versions.length > 0) {
    const state = versions[0].attributes?.appStoreState as string;
    console.log(`  Version ${version} state: ${state}`);

    if (BLOCKED_STATES.has(state)) {
      throw new Error(
        `Version ${version} is already released or pending release (state: ${state}). Increment the version in pubspec.yaml.`,
      );
    }

    if (REVIEW_STATES.has(state)) {
      throw new Error(
        `Version ${version} is currently in review (state: ${state}). Wait for the review to complete or cancel it.`,
      );
    }
  }

  const buildsResponse = await ascApi(
    jwt,
    `/builds?filter[app]=${appId}&filter[version]=${buildNumber}&filter[preReleaseVersion.version]=${version}&limit=1`,
  );
  const builds = buildsResponse?.data ?? [];
  if (builds.length > 0) {
    throw new Error(
      `Build ${version}+${buildNumber} already exists in App Store Connect. Increment the build number in pubspec.yaml.`,
    );
  }

  console.log(`  ✅ Version ${version}+${buildNumber} is available for upload`);
}

// ══════════════════════════════════════════════════════════════
// Certificate - using persistent private key
// ══════════════════════════════════════════════════════════════

interface CertificateResult {
  certificateId: string;
  p12Base64: string;
  password: string;
}

type CertificateType = "DISTRIBUTION" | "DEVELOPER_ID_APPLICATION";

const DEVELOPER_ID_APPLICATION_CERTIFICATE_TYPES = new Set([
  "DEVELOPER_ID_APPLICATION",
  "DEVELOPER_ID_APPLICATION_G2",
]);

async function listCertificates(jwt: string, certificateType: CertificateType): Promise<any[]> {
  if (certificateType === "DEVELOPER_ID_APPLICATION") {
    const response = await ascApi(jwt, "/certificates?limit=200");
    return sortCertificatesByNewest(
      (response?.data ?? []).filter((cert: any) =>
        DEVELOPER_ID_APPLICATION_CERTIFICATE_TYPES.has(cert.attributes?.certificateType),
      ),
    );
  }

  const response = await ascApi(
    jwt,
    `/certificates?filter[certificateType]=${certificateType}&limit=200`,
  );
  return sortCertificatesByNewest(response?.data ?? []);
}

function sortCertificatesByNewest(certs: any[]): any[] {
  return [...certs].sort((a, b) => certificateExpirationMs(b) - certificateExpirationMs(a));
}

function certificateExpirationMs(cert: any): number {
  const expirationDate = cert.attributes?.expirationDate;
  if (typeof expirationDate !== "string") {
    return 0;
  }
  const time = new Date(expirationDate).getTime();
  return Number.isFinite(time) ? time : 0;
}

function certificateCandidateSummary(cert: any, fingerprint: string): string {
  const expirationDate = cert.attributes?.expirationDate ?? "unknown-expiration";
  const displayName = cert.attributes?.displayName ?? cert.attributes?.name ?? "unnamed";
  return `${cert.id}:${fingerprint}:expires=${expirationDate}:name=${displayName}`;
}

/**
 * Try to find an existing valid signing certificate of the requested type.
 * If found, download and create a p12 with the provided private key.
 * If not found, create a new one using CSR from the provided key.
 */
export async function getOrCreateCertificate(
  jwt: string,
  certPrivateKeyPath: string,
  tmpDir: string,
  certificateType: CertificateType = "DISTRIBUTION",
): Promise<CertificateResult> {
  const password = "openci";

  const certs = await listCertificates(jwt, certificateType);

  const validCerts = certs.filter((cert: any) => {
    const expDate = new Date(cert.attributes.expirationDate);
    return expDate > new Date();
  });

  if (validCerts.length > 0) {
    console.log(`  Found ${validCerts.length} valid certificate(s), trying to reuse...`);

    for (const cert of validCerts) {
      try {
        const p12 = await buildP12FromCert(
          cert.attributes.certificateContent,
          certPrivateKeyPath,
          tmpDir,
          password,
        );
        console.log(`  ✅ Reusing existing certificate (ID: ${cert.id})`);
        return { certificateId: cert.id, p12Base64: p12, password };
      } catch {
        console.log(`  ⚠️  Certificate ${cert.id} doesn't match this private key, skipping`);
      }
    }

    console.log("  No matching certificate found, creating new...");
  } else {
    console.log("  No valid certificates found, creating new...");
  }

  return createNewCertificate(jwt, certPrivateKeyPath, tmpDir, password, certificateType);
}

async function createNewCertificate(
  jwt: string,
  certPrivateKeyPath: string,
  tmpDir: string,
  password: string,
  certificateType: CertificateType,
): Promise<CertificateResult> {
  const csrPemPath = `${tmpDir}/csr.pem`;
  const csrDerPath = `${tmpDir}/csr.der`;

  await exec(
    `openssl req -new -key "${certPrivateKeyPath}" -out "${csrPemPath}" -subj "/CN=OpenCI ${certificateType}/C=JP/O=OpenCI"`,
    { silent: true },
  );

  await exec(`openssl req -in "${csrPemPath}" -outform DER -out "${csrDerPath}"`, { silent: true });
  const csrBase64 = (await execAndCapture(`base64 -i "${csrDerPath}"`)).replace(/\n/g, "");

  let certResponse: any;
  try {
    certResponse = await ascApi(jwt, "/certificates", "POST", {
      data: {
        type: "certificates",
        attributes: {
          certificateType,
          csrContent: csrBase64,
        },
      },
    });
  } catch (e) {
    const msg = String(e);
    if (msg.includes("409") || msg.includes("CONFLICT")) {
      console.log("  ⚠️  Certificate limit reached, deleting oldest...");
      const allCerts = await listCertificates(jwt, certificateType);
      if (allCerts.length > 0) {
        const oldest = allCerts[allCerts.length - 1];
        console.log(`  🗑️  Deleting: ${oldest.id}`);
        await ascApi(jwt, `/certificates/${oldest.id}`, "DELETE").catch(() => {});
        certResponse = await ascApi(jwt, "/certificates", "POST", {
          data: {
            type: "certificates",
            attributes: {
              certificateType,
              csrContent: csrBase64,
            },
          },
        });
      } else {
        throw e;
      }
    } else {
      throw e;
    }
  }

  const certId = certResponse.data.id as string;
  const certContent = certResponse.data.attributes.certificateContent as string;

  const p12 = await buildP12FromCert(certContent, certPrivateKeyPath, tmpDir, password);
  console.log(`  ✅ New certificate created (ID: ${certId})`);

  return { certificateId: certId, p12Base64: p12, password };
}

async function buildP12FromCert(
  certContentBase64: string,
  privateKeyPath: string,
  tmpDir: string,
  password: string,
): Promise<string> {
  const certDerPath = `${tmpDir}/cert.der`;
  const certPemPath = `${tmpDir}/cert.pem`;
  const p12Path = `${tmpDir}/cert.p12`;

  fs.writeFileSync(certDerPath, Buffer.from(certContentBase64, "base64"));
  await exec(`openssl x509 -inform DER -in "${certDerPath}" -out "${certPemPath}"`, {
    silent: true,
  });

  // Verify the key matches the certificate
  const certModulus = await execAndCapture(`openssl x509 -noout -modulus -in "${certPemPath}"`);
  const keyModulus = await execAndCapture(`openssl rsa -noout -modulus -in "${privateKeyPath}"`);
  if (certModulus.trim() !== keyModulus.trim()) {
    // Cleanup temp files
    fs.rmSync(certDerPath, { force: true });
    fs.rmSync(certPemPath, { force: true });
    throw new Error("Certificate does not match the provided private key");
  }

  // Create .p12 (try without -legacy first for LibreSSL, then with -legacy for OpenSSL 3.x)
  try {
    await exec(
      `openssl pkcs12 -export -out "${p12Path}" -inkey "${privateKeyPath}" -in "${certPemPath}" -password "pass:${password}" -certpbe PBE-SHA1-3DES -keypbe PBE-SHA1-3DES -macalg SHA1`,
      { silent: true },
    );
  } catch {
    await exec(
      `openssl pkcs12 -export -out "${p12Path}" -inkey "${privateKeyPath}" -in "${certPemPath}" -password "pass:${password}" -legacy -certpbe PBE-SHA1-3DES -keypbe PBE-SHA1-3DES -macalg SHA1`,
      { silent: true },
    );
  }

  const p12Base64 = (await execAndCapture(`base64 -i "${p12Path}"`)).replace(/\n/g, "");

  // Cleanup
  fs.rmSync(certDerPath, { force: true });
  fs.rmSync(certPemPath, { force: true });
  fs.rmSync(p12Path, { force: true });

  return p12Base64;
}

// ══════════════════════════════════════════════════════════════
// Provisioning Profile
// ══════════════════════════════════════════════════════════════

export interface ProfileResult {
  id: string;
  name: string;
  profileContent: string;
  uuid: string;
  reused?: boolean;
}

const PROFILE_TYPES_REQUIRING_DEVICES = new Set([
  "IOS_APP_ADHOC",
  "IOS_APP_DEVELOPMENT",
  "TVOS_APP_ADHOC",
  "TVOS_APP_DEVELOPMENT",
  "MAC_APP_DEVELOPMENT",
  "MAC_CATALYST_APP_DEVELOPMENT",
]);

function profileLabel(profileType: string): string {
  switch (profileType) {
    case "IOS_APP_STORE":
      return "AppStore";
    case "IOS_APP_ADHOC":
      return "AdHoc";
    case "MAC_APP_DIRECT":
      return "MacDirect";
    default:
      return profileType.replace(/[^A-Za-z0-9]+/g, "");
  }
}

export async function listEnabledDeviceIds(jwt: string): Promise<string[]> {
  const response = await ascApi(jwt, "/devices?filter[status]=ENABLED&limit=200");
  const devices = response?.data ?? [];
  return devices.map((device: any) => device.id as string);
}

export async function createProvisioningProfile(
  jwt: string,
  certificateId: string,
  bundleIdentifier: string,
  profileType: string,
  deviceIds: string[] = [],
): Promise<ProfileResult> {
  const bundleIdResponse = await ascApi(
    jwt,
    `/bundleIds?filter[identifier]=${encodeURIComponent(bundleIdentifier)}`,
  );
  const bundleIds = bundleIdResponse?.data ?? [];
  const bundleIdRecord = bundleIds.find((b: any) => b.attributes?.identifier === bundleIdentifier);
  if (!bundleIdRecord) {
    throw new Error(
      `Bundle ID not found: ${bundleIdentifier}. Register it in Apple Developer Portal first.`,
    );
  }
  const bundleIdResourceId = bundleIdRecord.id as string;

  const label = profileLabel(profileType);
  const allProfiles = await ascApi(jwt, "/profiles?limit=200");
  const profileNamePrefix = `OpenCI ${label} ${bundleIdentifier} `;
  const matchingProfiles = sortProfilesByNewest(
    (allProfiles?.data ?? []).filter((profile: any) =>
      profile.attributes?.name?.startsWith(profileNamePrefix),
    ),
  );

  for (const profile of matchingProfiles) {
    const reusableProfile = await reusableProvisioningProfile(
      jwt,
      profile.id,
      bundleIdResourceId,
      certificateId,
      profileType,
      deviceIds,
    ).catch((error) => {
      console.log(`  ⚠️  Could not inspect profile ${profile.id} for reuse: ${error}`);
      return null;
    });
    if (reusableProfile) {
      console.log(
        `  ✅ Reusing existing profile: ${reusableProfile.name} (${reusableProfile.uuid})`,
      );
      return reusableProfile;
    }
  }

  for (const profile of matchingProfiles) {
    const name = profile.attributes?.name ?? profile.id;
    console.log(`  🗑️  Deleting stale profile: ${name}`);
    await ascApi(jwt, `/profiles/${profile.id}`, "DELETE").catch(() => {});
  }

  const timestamp = new Date().toISOString().replace(/[:.]/g, "-").substring(0, 19);
  const profileName = `OpenCI ${label} ${bundleIdentifier} ${timestamp}`;
  const relationships: any = {
    bundleId: {
      data: { type: "bundleIds", id: bundleIdResourceId },
    },
    certificates: {
      data: [{ type: "certificates", id: certificateId }],
    },
  };

  if (PROFILE_TYPES_REQUIRING_DEVICES.has(profileType)) {
    if (deviceIds.length === 0) {
      throw new Error(
        `No enabled Apple Developer devices found for ${profileType}. Register test devices before creating this provisioning profile.`,
      );
    }
    relationships.devices = {
      data: deviceIds.map((id) => ({ type: "devices", id })),
    };
  }

  const response = await ascApi(jwt, "/profiles", "POST", {
    data: {
      type: "profiles",
      attributes: { name: profileName, profileType },
      relationships,
    },
  });

  return {
    id: response.data.id,
    name: response.data.attributes.name,
    profileContent: response.data.attributes.profileContent,
    uuid: response.data.attributes.uuid,
  };
}

function sortProfilesByNewest(profiles: any[]): any[] {
  return [...profiles].sort((a, b) => profileUpdatedMs(b) - profileUpdatedMs(a));
}

function profileUpdatedMs(profile: any): number {
  for (const field of ["updatedDate", "createdDate", "expirationDate"]) {
    const value = profile.attributes?.[field];
    if (typeof value !== "string") {
      continue;
    }
    const time = new Date(value).getTime();
    if (Number.isFinite(time)) {
      return time;
    }
  }
  return 0;
}

async function reusableProvisioningProfile(
  jwt: string,
  profileId: string,
  bundleIdResourceId: string,
  certificateId: string,
  profileType: string,
  deviceIds: string[],
): Promise<ProfileResult | null> {
  const response = await ascApi(
    jwt,
    `/profiles/${profileId}?include=bundleId,certificates,devices`,
  );
  const profile = response?.data;
  if (!profile) {
    return null;
  }

  const attributes = profile.attributes ?? {};
  if (attributes.profileType !== profileType) {
    return null;
  }
  if (attributes.profileState && attributes.profileState !== "ACTIVE") {
    return null;
  }
  const expirationTime = new Date(attributes.expirationDate ?? 0).getTime();
  if (Number.isFinite(expirationTime) && expirationTime <= Date.now()) {
    return null;
  }
  if (typeof attributes.profileContent !== "string" || attributes.profileContent === "") {
    return null;
  }

  const bundleIds = relationshipIds(profile, response, "bundleId");
  if (bundleIds.length > 0 && !bundleIds.includes(bundleIdResourceId)) {
    return null;
  }

  const certificateIds = relationshipIds(profile, response, "certificates");
  if (certificateIds.length === 0 || !certificateIds.includes(certificateId)) {
    return null;
  }

  if (PROFILE_TYPES_REQUIRING_DEVICES.has(profileType)) {
    const profileDeviceIds = relationshipIds(profile, response, "devices");
    if (profileDeviceIds.length === 0) {
      return null;
    }
    const profileDeviceIdSet = new Set(profileDeviceIds);
    if (!deviceIds.every((id) => profileDeviceIdSet.has(id))) {
      return null;
    }
  }

  return {
    id: profile.id,
    name: attributes.name ?? profileId,
    profileContent: attributes.profileContent,
    uuid: attributes.uuid ?? "",
    reused: true,
  };
}

function relationshipIds(resource: any, response: any, relationshipName: string): string[] {
  const relationshipData = resource.relationships?.[relationshipName]?.data;
  if (Array.isArray(relationshipData)) {
    return relationshipData.map((item: any) => item.id).filter(Boolean);
  }
  if (relationshipData?.id) {
    return [relationshipData.id];
  }

  const includedType = relationshipName === "bundleId" ? "bundleIds" : relationshipName;
  return (response?.included ?? [])
    .filter((item: any) => item.type === includedType)
    .map((item: any) => item.id)
    .filter(Boolean);
}

export async function findDeveloperIdCertificateIdForP12(
  jwt: string,
  p12Base64: string,
  password: string,
  tmpDir: string,
): Promise<string> {
  const p12Path = `${tmpDir}/developer-id-match.p12`;
  const certPemPath = `${tmpDir}/developer-id-match.pem`;

  fs.writeFileSync(p12Path, Buffer.from(p12Base64, "base64"));

  try {
    await extractCertificateFromP12(p12Path, certPemPath, password);
    const localFingerprint = await certificateFingerprint(certPemPath);

    const certs = await listCertificates(jwt, "DEVELOPER_ID_APPLICATION");
    const candidateSummaries: string[] = [];

    for (const cert of certs) {
      const certContent = cert.attributes?.certificateContent ?? "";
      if (!certContent) continue;
      const ascCertPemPath = `${tmpDir}/developer-id-${cert.id}.pem`;
      fs.writeFileSync(ascCertPemPath, decodeCertificateContent(certContent));
      const ascFingerprint = await certificateFingerprint(ascCertPemPath);
      fs.rmSync(ascCertPemPath, { force: true });
      candidateSummaries.push(certificateCandidateSummary(cert, ascFingerprint));
      if (ascFingerprint === localFingerprint) {
        return cert.id as string;
      }
    }

    throw new Error(
      "Provided Developer ID .p12 certificate was not found in App Store Connect. " +
        `Local fingerprint: ${localFingerprint}. ` +
        `ASC candidates: ${candidateSummaries.join(", ") || "(none)"}. ` +
        "Use a Developer ID Application certificate from the same Apple Developer account.",
    );
  } finally {
    fs.rmSync(p12Path, { force: true });
    fs.rmSync(certPemPath, { force: true });
  }
}

function decodeCertificateContent(certificateContent: string): Buffer {
  const trimmed = certificateContent.trim();
  if (trimmed.includes("BEGIN CERTIFICATE")) {
    return Buffer.from(trimmed);
  }
  return Buffer.from(normalizeBase64(trimmed), "base64");
}

async function certificateFingerprint(certPath: string): Promise<string> {
  const output = await execAndCapture(
    `openssl x509 -in ${shellQuote(certPath)} -noout -fingerprint -sha256`,
  );
  return output
    .trim()
    .replace(/^sha256 Fingerprint=/i, "")
    .replace(/:/g, "")
    .toUpperCase();
}

async function extractCertificateFromP12(
  p12Path: string,
  certPemPath: string,
  password: string,
): Promise<void> {
  const command = [
    "openssl pkcs12",
    "-in",
    shellQuote(p12Path),
    "-clcerts",
    "-nokeys",
    "-passin",
    shellQuote(`pass:${password}`),
    "-out",
    shellQuote(certPemPath),
  ].join(" ");

  try {
    await exec(command, { silent: true });
  } catch {
    await exec(`${command} -legacy`, { silent: true });
  }
}

function normalizeBase64(value: string): string {
  return value.replace(/\s/g, "");
}

function shellQuote(value: string): string {
  return `'${value.replace(/'/g, "'\\''")}'`;
}

// ══════════════════════════════════════════════════════════════
// TestFlight Beta Distribution
// ══════════════════════════════════════════════════════════════

export async function getAppIdByBundleId(jwt: string, bundleId: string): Promise<string> {
  const appsResponse = await ascApi(jwt, `/apps?filter[bundleId]=${bundleId}`);
  const apps = appsResponse?.data ?? [];
  if (apps.length === 0) {
    throw new Error(`App not found in App Store Connect for bundle ID: ${bundleId}`);
  }
  return apps[0].id as string;
}

export async function getBetaGroupIdByName(
  jwt: string,
  appId: string,
  groupName: string,
): Promise<string> {
  const endpoint = `/apps/${appId}/betaGroups?filter[name]=${encodeURIComponent(groupName)}`;
  const response = await ascApi(jwt, endpoint);
  const groups = response?.data ?? [];
  if (groups.length === 0) {
    throw new Error(`Beta group not found with name: ${groupName}`);
  }
  return groups[0].id as string;
}

export async function getBuildInfo(
  jwt: string,
  appId: string,
  version: string,
  buildNumber: string,
): Promise<{ id: string; processingState: string } | null> {
  const endpoint = `/builds?filter[app]=${appId}&filter[version]=${buildNumber}&filter[preReleaseVersion.version]=${version}&limit=1`;
  const response = await ascApi(jwt, endpoint);
  const builds = response?.data ?? [];
  if (builds.length === 0) {
    return null;
  }
  const build = builds[0];
  return {
    id: build.id as string,
    processingState: (build.attributes?.processingState as string) || "UNKNOWN",
  };
}

export async function pollBuildProcessing(
  jwt: string,
  appId: string,
  version: string,
  buildNumber: string,
  maxWaitMinutes: number,
): Promise<string> {
  console.log(
    `  Waiting for build ${version}+${buildNumber} to finish processing (max ${maxWaitMinutes} minutes)...`,
  );
  const start = Date.now();
  const intervalMs = 30000; // 30 seconds
  const maxWaitMs = maxWaitMinutes * 60 * 1000;

  while (Date.now() - start < maxWaitMs) {
    try {
      const buildInfo = await getBuildInfo(jwt, appId, version, buildNumber);
      if (buildInfo) {
        const state = buildInfo.processingState;
        console.log(`    Build processing state: ${state}`);
        if (state === "VALID") {
          console.log("  ✅ Build is processed and valid");
          return buildInfo.id;
        }
        if (state === "INVALID" || state === "FAILED") {
          throw new Error(`Build processing failed with state: ${state}`);
        }
      } else {
        console.log("    Build not visible in ASC API yet, retrying...");
      }
    } catch (e) {
      const msg = String(e);
      if (msg.includes("failed with state")) {
        throw e;
      }
      console.log(`    Error fetching build info: ${msg}. Retrying...`);
    }

    await new Promise((resolve) => setTimeout(resolve, intervalMs));
  }

  throw new Error(
    `Timed out waiting for build ${version}+${buildNumber} to process after ${maxWaitMinutes} minutes.`,
  );
}

export async function addBuildToBetaGroup(
  jwt: string,
  buildId: string,
  betaGroupId: string,
): Promise<void> {
  const endpoint = `/builds/${buildId}/relationships/betaGroups`;
  await ascApi(jwt, endpoint, "POST", {
    data: [
      {
        type: "betaGroups",
        id: betaGroupId,
      },
    ],
  });
}
