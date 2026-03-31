import { SecretManagerServiceClient } from "@google-cloud/secret-manager";
import { HttpsError, onCall } from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import * as jose from "jose";

import { db } from "./firebase";
import { secretsCollectionPath, teamsCollectionPath } from "./firestore-collection-paths";

const secretManagerClient = new SecretManagerServiceClient();

const ASC_BASE_URL = "https://api.appstoreconnect.apple.com/v1";

async function getSecretValue(pathToSecret: string): Promise<string> {
  const [version] = await secretManagerClient.accessSecretVersion({
    name: `${pathToSecret}/versions/latest`,
  });
  return version.payload?.data?.toString() ?? "";
}

async function getAscCredentials(teamId: string): Promise<{
  issuerId: string;
  keyId: string;
  privateKey: string;
}> {
  const secretsSnapshot = await db
    .collection(secretsCollectionPath)
    .where("teamId", "==", teamId)
    .where("name", "in", [
      "OPENCI_ASC_ISSUER_ID",
      "OPENCI_ASC_KEY_ID",
      "OPENCI_ASC_PRIVATE_KEY",
    ])
    .get();

  if (secretsSnapshot.empty || secretsSnapshot.docs.length < 3) {
    throw new HttpsError(
      "failed-precondition",
      "ASC API credentials not configured. Please set up your App Store Connect API key first.",
    );
  }

  const secrets: Record<string, string> = {};
  for (const doc of secretsSnapshot.docs) {
    const data = doc.data();
    const value = await getSecretValue(data.pathToSecret);
    secrets[data.name] = value;
  }

  return {
    issuerId: secrets["OPENCI_ASC_ISSUER_ID"],
    keyId: secrets["OPENCI_ASC_KEY_ID"],
    privateKey: secrets["OPENCI_ASC_PRIVATE_KEY"],
  };
}

async function generateAscJwt(
  issuerId: string,
  keyId: string,
  privateKeyPem: string,
): Promise<string> {
  const privateKey = await jose.importPKCS8(privateKeyPem, "ES256");

  const jwt = await new jose.SignJWT({})
    .setProtectedHeader({ alg: "ES256", kid: keyId, typ: "JWT" })
    .setIssuer(issuerId)
    .setIssuedAt()
    .setExpirationTime("20m")
    .setAudience("appstoreconnect-v1")
    .sign(privateKey);

  return jwt;
}

async function ascApiFetch(
  token: string,
  path: string,
  method: string = "GET",
  body?: any,
): Promise<any> {
  const url = path.startsWith("http") ? path : `${ASC_BASE_URL}${path}`;
  const response = await fetch(url, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: body ? JSON.stringify(body) : undefined,
  });

  if (!response.ok) {
    const errorText = await response.text();
    logger.error("ASC API error", { status: response.status, body: errorText });
    throw new HttpsError(
      "internal",
      `App Store Connect API error (${response.status}): ${errorText}`,
    );
  }

  if (response.status === 204 || response.headers.get("content-length") === "0") {
    return {};
  }

  const text = await response.text();
  if (!text) {
    return {};
  }

  return JSON.parse(text);
}

function verifyTeamMembership(members: string[], callerUid: string) {
  if (!members.includes(callerUid)) {
    throw new HttpsError("permission-denied", "You are not a member of this team");
  }
}

async function verifyAndGetTeam(teamId: string, callerUid: string) {
  const teamRef = db.collection(teamsCollectionPath).doc(teamId);
  const teamDoc = await teamRef.get();
  if (!teamDoc.exists) {
    throw new HttpsError("not-found", "Team not found");
  }
  const teamData = teamDoc.data()!;
  verifyTeamMembership(teamData.members || [], callerUid);
  return teamData;
}

// ── List Apps ──
export const ascListApps = onCall(
  { region: "asia-northeast1" },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Unauthenticated");

    const { teamId } = request.data as { teamId: string };
    if (!teamId) throw new HttpsError("invalid-argument", "Missing teamId");

    await verifyAndGetTeam(teamId, request.auth.uid);
    const creds = await getAscCredentials(teamId);
    const token = await generateAscJwt(creds.issuerId, creds.keyId, creds.privateKey);

    const data = await ascApiFetch(token, "/apps?fields[apps]=name,bundleId,sku&limit=100");

    return {
      apps: data.data.map((app: any) => ({
        id: app.id,
        name: app.attributes.name,
        bundleId: app.attributes.bundleId,
        sku: app.attributes.sku,
      })),
    };
  },
);

