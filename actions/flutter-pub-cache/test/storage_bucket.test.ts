import { mkdtemp, mkdir, rm, writeFile } from "fs/promises";
import { tmpdir } from "os";
import { join } from "path";
import { afterEach, describe, expect, it } from "vitest";

import { storageBucket } from "../src/storage_bucket";
import type { Inputs } from "../src/types";

let tempDir: string | undefined;

afterEach(async () => {
  if (tempDir) {
    await rm(tempDir, { recursive: true, force: true });
    tempDir = undefined;
  }
});

describe("storageBucket", () => {
  it("prefers explicit storage-bucket", async () => {
    const inputs = inputsFor("/tmp/openci", {
      storageBucket: "explicit.firebasestorage.app",
    });

    await expect(storageBucket(inputs)).resolves.toBe("explicit.firebasestorage.app");
  });

  it("reads storageBucket from firebase_options.dart", async () => {
    tempDir = await mkdtemp(join(tmpdir(), "flutter-pub-cache-test-"));
    await mkdir(join(tempDir, "lib"));
    await writeFile(
      join(tempDir, "lib", "firebase_options.dart"),
      "const options = FirebaseOptions(storageBucket: 'openci-b1b91.firebasestorage.app');",
    );

    await expect(storageBucket(inputsFor(tempDir))).resolves.toBe(
      "openci-b1b91.firebasestorage.app",
    );
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
