import { logger } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import type { CallableRequest } from "firebase-functions/v2/https";

import { ascApiFetch, generateAscJwt, getAscCredentials } from "./ascClient";
import {
  ascAppFromJsonApi,
  ascBetaGroupFromJsonApi,
  ascBuildFromJsonApi,
  parseIncludedResources,
  type AscApp,
  type AscBuild,
} from "./ascModels";
import { verifyTeamMembership } from "../team/teamAuth";

interface TeamRequest {
  teamId: string;
}

interface ListBuildsRequest extends TeamRequest {
  appId: string;
}

interface SubmitToTestFlightRequest extends TeamRequest {
  buildId: string;
}

interface SubmitForReviewRequest extends TeamRequest {
  appId: string;
  buildId: string;
  versionString: string;
  whatsNew: string;
  platform?: string;
}

interface AscListResponse<T> {
  data?: T[];
  included?: unknown[];
}

interface AscEntity {
  id?: unknown;
  attributes?: Record<string, unknown>;
}

function requireNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.length === 0) {
    throw new HttpsError("invalid-argument", `${field} is required`);
  }
  return value;
}

async function getAscToken(teamId: string, auth: NonNullable<CallableRequest["auth"]>): Promise<string> {
  await verifyTeamMembership(auth, teamId);
  const creds = await getAscCredentials(teamId, auth.token);
  return generateAscJwt(creds);
}

function requireAuth(auth: CallableRequest["auth"]): NonNullable<CallableRequest["auth"]> {
  if (!auth) {
    throw new HttpsError("unauthenticated", "Unauthenticated");
  }
  return auth;
}

export const ascListApps = onCall<TeamRequest, Promise<{ apps: AscApp[] }>>(async (request) => {
  const auth = requireAuth(request.auth);
  const teamId = requireNonEmptyString(request.data?.teamId, "teamId");
  const token = await getAscToken(teamId, auth);

  const result = await ascApiFetch<AscListResponse<Record<string, unknown>>>({
    token,
    path: "/apps?fields[apps]=name,bundleId,sku&limit=100",
  });
  return { apps: (result.data ?? []).map(ascAppFromJsonApi) };
});

export const ascListBuilds = onCall<ListBuildsRequest, Promise<{ builds: AscBuild[] }>>(
  async (request) => {
    const auth = requireAuth(request.auth);
    const teamId = requireNonEmptyString(request.data?.teamId, "teamId");
    const appId = requireNonEmptyString(request.data?.appId, "appId");
    const token = await getAscToken(teamId, auth);

    const result = await ascApiFetch<AscListResponse<Record<string, unknown>>>({
      token,
      path:
        `/builds?filter[app]=${encodeURIComponent(appId)}` +
        "&sort=-uploadedDate" +
        "&limit=20" +
        "&include=preReleaseVersion,buildBetaDetail,appStoreVersion" +
        "&fields[preReleaseVersions]=version,platform" +
        "&fields[buildBetaDetails]=externalBuildState,internalBuildState" +
        "&fields[appStoreVersions]=versionString,appStoreState",
    });
    const resources = parseIncludedResources(result.included ?? []);
    return { builds: (result.data ?? []).map((build) => ascBuildFromJsonApi(build, resources)) };
  },
);

export const ascSubmitToTestFlight = onCall<
  SubmitToTestFlightRequest,
  Promise<{ success: true; betaGroupName: string }>
>(async (request) => {
  const auth = requireAuth(request.auth);
  const teamId = requireNonEmptyString(request.data?.teamId, "teamId");
  const buildId = requireNonEmptyString(request.data?.buildId, "buildId");
  const token = await getAscToken(teamId, auth);

  const betaGroupsData = await ascApiFetch<AscListResponse<Record<string, unknown>>>({
    token,
    path: "/betaGroups?limit=50",
  });
  const externalGroups = (betaGroupsData.data ?? [])
    .map(ascBetaGroupFromJsonApi)
    .filter((group) => !group.isInternalGroup);

  if (externalGroups.length === 0) {
    throw new HttpsError(
      "failed-precondition",
      "No external beta groups found. Create a beta group in App Store Connect first.",
    );
  }

  const group = externalGroups[0]!;
  await ascApiFetch({
    token,
    path: `/betaGroups/${group.id}/relationships/builds`,
    method: "POST",
    body: { data: [{ type: "builds", id: buildId }] },
  });

  logger.info("Build submitted to TestFlight", { buildId, groupId: group.id });
  return { success: true, betaGroupName: group.name };
});

