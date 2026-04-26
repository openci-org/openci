import { describe, expect, it } from "vitest";
import { buildSecretPath, extractSecretData, resolveProjectId } from "./secretManager";

describe("resolveProjectId", () => {
  it("returns an explicit project id", () => {
    expect(resolveProjectId("test-project")).toBe("test-project");
  });

  it("throws for an empty explicit project id", () => {
    expect(() => resolveProjectId("")).toThrow("GCLOUD_PROJECT");
  });
});

describe("buildSecretPath", () => {
  it("builds a latest secret version path", () => {
    expect(buildSecretPath("test-project", "secret-id")).toBe(
      "projects/test-project/secrets/secret-id/versions/latest",
    );
  });

  it("throws when secret id is empty", () => {
    expect(() => buildSecretPath("test-project", "  ")).toThrow("secretId");
  });
});

describe("extractSecretData", () => {
  it("extracts utf8 secret data", () => {
    const response = {
      payload: {
        data: Buffer.from("my-secret-value"),
      },
    };

    expect(extractSecretData(response, "secret-id")).toBe("my-secret-value");
  });

  it("throws when the secret has no data", () => {
    expect(() => extractSecretData({ payload: {} }, "secret-id")).toThrow("has no data");
  });
});
