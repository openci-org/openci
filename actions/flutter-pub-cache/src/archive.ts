import { readdir, rm, mkdir } from "fs/promises";
import { basename, dirname } from "path";

import { compressionExtension } from "./compression";
import { pipeCommands, run } from "./process_runner";

export async function createArchive(cacheDir: string, archivePath: string): Promise<void> {
  const parent = dirname(cacheDir);
  const name = basename(cacheDir);

  if ((await compressionExtension()) === "tar.zst") {
    await pipeCommands(
      [
        "tar",
        ["-cf", "-", "--exclude", `${name}/_temp`, "--exclude", `${name}/log`, "-C", parent, name],
      ],
      ["zstd", ["-T0", "-1", "-q", "-o", archivePath]],
    );
    return;
  }

  await run("tar", [
    "-czf",
    archivePath,
    "--exclude",
    `${name}/_temp`,
    "--exclude",
    `${name}/log`,
    "-C",
    parent,
    name,
  ]);
}

export async function extractArchive(cacheDir: string, archivePath: string): Promise<void> {
  const parent = dirname(cacheDir);
  await rm(cacheDir, { recursive: true, force: true });
  await mkdir(parent, { recursive: true });

  if (archivePath.endsWith(".zst")) {
    await pipeCommands(["zstd", ["-dc", archivePath]], ["tar", ["-xf", "-", "-C", parent]]);
    return;
  }

  await run("tar", ["-xzf", archivePath, "-C", parent]);
}

export async function du(path: string): Promise<void> {
  const result = await run("du", ["-sh", path], { ignoreFailure: true });
  if (result.stdout.trim()) {
    console.log(result.stdout.trim());
  }
}

export async function countFiles(path: string): Promise<number> {
  let count = 0;
  async function visit(dir: string): Promise<void> {
    const entries = await readdir(dir, { withFileTypes: true }).catch(() => []);
    for (const entry of entries) {
      const child = `${dir}/${entry.name}`;
      if (entry.isDirectory()) {
        await visit(child);
      } else if (entry.isFile()) {
        count += 1;
      }
    }
  }
  await visit(path);
  return count;
}
