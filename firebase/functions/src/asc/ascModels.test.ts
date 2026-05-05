import { describe, expect, it } from "vitest";
import {
  ascAppFromJsonApi,
  ascBetaGroupFromJsonApi,
  ascBuildFromJsonApi,
  parseIncludedResources,
} from "./ascModels";

describe("ASC models", () => {
  it("maps apps from ASC JSON:API", () => {
    expect(
      ascAppFromJsonApi({
        id: "app-1",
        attributes: { name: "OpenCI", bundleId: "org.openci.app", sku: "SKU" },
      }),
    ).toEqual({
      id: "app-1",
      name: "OpenCI",
      bundleId: "org.openci.app",
      sku: "SKU",
    });
  });

  it("maps included build resources", () => {
    const resources = parseIncludedResources([
      {
        type: "preReleaseVersions",
        id: "pre-1",
        attributes: { version: "1.0.0", platform: "IOS" },
      },
      { type: "buildBetaDetails", id: "beta-1", attributes: { externalBuildState: "READY" } },
      { type: "appStoreVersions", id: "store-1", attributes: { appStoreState: "READY" } },
    ]);

    expect(
      ascBuildFromJsonApi(
        {
          id: "build-1",
          attributes: { version: "42", uploadedDate: "2026-01-01T00:00:00Z" },
          relationships: {
            preReleaseVersion: { data: { id: "pre-1" } },
            buildBetaDetail: { data: { id: "beta-1" } },
            appStoreVersion: { data: { id: "store-1" } },
          },
        },
        resources,
      ),
    ).toEqual(
      expect.objectContaining({
        id: "build-1",
        version: "1.0.0",
        buildNumber: "42",
        platform: "IOS",
        externalBuildState: "READY",
        appStoreState: "READY",
      }),
    );
  });

  it("maps beta groups", () => {
    expect(
      ascBetaGroupFromJsonApi({
        id: "group-1",
        attributes: { name: "External Testers", isInternalGroup: false },
      }),
    ).toEqual({ id: "group-1", name: "External Testers", isInternalGroup: false });
  });
});
