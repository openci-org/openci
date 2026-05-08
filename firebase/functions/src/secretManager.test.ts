import { describe, expect, it } from "vitest";
import { resolveProjectId } from "./secretManager.js";

describe("resolveProjectId", () => {
  it("returns an explicit project id", () => {
    expect(resolveProjectId("test-project")).toBe("test-project");
  });

  it("throws for an empty explicit project id", () => {
    expect(() => resolveProjectId("")).toThrow("GCLOUD_PROJECT");
  });
});
