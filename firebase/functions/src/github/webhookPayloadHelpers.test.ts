import { describe, expect, it } from "vitest";

import { branchFromRef, ownerFromFullName } from "./webhookPayloadHelpers.js";

describe("branchFromRef", () => {
  it("removes the refs heads prefix", () => {
    expect(branchFromRef("refs/heads/main")).toBe("main");
    expect(branchFromRef("refs/heads/feature/test")).toBe("feature/test");
  });

  it("leaves non-head refs unchanged", () => {
    expect(branchFromRef("refs/tags/v1.0.0")).toBe("refs/tags/v1.0.0");
    expect(branchFromRef("main")).toBe("main");
  });
});

describe("ownerFromFullName", () => {
  it("extracts the owner segment from full_name", () => {
    expect(ownerFromFullName("openci-org/openci")).toBe("openci-org");
  });

  it("returns the whole value when there is no slash", () => {
    expect(ownerFromFullName("openci")).toBe("openci");
  });
});