// ── List Builds ──
export const ascListBuilds = onCall(
  { region: "asia-northeast1" },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Unauthenticated");

    const { teamId, appId } = request.data as { teamId: string; appId: string };
    if (!teamId || !appId) throw new HttpsError("invalid-argument", "Missing required fields");

    await verifyAndGetTeam(teamId, request.auth.uid);
    const creds = await getAscCredentials(teamId);
    const token = await generateAscJwt(creds.issuerId, creds.keyId, creds.privateKey);

    const data = await ascApiFetch(
      token,
      `/builds?filter[app]=${appId}&sort=-uploadedDate&limit=20&include=preReleaseVersion,buildBetaDetail,appStoreVersion&fields[preReleaseVersions]=version,platform&fields[buildBetaDetails]=externalBuildState,internalBuildState&fields[appStoreVersions]=versionString,appStoreState`,
    );

    const included = data.included || [];
    const preReleaseVersions: Record<string, any> = {};
    const buildBetaDetails: Record<string, any> = {};
    const appStoreVersions: Record<string, any> = {};


    for (const item of included) {
      if (item.type === "preReleaseVersions") {
        preReleaseVersions[item.id] = item.attributes;
      } else if (item.type === "buildBetaDetails") {
        buildBetaDetails[item.id] = item.attributes;
      } else if (item.type === "appStoreVersions") {
        appStoreVersions[item.id] = item.attributes;
      }
    }

    return {
      builds: data.data.map((build: any) => {
        const preReleaseVersionId = build.relationships?.preReleaseVersion?.data?.id;
        const betaDetailId = build.relationships?.buildBetaDetail?.data?.id;
        const appStoreVersionId = build.relationships?.appStoreVersion?.data?.id;
        const preRelease = preReleaseVersionId ? preReleaseVersions[preReleaseVersionId] : null;
        const betaDetail = betaDetailId ? buildBetaDetails[betaDetailId] : null;
        const appStoreVersion = appStoreVersionId ? appStoreVersions[appStoreVersionId] : null;

        return {
          id: build.id,
          version: preRelease?.version ?? build.attributes.version ?? "",
          buildNumber: build.attributes.version ?? "",
          platform: preRelease?.platform ?? "IOS",
          uploadedDate: build.attributes.uploadedDate,
          processingState: build.attributes.processingState,
          iconUrl: build.attributes.iconAssetToken?.templateUrl
            ?.replace("{w}", "64")
            .replace("{h}", "64")
            .replace("{f}", "png") ?? null,
          externalBuildState: betaDetail?.externalBuildState ?? null,
          internalBuildState: betaDetail?.internalBuildState ?? null,
          appStoreState: appStoreVersion?.appStoreState ?? null,
        };
      }),
    };
  },
);

// ── Submit to TestFlight (External Testing) ──
export const ascSubmitToTestFlight = onCall(
  { region: "asia-northeast1" },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Unauthenticated");

    const { teamId, buildId } = request.data as { teamId: string; buildId: string };
    if (!teamId || !buildId) throw new HttpsError("invalid-argument", "Missing required fields");

    await verifyAndGetTeam(teamId, request.auth.uid);
    const creds = await getAscCredentials(teamId);
    const token = await generateAscJwt(creds.issuerId, creds.keyId, creds.privateKey);

    // Get existing beta groups for external testing
    const betaGroupsData = await ascApiFetch(token, `/betaGroups?limit=50`);
    const externalGroups = betaGroupsData.data.filter(
      (g: any) => !g.attributes.isInternalGroup,
    );

    if (externalGroups.length === 0) {
      throw new HttpsError(
        "failed-precondition",
        "No external beta groups found. Create a beta group in App Store Connect first.",
      );
    }

    // Add the build to the first external beta group
    const groupId = externalGroups[0].id;
    await ascApiFetch(token, `/betaGroups/${groupId}/relationships/builds`, "POST", {
      data: [{ type: "builds", id: buildId }],
    });

    logger.info("Build submitted to TestFlight", { buildId, groupId });

    return {
      success: true,
      betaGroupName: externalGroups[0].attributes.name,
    };
  },
);

