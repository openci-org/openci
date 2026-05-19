import { spawn } from "child_process";
import { writeFile } from "fs/promises";

import { OperationError, messageFrom } from "./errors";

export async function run(
  command: string,
  args: string[],
  options: {
    stdoutFile?: string;
    ignoreFailure?: boolean;
  } = {},
): Promise<{ code: number; stdout: string; stderr: string }> {
  return new Promise((resolvePromise, reject) => {
    const child = spawn(command, args, { stdio: ["ignore", "pipe", "pipe"] });
    const stdout: Buffer[] = [];
    const stderr: Buffer[] = [];

    child.stdout.on("data", (chunk) => stdout.push(Buffer.from(chunk)));
    child.stderr.on("data", (chunk) => stderr.push(Buffer.from(chunk)));
    child.on("error", (error) => {
      if (options.ignoreFailure) {
        resolvePromise({ code: 127, stdout: "", stderr: messageFrom(error) });
      } else {
        reject(error);
      }
    });
    child.on("close", async (code) => {
      const stdoutText = Buffer.concat(stdout).toString();
      const stderrText = Buffer.concat(stderr).toString();
      if (options.stdoutFile) {
        await writeFile(options.stdoutFile, stdoutText);
      }
      if (code && !options.ignoreFailure) {
        reject(
          new OperationError(
            `${command} ${args.join(" ")} failed with exit code ${code}: ${stderrText}`,
          ),
        );
      } else {
        resolvePromise({ code: code || 0, stdout: stdoutText, stderr: stderrText });
      }
    });
  });
}

export async function pipeCommands(
  from: [string, string[]],
  to: [string, string[]],
): Promise<void> {
  await new Promise<void>((resolvePromise, reject) => {
    const first = spawn(from[0], from[1], { stdio: ["ignore", "pipe", "inherit"] });
    const second = spawn(to[0], to[1], { stdio: ["pipe", "inherit", "inherit"] });
    let firstCode: number | null = null;
    let secondCode: number | null = null;

    first.on("error", reject);
    second.on("error", reject);
    first.stdout.pipe(second.stdin);

    const maybeDone = () => {
      if (firstCode == null || secondCode == null) {
        return;
      }
      if (firstCode !== 0) {
        reject(
          new OperationError(`${from[0]} ${from[1].join(" ")} failed with exit code ${firstCode}`),
        );
      } else if (secondCode !== 0) {
        reject(
          new OperationError(`${to[0]} ${to[1].join(" ")} failed with exit code ${secondCode}`),
        );
      } else {
        resolvePromise();
      }
    };

    first.on("close", (code) => {
      firstCode = code ?? 0;
      maybeDone();
    });
    second.on("close", (code) => {
      secondCode = code ?? 0;
      maybeDone();
    });
  });
}
