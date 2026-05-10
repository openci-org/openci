import { describe, expect, it } from "vitest";

import { matchesTrigger } from "./matchesTrigger.js";

describe("matchesTrigger", () => {
  it("returns false when on is missing", () => {
    expect(matchesTrigger({}, "push")).toBe(false);
  });

  it("returns false when on is null", () => {
    expect(matchesTrigger({ on: null }, "push")).toBe(false);
  });

  describe("string form (on: push)", () => {
    it("matches when string equals triggerType", () => {
      expect(matchesTrigger({ on: "push" }, "push")).toBe(true);
    });

    it("does not match when string differs", () => {
      expect(matchesTrigger({ on: "pull_request" }, "push")).toBe(false);
    });
  });

  describe("array form (on: [push, pull_request])", () => {
    it("matches when array contains triggerType", () => {
      expect(matchesTrigger({ on: ["push", "pull_request"] }, "pull_request")).toBe(true);
    });

    it("does not match when array does not contain triggerType", () => {
      expect(matchesTrigger({ on: ["pull_request"] }, "push")).toBe(false);
    });
  });

  describe("object form (on: { push: ... })", () => {
    it("matches when key exists with null config", () => {
      expect(matchesTrigger({ on: { push: null } }, "push")).toBe(true);
    });

    it("matches when key exists with empty object config", () => {
      expect(matchesTrigger({ on: { push: {} } }, "push")).toBe(true);
    });

    it("does not match when key does not exist", () => {
      expect(matchesTrigger({ on: { pull_request: {} } }, "push")).toBe(false);
    });

    describe("with branches filter", () => {
      it("matches when triggerBranch is in branches list", () => {
        expect(
          matchesTrigger({ on: { push: { branches: ["main", "develop"] } } }, "push", "main"),
        ).toBe(true);
      });

      it("does not match when triggerBranch is not in branches list", () => {
        expect(matchesTrigger({ on: { push: { branches: ["main"] } } }, "push", "feature/x")).toBe(
          false,
        );
      });

      it("matches when branches is a single string and matches", () => {
        expect(matchesTrigger({ on: { push: { branches: "main" } } }, "push", "main")).toBe(true);
      });

      it("matches when triggerBranch is undefined regardless of branches", () => {
        expect(matchesTrigger({ on: { push: { branches: ["main"] } } }, "push")).toBe(true);
      });

      it("matches pull request branch filters", () => {
        expect(
          matchesTrigger(
            {
              on: {
                pull_request: {
                  branches: ["main", "develop"],
                },
              },
            },
            "pull_request",
            "main",
          ),
        ).toBe(true);
      });
    });
  });
});
