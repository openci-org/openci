import { UsageError } from "./errors";
import { absolutePath, expandPath } from "./paths";
import type { Inputs } from "./types";

export function readInputs(): Inputs {
  const actionInput = getInput("action", { required: true });
  if (actionInput !== "restore" && actionInput !== "save") {
    throw new UsageError("Usage: flutter-pub-cache <restore|save>");
  }

  const workingDirectory = absolutePath(
    getInput("working-directory") || ".",
    process.env.GITHUB_WORKSPACE || process.cwd(),
  );

  return {
    action: actionInput,
    serviceAccount: getInput("service-account") || process.env.FIREBASE_SERVICE_ACCOUNT || "",
    storageBucket: getInput("storage-bucket"),
    firebaseOptionsPath: getInput("firebase-options-path") || "lib/firebase_options.dart",
    cachePath: expandPath(getInput("cache-path") || process.env.PUB_CACHE || "~/.pub-cache"),
    keyPrefix: getInput("key-prefix") || "caches/flutter-pub",
    dependencyPaths: getInput("dependency-paths"),
    workingDirectory,
    repository: getInput("repository") || process.env.GITHUB_REPOSITORY || "unknown-repository",
    failOnError: parseBoolean(getInput("fail-on-error")),
  };
}

function getInput(name: string, options: { required?: boolean } = {}): string {
  const envNames = [
    `INPUT_${name.toUpperCase()}`,
    `INPUT_${name.replace(/-/g, "_").toUpperCase()}`,
    `INPUT_${name.replace(/ /g, "_").toUpperCase()}`,
  ];
  const value = envNames.map((envName) => process.env[envName]).find((item) => item != null) ?? "";
  const trimmed = value.trim();
  if (options.required && !trimmed) {
    throw new UsageError(`Input required and not supplied: ${name}`);
  }
  return trimmed;
}

function parseBoolean(value: string): boolean {
  return /^(1|true|yes)$/i.test(value);
}
