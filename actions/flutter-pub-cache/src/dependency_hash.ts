import { createHash } from "crypto";
import { createReadStream } from "fs";
import { stat } from "fs/promises";
import { basename, dirname, isAbsolute, join, relative, sep } from "path";
import fg = require("fast-glob");

import type { Inputs } from "./types";

const ignoredDependencyDirs = [
  ".dart_tool",
  ".firebase",
  ".fvm",
  ".git",
  ".pub-cache",
  ".swiftpm",
  "build",
  "node_modules",
];

const ignoredDependencyPatterns = ignoredDependencyDirs.flatMap((dir) => [
  `${dir}/**`,
  `**/${dir}/**`,
]);

export async function dependencyHash(inputs: Inputs): Promise<string> {
  const files = inputs.dependencyPaths
    ? await dependencyFilesFromPatterns(inputs.workingDirectory, inputs.dependencyPaths)
    : await autoDetectDependencyFiles(inputs.workingDirectory);

  const digest = createHash("sha256");
  for (const file of files) {
    const display = relative(inputs.workingDirectory, file);
    digest.update(display);
    digest.update("\n");
    digest.update(await sha256Digest(file));
    digest.update("  ");
    digest.update(display);
    digest.update("\n");
  }
  return digest.digest("hex").slice(0, 20);
}

async function autoDetectDependencyFiles(workDir: string): Promise<string[]> {
  return sortDependencyFiles(
    await fg(["**/pubspec.yaml", "**/pubspec.lock"], {
      absolute: true,
      cwd: workDir,
      dot: true,
      followSymbolicLinks: false,
      ignore: ignoredDependencyPatterns,
      onlyFiles: true,
    }),
    workDir,
  );
}

async function dependencyFilesFromPatterns(
  workDir: string,
  patternsText: string,
): Promise<string[]> {
  const patterns = patternsText
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line && !line.startsWith("#"));
  const files: string[] = [];
  const seen = new Set<string>();

  for (const pattern of patterns) {
    const matches = hasGlob(pattern)
      ? await fg(pattern, {
          absolute: true,
          cwd: workDir,
          dot: true,
          followSymbolicLinks: false,
          ignore: ignoredDependencyPatterns,
          onlyFiles: true,
        })
      : [isAbsolute(pattern) ? pattern : join(workDir, pattern)];
    for (const match of sortDependencyFiles(matches, workDir)) {
      await addDependencyFile(files, seen, workDir, match);
    }
  }

  return files;
}

async function addDependencyFile(
  files: string[],
  seen: Set<string>,
  workDir: string,
  path: string,
): Promise<void> {
  const absolute = isAbsolute(path) ? path : join(workDir, path);
  if (seen.has(absolute) || isIgnoredDependencyPath(workDir, absolute)) {
    return;
  }
  const info = await stat(absolute).catch(() => null);
  if (info?.isFile()) {
    seen.add(absolute);
    files.push(absolute);
  }
}

function sortDependencyFiles(files: string[], workDir: string): string[] {
  return [...files].sort((a, b) =>
    compareDependencyPath(relative(workDir, a), relative(workDir, b)),
  );
}

function compareDependencyPath(a: string, b: string): number {
  const dirCompare = dirname(a).localeCompare(dirname(b));
  if (dirCompare !== 0) {
    return dirCompare;
  }
  return dependencyFileRank(basename(b)) - dependencyFileRank(basename(a)) || a.localeCompare(b);
}

function dependencyFileRank(name: string): number {
  if (name === "pubspec.yaml") {
    return 1;
  }
  if (name === "pubspec.lock") {
    return 0;
  }
  return -1;
}

function hasGlob(pattern: string): boolean {
  return /[*?[]/.test(pattern);
}

function isIgnoredDependencyPath(workDir: string, path: string): boolean {
  const rel = relative(workDir, path);
  if (!rel || rel.startsWith("..")) {
    return false;
  }
  return rel.split(sep).some((part) => ignoredDependencyDirs.includes(part));
}

async function sha256Digest(path: string): Promise<string> {
  const digest = createHash("sha256");
  for await (const chunk of createReadStream(path)) {
    digest.update(chunk as Buffer);
  }
  return digest.digest("hex");
}
