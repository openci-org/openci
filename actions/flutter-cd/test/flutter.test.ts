import { describe, expect, it } from "vitest";

import { buildNoPubArg, parseSwiftPackageManagerMode } from "../src/flutter";

describe("parseSwiftPackageManagerMode", () => {
  it("accepts inherit aliases", () => {
    expect(parseSwiftPackageManagerMode("")).toBe("inherit");
    expect(parseSwiftPackageManagerMode(" inherit ")).toBe("inherit");
    expect(parseSwiftPackageManagerMode("auto")).toBe("inherit");
  });

  it("accepts enabled and disabled aliases", () => {
    expect(parseSwiftPackageManagerMode("enabled")).toBe("enabled");
    expect(parseSwiftPackageManagerMode("enable")).toBe("enabled");
    expect(parseSwiftPackageManagerMode("true")).toBe("enabled");

    expect(parseSwiftPackageManagerMode("disabled")).toBe("disabled");
    expect(parseSwiftPackageManagerMode("disable")).toBe("disabled");
    expect(parseSwiftPackageManagerMode("false")).toBe("disabled");
  });

  it("rejects unsupported values", () => {
    expect(() => parseSwiftPackageManagerMode("maybe")).toThrow(
      'Unsupported swift-package-manager: maybe. Use "inherit", "enabled", or "disabled".',
    );
  });
});

describe("buildNoPubArg", () => {
  it("uses --no-pub only when pub get already ran and build args do not include it", () => {
    expect(buildNoPubArg(true, "")).toBe("--no-pub");
    expect(buildNoPubArg(true, "--dart-define=FOO=bar")).toBe("--no-pub");
    expect(buildNoPubArg(false, "")).toBe("");
    expect(buildNoPubArg(true, "--no-pub --dart-define=FOO=bar")).toBe("");
  });
});
