import type { Storage } from "@google-cloud/storage";
import { existsSync } from "fs";
import { stat } from "fs/promises";
import { join } from "path";

import { createArchive, countFiles, du, extractArchive } from "./archive";
import { compressionContentType, compressionExtension } from "./compression";
import { setOutput } from "./github";

export async function restoreCache(options: {
  storage: Storage;
  bucket: string;
  objectName: string;
  cacheDir: string;
  tmpDir: string;
}): Promise<void> {
  const archivePath = join(options.tmpDir, `flutter-pub-cache.${await compressionExtension()}`);
  const file = options.storage.bucket(options.bucket).file(options.objectName);

  console.log(`Restoring Flutter pub cache from gs://${options.bucket}/${options.objectName}`);
  try {
    await file.download({ destination: archivePath });
  } catch (error) {
    if (errorCode(error) === 404) {
      console.log("Flutter pub cache miss");
      setOutput("cache-hit", "false");
      return;
    }
    throw error;
  }

  console.log("Downloaded Flutter pub cache archive:");
  await du(archivePath);

  await extractArchive(options.cacheDir, archivePath);

  console.log("Restored Flutter pub cache:");
  await du(options.cacheDir);
  console.log(`File count: ${await countFiles(options.cacheDir)}`);
  setOutput("cache-hit", "true");
}

export async function saveCache(options: {
  storage: Storage;
  bucket: string;
  objectName: string;
  cacheDir: string;
  tmpDir: string;
}): Promise<void> {
  setOutput("cache-saved", "false");
  const file = options.storage.bucket(options.bucket).file(options.objectName);
  const [exists] = await file.exists();
  if (exists) {
    console.log(
      `Flutter pub cache already exists; skipping upload: gs://${options.bucket}/${options.objectName}`,
    );
    return;
  }

  if (!existsSync(options.cacheDir)) {
    console.log(`Flutter pub cache not found; nothing to save: ${options.cacheDir}`);
    return;
  }

  const archivePath = join(options.tmpDir, `flutter-pub-cache.${await compressionExtension()}`);
  console.log("Creating Flutter pub cache archive:");
  await du(options.cacheDir);
  await createArchive(options.cacheDir, archivePath);
  await du(archivePath);

  const size = (await stat(archivePath)).size;
  const contentType = await compressionContentType();

  console.log(`Uploading Flutter pub cache to gs://${options.bucket}/${options.objectName}`);
  await options.storage.bucket(options.bucket).upload(archivePath, {
    destination: options.objectName,
    metadata: { contentType },
    resumable: true,
  });

  console.log("Uploaded Flutter pub cache");
  console.log(`Uploaded size: ${size}`);
  setOutput("cache-saved", "true");
}

function errorCode(error: unknown): number | undefined {
  if (typeof error === "object" && error !== null && "code" in error) {
    const code = (error as { code?: unknown }).code;
    return typeof code === "number" ? code : Number(code);
  }
  return undefined;
}
