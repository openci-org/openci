import { describe, expect, it } from "vitest";

import { backoffMilliSeconds } from "./backoff.js";

describe("backoffMilliSeconds", () => {
  it("returns 10s when consecutiveFailures is 0", () => {
    expect(backoffMilliSeconds(0)).toBe(10_000);
  });

  it("doubles on each consecutive failure", () => {
    expect(backoffMilliSeconds(1)).toBe(20_000);
    expect(backoffMilliSeconds(2)).toBe(40_000);
    expect(backoffMilliSeconds(3)).toBe(80_000);
    expect(backoffMilliSeconds(4)).toBe(160_000);
  });

  it("caps at 5 minutes", () => {
    const fiveMinutes = 5 * 60_000;
    expect(backoffMilliSeconds(5)).toBe(fiveMinutes);
    expect(backoffMilliSeconds(6)).toBe(fiveMinutes);
    expect(backoffMilliSeconds(100)).toBe(fiveMinutes);
  });
});
