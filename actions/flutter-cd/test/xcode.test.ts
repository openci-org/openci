import { mkdir, mkdtemp, readFile, rm, writeFile } from "fs/promises";
import { tmpdir } from "os";
import { join } from "path";
import { afterEach, describe, expect, it } from "vitest";

import {
  appendXcodeCompilationCacheSettings,
  prepareXcodeCompilationCacheXcconfig,
} from "../src/xcode";

let tempDir: string | undefined;

afterEach(async () => {
  if (tempDir) {
    await rm(tempDir, { recursive: true, force: true });
    tempDir = undefined;
  }
});

describe("Xcode compilation cache xcconfig", () => {
  it("creates an xcconfig with compilation cache enabled", async () => {
    tempDir = await mkdtemp(join(tmpdir(), "flutter-cd-xcode-"));
    const xcconfigPath = prepareXcodeCompilationCacheXcconfig(tempDir);

    await expect(readFile(xcconfigPath, "utf8")).resolves.toBe(
      "COMPILATION_CACHE_ENABLE_CACHING = True\n",
    );
  });

  it("appends compilation cache settings to an existing xcconfig", async () => {
    tempDir = await mkdtemp(join(tmpdir(), "flutter-cd-xcode-"));
    await mkdir(tempDir, { recursive: true });
    const xcconfigPath = join(tempDir, "Runner.xcconfig");

    await writeFile(xcconfigPath, "CODE_SIGNING_ALLOWED = NO\n");
    appendXcodeCompilationCacheSettings(xcconfigPath);

    await expect(readFile(xcconfigPath, "utf8")).resolves.toBe(
      "CODE_SIGNING_ALLOWED = NO\nCOMPILATION_CACHE_ENABLE_CACHING = True\n",
    );
  });
});
