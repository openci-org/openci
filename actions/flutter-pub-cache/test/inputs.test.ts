import { afterEach, describe, expect, it } from "vitest";

import { UsageError } from "../src/errors";
import { readInputs } from "../src/inputs";

const originalEnv = { ...process.env };

afterEach(() => {
  for (const key of Object.keys(process.env)) {
    if (!(key in originalEnv)) {
      delete process.env[key];
    }
  }
  Object.assign(process.env, originalEnv);
});

describe("readInputs", () => {
  it("rejects misspelled actions", () => {
    process.env.INPUT_ACTION = "restroe";

    expect(() => readInputs()).toThrow(UsageError);
    expect(() => readInputs()).toThrow("Usage: flutter-pub-cache <restore|save>");
  });

  it("reads defaults and environment fallbacks", () => {
    process.env.INPUT_ACTION = "restore";
    process.env.FIREBASE_SERVICE_ACCOUNT = '{"client_email":"service@example.com"}';
    process.env.GITHUB_REPOSITORY = "openci-org/openci";
    process.env.GITHUB_WORKSPACE = "/tmp/openci";
    process.env.HOME = "/tmp/home";

    const inputs = readInputs();

    expect(inputs).toMatchObject({
      action: "restore",
      serviceAccount: '{"client_email":"service@example.com"}',
      storageBucket: "",
      firebaseOptionsPath: "lib/firebase_options.dart",
      cachePath: "/tmp/home/.pub-cache",
      keyPrefix: "caches/flutter-pub",
      dependencyPaths: "",
      workingDirectory: "/tmp/openci",
      repository: "openci-org/openci",
      failOnError: false,
    });
  });

  it("supports dash inputs via underscore environment names", () => {
    process.env.INPUT_ACTION = "save";
    process.env.INPUT_FAIL_ON_ERROR = "true";
    process.env.INPUT_STORAGE_BUCKET = "openci-b1b91.firebasestorage.app";
    process.env.INPUT_WORKING_DIRECTORY = "apps/dashboard";
    process.env.GITHUB_WORKSPACE = "/tmp/openci";

    const inputs = readInputs();

    expect(inputs.action).toBe("save");
    expect(inputs.failOnError).toBe(true);
    expect(inputs.storageBucket).toBe("openci-b1b91.firebasestorage.app");
    expect(inputs.workingDirectory).toBe("/tmp/openci/apps/dashboard");
  });
});