// ── Submit for App Store Review ──
export const ascSubmitForReview = onCall(
  { region: "asia-northeast1" },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Unauthenticated");

    const { teamId, appId, buildId, versionString, whatsNew, platform } = request.data as {
      teamId: string;
      appId: string;
      buildId: string;
      versionString: string;
      whatsNew: string;
      platform: string;
    };
    if (!teamId || !appId || !buildId || !versionString || !whatsNew) {
      throw new HttpsError("invalid-argument", "Missing required fields");
    }

    await verifyAndGetTeam(teamId, request.auth.uid);
    const creds = await getAscCredentials(teamId);
    const token = await generateAscJwt(creds.issuerId, creds.keyId, creds.privateKey);

    const resolvedPlatform = platform || "IOS";

    // 1. Create or find appStoreVersion
    let appStoreVersionId: string;

    // Check if there's already an editable version
    const existingVersions = await ascApiFetch(
      token,
      `/apps/${appId}/appStoreVersions?filter[versionString]=${versionString}&filter[platform]=${resolvedPlatform}`,
    );

    if (existingVersions.data.length > 0) {
      const version = existingVersions.data[0];
      const state = version.attributes.appStoreState;
      if (
        state === "PREPARE_FOR_SUBMISSION" ||
        state === "DEVELOPER_REJECTED" ||
        state === "REJECTED"
      ) {
        appStoreVersionId = version.id;
      } else {
        throw new HttpsError(
          "failed-precondition",
          `Version ${versionString} is already in state: ${state}. Cannot submit.`,
        );
      }
    } else {
      // Create a new appStoreVersion
      const createVersionResponse = await ascApiFetch(
        token,
        "/appStoreVersions",
        "POST",
        {
          data: {
            type: "appStoreVersions",
            attributes: {
              versionString,
              platform: resolvedPlatform,
            },
            relationships: {
              app: {
                data: { type: "apps", id: appId },
              },
            },
          },
        },
      );
      appStoreVersionId = createVersionResponse.data.id;
    }

    // 2. Set "What's New" release notes via localizations
    const localizationsResponse = await ascApiFetch(
      token,
      `/appStoreVersions/${appStoreVersionId}/appStoreVersionLocalizations`,
    );

    if (localizationsResponse.data.length > 0) {
      // Update existing localization(s)
      for (const loc of localizationsResponse.data) {
        await ascApiFetch(
          token,
          `/appStoreVersionLocalizations/${loc.id}`,
          "PATCH",
          {
            data: {
              type: "appStoreVersionLocalizations",
              id: loc.id,
              attributes: {
                whatsNew,
              },
            },
          },
        );
      }
    } else {
      // Create a default en-US localization
      await ascApiFetch(
        token,
        "/appStoreVersionLocalizations",
        "POST",
        {
          data: {
            type: "appStoreVersionLocalizations",
            attributes: {
              locale: "en-US",
              whatsNew,
            },
            relationships: {
              appStoreVersion: {
                data: { type: "appStoreVersions", id: appStoreVersionId },
              },
            },
          },
        },
      );
    }

    // 3. Attach the build to the version
    await ascApiFetch(
      token,
      `/appStoreVersions/${appStoreVersionId}/relationships/build`,
      "PATCH",
      {
        data: { type: "builds", id: buildId },
      },
    );

    // 3.5 Set export compliance (usesNonExemptEncryption)
    // Always set this to ensure the build is ready for submission
    try {
      await ascApiFetch(token, `/builds/${buildId}`, "PATCH", {
        data: {
          type: "builds",
          id: buildId,
          attributes: {
            usesNonExemptEncryption: false,
          },
        },
      });
      logger.info("Set usesNonExemptEncryption=false on build", { buildId });
    } catch (e) {
      logger.warn("Failed to set usesNonExemptEncryption, trying via Info.plist key", { buildId, error: String(e) });
    }

    // 4. Submit for review using the new reviewSubmissions API
    // Step 4a: Create a review submission
    const reviewSubmission = await ascApiFetch(token, "/reviewSubmissions", "POST", {
      data: {
        type: "reviewSubmissions",
        relationships: {
          app: {
            data: { type: "apps", id: appId },
          },
        },
      },
    });
    const reviewSubmissionId = reviewSubmission.data.id;

    // Step 4b: Add the app store version as a review submission item
    await ascApiFetch(token, "/reviewSubmissionItems", "POST", {
      data: {
        type: "reviewSubmissionItems",
        relationships: {
          reviewSubmission: {
            data: { type: "reviewSubmissions", id: reviewSubmissionId },
          },
          appStoreVersion: {
            data: { type: "appStoreVersions", id: appStoreVersionId },
          },
        },
      },
    });

    // Step 4c: Submit the review submission
    await ascApiFetch(token, `/reviewSubmissions/${reviewSubmissionId}`, "PATCH", {
      data: {
        type: "reviewSubmissions",
        id: reviewSubmissionId,
        attributes: {
          submitted: true,
        },
      },
    });

    logger.info("Build submitted for App Store Review", {
      appId,
      buildId,
      versionString,
      appStoreVersionId,
    });

    return { success: true, appStoreVersionId };
  },
);