async function resolveAppStoreVersion({
  token,
  appId,
  versionString,
  platform,
}: {
  token: string;
  appId: string;
  versionString: string;
  platform: string;
}): Promise<string> {
  const existingVersions = await ascApiFetch<AscListResponse<AscEntity>>({
    token,
    path:
      `/apps/${appId}/appStoreVersions?filter[versionString]=${encodeURIComponent(versionString)}` +
      `&filter[platform]=${encodeURIComponent(platform)}`,
  });
  const version = existingVersions.data?.[0];
  if (version) {
    const state = version.attributes?.appStoreState;
    const editableStates = new Set(["PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED"]);
    if (typeof state === "string" && editableStates.has(state)) {
      return String(version.id);
    }
    throw new HttpsError(
      "failed-precondition",
      `Version ${versionString} is already in state: ${String(state)}. Cannot submit.`,
    );
  }

  const createResponse = await ascApiFetch<{ data?: { id?: string } }>({
    token,
    path: "/appStoreVersions",
    method: "POST",
    body: {
      data: {
        type: "appStoreVersions",
        attributes: { versionString, platform },
        relationships: { app: { data: { type: "apps", id: appId } } },
      },
    },
  });
  return requireNonEmptyString(createResponse.data?.id, "appStoreVersionId");
}

async function setWhatsNew({
  token,
  appStoreVersionId,
  whatsNew,
}: {
  token: string;
  appStoreVersionId: string;
  whatsNew: string;
}): Promise<void> {
  const locResponse = await ascApiFetch<AscListResponse<{ id?: string }>>({
    token,
    path: `/appStoreVersions/${appStoreVersionId}/appStoreVersionLocalizations`,
  });
  const localizations = locResponse.data ?? [];
  if (localizations.length > 0) {
    for (const loc of localizations) {
      const locId = requireNonEmptyString(loc.id, "localizationId");
      await ascApiFetch({
        token,
        path: `/appStoreVersionLocalizations/${locId}`,
        method: "PATCH",
        body: {
          data: {
            type: "appStoreVersionLocalizations",
            id: locId,
            attributes: { whatsNew },
          },
        },
      });
    }
    return;
  }

  await ascApiFetch({
    token,
    path: "/appStoreVersionLocalizations",
    method: "POST",
    body: {
      data: {
        type: "appStoreVersionLocalizations",
        attributes: { locale: "en-US", whatsNew },
        relationships: { appStoreVersion: { data: { type: "appStoreVersions", id: appStoreVersionId } } },
      },
    },
  });
}

export const ascSubmitForReview = onCall<
  SubmitForReviewRequest,
  Promise<{ success: true; appStoreVersionId: string }>
>(async (request) => {
  const auth = requireAuth(request.auth);
  const teamId = requireNonEmptyString(request.data?.teamId, "teamId");
  const appId = requireNonEmptyString(request.data?.appId, "appId");
  const buildId = requireNonEmptyString(request.data?.buildId, "buildId");
  const versionString = requireNonEmptyString(request.data?.versionString, "versionString");
  const whatsNew = requireNonEmptyString(request.data?.whatsNew, "whatsNew");
  const platform = request.data?.platform ?? "IOS";
  const token = await getAscToken(teamId, auth);

  const appStoreVersionId = await resolveAppStoreVersion({
    token,
    appId,
    versionString,
    platform,
  });
  await setWhatsNew({ token, appStoreVersionId, whatsNew });

  await ascApiFetch({
    token,
    path: `/appStoreVersions/${appStoreVersionId}/relationships/build`,
    method: "PATCH",
    body: { data: { type: "builds", id: buildId } },
  });

  try {
    await ascApiFetch({
      token,
      path: `/builds/${buildId}`,
      method: "PATCH",
      body: {
        data: {
          type: "builds",
          id: buildId,
          attributes: { usesNonExemptEncryption: false },
        },
      },
    });
  } catch (error) {
    logger.warn("Failed to set usesNonExemptEncryption", { buildId, error });
  }

  const reviewSubmission = await ascApiFetch<{ data?: { id?: string } }>({
    token,
    path: "/reviewSubmissions",
    method: "POST",
    body: {
      data: {
        type: "reviewSubmissions",
        relationships: { app: { data: { type: "apps", id: appId } } },
      },
    },
  });
  const reviewSubmissionId = requireNonEmptyString(reviewSubmission.data?.id, "reviewSubmissionId");

  await ascApiFetch({
    token,
    path: "/reviewSubmissionItems",
    method: "POST",
    body: {
      data: {
        type: "reviewSubmissionItems",
        relationships: {
          reviewSubmission: { data: { type: "reviewSubmissions", id: reviewSubmissionId } },
          appStoreVersion: { data: { type: "appStoreVersions", id: appStoreVersionId } },
        },
      },
    },
  });

  await ascApiFetch({
    token,
    path: `/reviewSubmissions/${reviewSubmissionId}`,
    method: "PATCH",
    body: {
      data: {
        type: "reviewSubmissions",
        id: reviewSubmissionId,
        attributes: { submitted: true },
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
});
