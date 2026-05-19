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
  it("rejects a misspelled action at the bundled entrypoint", async () => {
    tempDir = await mkdtemp(join(tmpdir(), "flutter-pub-cache-smoke-"));

    const result = await run(process.execPath, [distEntry], {
      cwd: actionDir,
      env: actionEnv({
        GITHUB_WORKSPACE: tempDir,
        HOME: join(tempDir, "home"),
        INPUT_ACTION: "restroe",
      }),
    });

    expect(result.code).toBe(2);
    expect(result.stderr).toContain("Usage: flutter-pub-cache <restore|save>");
  });

  it("writes outputs and skips remote access when service-account is missing", async () => {
    tempDir = await mkdtemp(join(tmpdir(), "flutter-pub-cache-smoke-"));
    await writeFile(join(tempDir, "pubspec.yaml"), "name: smoke\n");

    const binDir = join(tempDir, "bin");
    await mkdir(binDir);
    await writeExecutable(
      join(binDir, "flutter"),
      `#!/usr/bin/env bash
if [ "$1" = "--version" ] && [ "$2" = "--machine" ]; then
  printf '%s\n' '{"frameworkVersion":"3.41.9","frameworkRevision":"00b0c91f0620abc","dartSdkVersion":"3.11.5"}'
else
  exit 1
fi
`,
    );
    await writeExecutable(
      join(binDir, "uname"),
      `#!/usr/bin/env bash
case "$1" in
  -s) echo Linux ;;
  -m) echo x86_64 ;;
  *) exit 1 ;;
esac
`,
    );
    await writeExecutable(join(binDir, "zstd"), "#!/usr/bin/env bash\necho 'zstd 1.5.6'\n");

    const outputPath = join(tempDir, "github-output.txt");
    const result = await run(process.execPath, [distEntry], {
      cwd: actionDir,
      env: actionEnv({
        GITHUB_OUTPUT: outputPath,
        GITHUB_REPOSITORY: "openci-org/example",
        GITHUB_WORKSPACE: tempDir,
        HOME: join(tempDir, "home"),
        INPUT_ACTION: "restore",
        INPUT_KEY_PREFIX: "caches/test",
        PATH: `${binDir}:${process.env.PATH ?? ""}`,
      }),
    });

    expect(result.code, result.stderr || result.stdout).toBe(0);
    expect(result.stdout).toContain(
      "service-account is not set; skipping remote Flutter pub cache restore",
    );

    const outputs = parseOutputs(await readFile(outputPath, "utf8"));
    expect(outputs["cache-hit"]).toBe("false");
    expect(outputs["cache-saved"]).toBe("false");
    expect(outputs["object-name"]).toMatch(
      /^caches\/test\/openci-org\/example\/linux-x86_64\/3\.41\.9-00b0c91f0620-3\.11\.5\/deps-[0-9a-f]{20}\.tar\.zst$/,
    );
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

function parseOutputs(contents: string): Record<string, string> {
  return Object.fromEntries(
    contents
      .trim()
      .split(/\r?\n/)
      .filter(Boolean)
      .map((line) => {
        const separator = line.indexOf("=");
        return [line.slice(0, separator), line.slice(separator + 1)];
      }),
  );
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
