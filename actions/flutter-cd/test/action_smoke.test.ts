import { spawn } from "child_process";
import { chmod, mkdir, mkdtemp, readFile, rm, writeFile } from "fs/promises";
import { tmpdir } from "os";
import { dirname, join, resolve } from "path";
import { fileURLToPath } from "url";
import { afterEach, beforeAll, describe, expect, it } from "vitest";

const actionDir = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const distEntry = join(actionDir, "dist", "index.js");
const npmCommand = process.platform === "win32" ? "npm.cmd" : "npm";

let tempDir: string | undefined;

beforeAll(async () => {
  const result = await run(npmCommand, ["run", "build"], { cwd: actionDir });
  expect(result.code, result.stderr || result.stdout).toBe(0);
}, 30_000);

afterEach(async () => {
  if (tempDir) {
    await rm(tempDir, { recursive: true, force: true });
    tempDir = undefined;
  }
});

describe("dist action smoke", () => {
  it("rejects an unsupported platform at the bundled entrypoint", async () => {
    const result = await run(process.execPath, [distEntry], {
      cwd: actionDir,
      env: actionEnv({
        INPUT_PLATFORM: "windows",
      }),
    });

    expect(result.code).toBe(1);
    expect(result.stdout + result.stderr).toContain("Unsupported platform: windows");
  });

  it("builds web and skips deploy when firebase-service-account is missing", async () => {
    tempDir = await mkdtemp(join(tmpdir(), "flutter-cd-smoke-"));
    await writeFile(join(tempDir, "pubspec.yaml"), "name: smoke\n");

    const binDir = join(tempDir, "bin");
    const flutterLog = join(tempDir, "flutter.log");
    await mkdir(binDir);
    await writeExecutable(
      join(binDir, "flutter"),
      `#!/usr/bin/env bash
printf '%s\\n' "$*" >> "$FLUTTER_LOG"
if [ "$1" = "build" ] && [ "$2" = "web" ]; then
  mkdir -p build/web
  exit 0
fi
exit 42
`,
    );

    const result = await run(process.execPath, [distEntry], {
      cwd: actionDir,
      env: actionEnv({
        FLUTTER_LOG: flutterLog,
        INPUT_PLATFORM: "web",
        INPUT_WORKING_DIRECTORY: tempDir,
        PATH: `${binDir}:${process.env.PATH ?? ""}`,
      }),
    });

    expect(result.code, result.stderr || result.stdout).toBe(0);
    expect(result.stdout).toContain("No firebase-service-account provided, skipping deploy.");
    await expect(readFile(flutterLog, "utf8")).resolves.toBe("build web\n");
  });
});

async function writeExecutable(path: string, contents: string): Promise<void> {
  await writeFile(path, contents);
  await chmod(path, 0o755);
}

function actionEnv(overrides: NodeJS.ProcessEnv): NodeJS.ProcessEnv {
  const env = { ...process.env };
  for (const key of Object.keys(env)) {
    if (key.startsWith("INPUT_")) {
      delete env[key];
    }
  }
  delete env.FIREBASE_SERVICE_ACCOUNT;
  return { ...env, ...overrides };
}

function run(
  command: string,
  args: string[],
  options: { cwd: string; env?: NodeJS.ProcessEnv },
): Promise<{ code: number; stdout: string; stderr: string }> {
  return new Promise((resolvePromise, reject) => {
    const child = spawn(command, args, {
      cwd: options.cwd,
      env: options.env,
      stdio: ["ignore", "pipe", "pipe"],
    });
    const stdout: Buffer[] = [];
    const stderr: Buffer[] = [];

    child.stdout.on("data", (chunk) => stdout.push(Buffer.from(chunk)));
    child.stderr.on("data", (chunk) => stderr.push(Buffer.from(chunk)));
    child.on("error", reject);
    child.on("close", (code) => {
      resolvePromise({
        code: code ?? 0,
        stdout: Buffer.concat(stdout).toString(),
        stderr: Buffer.concat(stderr).toString(),
      });
    });
  });
}
