import { readFile } from "fs/promises";
import { join } from "path";

import { compressionExtension } from "./compression";
import { dependencyHash } from "./dependency_hash";
import { sanitizeComponent } from "./paths";
import { run } from "./process_runner";
import type { Inputs } from "./types";

export async function cacheObjectName(inputs: Inputs, tmpDir: string): Promise<string> {
  const host = await hostCacheKeyComponent();
  const flutter = await flutterCacheKeyComponent(tmpDir);
  const deps = await dependencyHash(inputs);
  const extension = await compressionExtension();

  return [
    inputs.keyPrefix.replace(/\/+$/, ""),
    inputs.repository,
    host,
    flutter,
    `deps-${deps}.${extension}`,
  ].join("/");
}

async function hostCacheKeyComponent(): Promise<string> {
  const os = await run("uname", ["-s"], { ignoreFailure: true });
  const arch = await run("uname", ["-m"], { ignoreFailure: true });
  if (os.code === 0 && arch.code === 0) {
    return sanitizeComponent(`${os.stdout.trim()}-${arch.stdout.trim()}`);
  }
  return sanitizeComponent(`${process.platform}-${process.arch}`);
}

async function flutterCacheKeyComponent(tmpDir: string): Promise<string> {
  const versionFile = join(tmpDir, "flutter-version.json");
  const result = await run("flutter", ["--version", "--machine"], {
    stdoutFile: versionFile,
    ignoreFailure: true,
  });
  if (result.code !== 0) {
    return "unknown-flutter";
  }

  try {
    const data = JSON.parse(await readFile(versionFile, "utf8")) as {
      frameworkVersion?: string;
      frameworkRevision?: string;
      dartSdkVersion?: string;
    };
    const value = [data.frameworkVersion, data.frameworkRevision?.slice(0, 12), data.dartSdkVersion]
      .filter(Boolean)
      .join("-");
    return sanitizeComponent(value || "unknown-flutter");
  } catch {
    return "unknown-flutter";
  }
}
