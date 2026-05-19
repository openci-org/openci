import { mkdir, mkdtemp, rm, writeFile } from "fs/promises";
import { tmpdir } from "os";
import { join } from "path";
import { afterEach, describe, expect, it } from "vitest";

import { dependencyHash } from "../src/dependency_hash";
import type { Inputs } from "../src/types";

let tempDir: string | undefined;

afterEach(async () => {
  if (tempDir) {
    await rm(tempDir, { recursive: true, force: true });
    tempDir = undefined;
  }
});

describe("dependencyHash", () => {
  it("auto-detects pubspec files and ignores generated directories", async () => {
    tempDir = await mkdtemp(join(tmpdir(), "flutter-pub-cache-test-"));
    await writeFile(join(tempDir, "pubspec.yaml"), "name: root\n");
    await writeFile(join(tempDir, "pubspec.lock"), "# lock\n");

    await mkdir(join(tempDir, "packages", "example"), { recursive: true });
    await writeFile(join(tempDir, "packages", "example", "pubspec.yaml"), "name: example\n");

    await mkdir(join(tempDir, "build", "generated"), { recursive: true });
    await writeFile(join(tempDir, "build", "generated", "pubspec.yaml"), "name: ignored\n");

    const hash = await dependencyHash(inputsFor(tempDir));
    await writeFile(join(tempDir, "build", "generated", "pubspec.yaml"), "name: still_ignored\n");
    const hashAfterIgnoredChange = await dependencyHash(inputsFor(tempDir));

    expect(hash).toMatch(/^[0-9a-f]{20}$/);
    expect(hashAfterIgnoredChange).toBe(hash);
  });

  it("changes when an explicit dependency file changes", async () => {
    tempDir = await mkdtemp(join(tmpdir(), "flutter-pub-cache-test-"));
    await mkdir(join(tempDir, "apps", "dashboard"), { recursive: true });
    const pubspecPath = join(tempDir, "apps", "dashboard", "pubspec.yaml");
    await writeFile(pubspecPath, "name: dashboard\n");

    const inputs = inputsFor(tempDir, {
      dependencyPaths: "apps/dashboard/pubspec.yaml",
    });
    const before = await dependencyHash(inputs);

    await writeFile(pubspecPath, "name: dashboard\ndependencies:\n  path: any\n");
    const after = await dependencyHash(inputs);

    expect(after).not.toBe(before);
  });
});

function inputsFor(workingDirectory: string, overrides: Partial<Inputs> = {}): Inputs {
  return {
    action: "restore",
    serviceAccount: "",
    storageBucket: "",
    firebaseOptionsPath: "lib/firebase_options.dart",
    cachePath: "~/.pub-cache",
    keyPrefix: "caches/flutter-pub",
    dependencyPaths: "",
    workingDirectory,
    repository: "openci-org/openci",
    failOnError: false,
    ...overrides,
  };
}
