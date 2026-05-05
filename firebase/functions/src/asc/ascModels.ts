type JsonMap = Record<string, unknown>;

export interface AscApp {
  id: string;
  name: string;
  bundleId: string;
  sku?: string;
}

export interface AscBuild {
  id: string;
  version: string;
  buildNumber: string;
  platform: string;
  uploadedDate?: string;
  processingState?: string;
  iconUrl?: string;
  externalBuildState?: string;
  internalBuildState?: string;
  appStoreState?: string;
}

export interface AscBetaGroup {
  id: string;
  name: string;
  isInternalGroup: boolean;
}

function attrs(json: JsonMap): JsonMap {
  return typeof json.attributes === "object" && json.attributes !== null
    ? (json.attributes as JsonMap)
    : {};
}

function relationshipId(json: JsonMap, key: string): string | undefined {
  const relationships =
    typeof json.relationships === "object" && json.relationships !== null
      ? (json.relationships as JsonMap)
      : {};
  const rel = relationships[key];
  if (typeof rel !== "object" || rel === null) return undefined;
  const data = (rel as JsonMap).data;
  if (typeof data !== "object" || data === null) return undefined;
  const id = (data as JsonMap).id;
  return typeof id === "string" ? id : undefined;
}

export function ascAppFromJsonApi(json: JsonMap): AscApp {
  const attributes = attrs(json);
  return {
    id: String(json.id ?? ""),
    name: String(attributes.name ?? ""),
    bundleId: String(attributes.bundleId ?? ""),
    sku: typeof attributes.sku === "string" ? attributes.sku : undefined,
  };
}

export function parseIncludedResources(included: unknown[]): {
  preReleaseVersions: Record<string, JsonMap>;
  buildBetaDetails: Record<string, JsonMap>;
  appStoreVersions: Record<string, JsonMap>;
} {
  const preReleaseVersions: Record<string, JsonMap> = {};
  const buildBetaDetails: Record<string, JsonMap> = {};
  const appStoreVersions: Record<string, JsonMap> = {};

  for (const item of included) {
    if (typeof item !== "object" || item === null) continue;
    const map = item as JsonMap;
    const id = typeof map.id === "string" ? map.id : undefined;
    const type = typeof map.type === "string" ? map.type : undefined;
    if (!id || !type) continue;
    const attributes = attrs(map);
    if (type === "preReleaseVersions") preReleaseVersions[id] = attributes;
    if (type === "buildBetaDetails") buildBetaDetails[id] = attributes;
    if (type === "appStoreVersions") appStoreVersions[id] = attributes;
  }

  return { preReleaseVersions, buildBetaDetails, appStoreVersions };
}

export function ascBuildFromJsonApi(
  json: JsonMap,
  resources: ReturnType<typeof parseIncludedResources>,
): AscBuild {
  const attributes = attrs(json);
  const preReleaseVersionId = relationshipId(json, "preReleaseVersion");
  const betaDetailId = relationshipId(json, "buildBetaDetail");
  const appStoreVersionId = relationshipId(json, "appStoreVersion");
  const preRelease = preReleaseVersionId
    ? resources.preReleaseVersions[preReleaseVersionId]
    : undefined;
  const betaDetail = betaDetailId ? resources.buildBetaDetails[betaDetailId] : undefined;
  const appStoreVersion = appStoreVersionId
    ? resources.appStoreVersions[appStoreVersionId]
    : undefined;

  const iconToken =
    typeof attributes.iconAssetToken === "object" && attributes.iconAssetToken !== null
      ? (attributes.iconAssetToken as JsonMap)
      : undefined;
  const templateUrl =
    typeof iconToken?.templateUrl === "string" ? iconToken.templateUrl : undefined;

  return {
    id: String(json.id ?? ""),
    version: String(preRelease?.version ?? attributes.version ?? ""),
    buildNumber: String(attributes.version ?? ""),
    platform: String(preRelease?.platform ?? "IOS"),
    uploadedDate: typeof attributes.uploadedDate === "string" ? attributes.uploadedDate : undefined,
    processingState:
      typeof attributes.processingState === "string" ? attributes.processingState : undefined,
    iconUrl: templateUrl?.replaceAll("{w}", "64").replaceAll("{h}", "64").replaceAll("{f}", "png"),
    externalBuildState:
      typeof betaDetail?.externalBuildState === "string"
        ? betaDetail.externalBuildState
        : undefined,
    internalBuildState:
      typeof betaDetail?.internalBuildState === "string"
        ? betaDetail.internalBuildState
        : undefined,
    appStoreState:
      typeof appStoreVersion?.appStoreState === "string"
        ? appStoreVersion.appStoreState
        : undefined,
  };
}

export function ascBetaGroupFromJsonApi(json: JsonMap): AscBetaGroup {
  const attributes = attrs(json);
  return {
    id: String(json.id ?? ""),
    name: String(attributes.name ?? ""),
    isInternalGroup: attributes.isInternalGroup === true,
  };
}
