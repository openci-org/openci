import { mkdtemp, rm } from "fs/promises";
import { tmpdir } from "os";
import { join } from "path";

import { cacheObjectName } from "./cache_key";
import { UsageError, messageFrom } from "./errors";
import { restoreCache, saveCache } from "./gcs";
import { setOutput, warning } from "./github";
import { readInputs } from "./inputs";
import { storageBucket } from "./storage_bucket";
import { createStorageClient } from "./storage_client";
import type { Inputs } from "./types";

export async function main(): Promise<void> {
  let tmpDir = "";
  let inputs: Inputs | undefined;
  try {
    inputs = readInputs();
    tmpDir = await mkdtemp(join(tmpdir(), "flutter-pub-cache-"));

    setOutput("cache-hit", "false");
    setOutput("cache-saved", "false");

    const objectName = await cacheObjectName(inputs, tmpDir);
    setOutput("object-name", objectName);

    if (!inputs.serviceAccount) {
      console.log(`service-account is not set; skipping remote Flutter pub cache ${inputs.action}`);
      return;
    }

    const bucket = await storageBucket(inputs);
    if (!bucket) {
      throw new UsageError(
        `storage-bucket is not set and storageBucket could not be read from ${inputs.firebaseOptionsPath}`,
      );
    }

    const storage = createStorageClient(inputs.serviceAccount);
    if (inputs.action === "restore") {
      await restoreCache({ storage, bucket, objectName, cacheDir: inputs.cachePath, tmpDir });
    } else {
      await saveCache({ storage, bucket, objectName, cacheDir: inputs.cachePath, tmpDir });
    }
  } catch (error) {
    if (error instanceof UsageError) {
      console.error(error.message);
      process.exitCode = 2;
    } else if (inputs) {
      await handleError(error, inputs);
    } else {
      console.error(messageFrom(error));
      process.exitCode = 1;
    }
  } finally {
    if (tmpDir) {
      await rm(tmpDir, { recursive: true, force: true });
    }
  }
}

async function handleError(error: unknown, inputs: Inputs): Promise<void> {
  const message = error instanceof Error ? error.message : String(error);

  if (error instanceof UsageError) {
    console.error(message);
    process.exitCode = 2;
    return;
  }

  if (inputs.failOnError) {
    console.error(message);
    process.exitCode = 1;
    return;
  }

  warning(
    `Flutter pub cache ${inputs.action} failed; continuing because fail-on-error is false. ${message}`,
  );
}
