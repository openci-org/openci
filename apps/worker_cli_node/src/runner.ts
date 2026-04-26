import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { spawn, type ChildProcess } from "node:child_process";

import { isJobCancelled } from "./dataconnect.js";
import { envFileContent } from "./env.js";
import { logInfo, logWarning } from "./logger.js";
import type { BuildJob } from "./types.js";

const baseVmName = "tahoe-base_v1.1.1";
const sshUser = "admin";
const sshPassword = "admin";
const dockerImage = "openci-ubuntu:latest";
const sshKeyPath = "/tmp/openci-ssh-key";

function maskToken(message: string, token?: string | null): string {
  if (!token) return message;
  return message.split(token).join("***");
}

function splitLines(chunk: Buffer, carry: string): { lines: string[]; carry: string } {
  const text = carry + chunk.toString("utf8");
  const parts = text.split(/\r?\n/);
  return { lines: parts.slice(0, -1), carry: parts.at(-1) ?? "" };
}

async function runProcess(input: {
  command: string;
  args: string[];
  cwd?: string;
  buildJob: BuildJob;
  runId: string;
  logOutput?: boolean;
  signal?: AbortSignal;
}): Promise<void> {
  const child = spawn(input.command, input.args, {
    cwd: input.cwd,
    stdio: ["ignore", "pipe", "pipe"],
    env: process.env,
  });
  let stdoutCarry = "";
  let stderrCarry = "";

  const writeOutput = async (line: string, warning = false) => {
    if (!input.logOutput || line.length === 0) return;
    const masked = maskToken(line, input.buildJob.installationToken);
    if (warning) await logWarning(input.buildJob.id, input.runId, masked);
    else await logInfo(input.buildJob.id, input.runId, masked);
  };

  child.stdout.on("data", (chunk: Buffer) => {
    const result = splitLines(chunk, stdoutCarry);
    stdoutCarry = result.carry;
    for (const line of result.lines) void writeOutput(line);
  });
  child.stderr.on("data", (chunk: Buffer) => {
    const result = splitLines(chunk, stderrCarry);
    stderrCarry = result.carry;
    for (const line of result.lines) void writeOutput(line, true);
  });

  const abort = () => {
    child.kill("SIGTERM");
    setTimeout(() => {
      if (!child.killed) child.kill("SIGKILL");
    }, 5_000).unref();
  };
  input.signal?.addEventListener("abort", abort, { once: true });

  const exitCode = await new Promise<number | null>((resolve, reject) => {
    child.on("error", reject);
    child.on("close", resolve);
  });
  input.signal?.removeEventListener("abort", abort);

  if (stdoutCarry) await writeOutput(stdoutCarry);
  if (stderrCarry) await writeOutput(stderrCarry, true);
  if (input.signal?.aborted) {
    throw new Error("Build job was cancelled");
  }
  if (exitCode !== 0) {
    throw new Error(`${input.command} exited with code ${exitCode ?? "unknown"}`);
  }
}

async function runSimple(command: string, args: string[], errorMessage: string): Promise<string> {
  const child = spawn(command, args, { stdio: ["ignore", "pipe", "pipe"] });
  const stdout: Buffer[] = [];
  const stderr: Buffer[] = [];
  child.stdout.on("data", (chunk: Buffer) => stdout.push(chunk));
  child.stderr.on("data", (chunk: Buffer) => stderr.push(chunk));
  const exitCode = await new Promise<number | null>((resolve, reject) => {
    child.on("error", reject);
    child.on("close", resolve);
  });
  if (exitCode !== 0) {
    throw new Error(`${errorMessage}: ${Buffer.concat(stderr).toString("utf8").trim()}`);
  }
  return Buffer.concat(stdout).toString("utf8");
}

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function buildEventPayload(buildJob: BuildJob): string {
  const owner = buildJob.owner;
  const repo = buildJob.repo;
  const fullName = `${owner}/${repo}`;
  const commitSha = buildJob.commitSha ?? "";
  const branch = buildJob.branch ?? "";
  const repository = {
    name: repo,
    full_name: fullName,
    owner: { login: owner, name: owner },
    default_branch: branch,
  };

  if (buildJob.pullRequestNumber) {
    return JSON.stringify({
      action: "opened",
      number: buildJob.pullRequestNumber,
      pull_request: {
        number: buildJob.pullRequestNumber,
        head: { ref: branch, sha: commitSha, repo: { full_name: fullName, name: repo } },
        base: { ref: "", sha: "", repo: { full_name: fullName, name: repo } },
      },
      repository,
      sender: { login: owner },
    });
  }

  return JSON.stringify({
    ref: branch ? `refs/heads/${branch}` : "",
    before: "",
    after: commitSha,
    head_commit: { id: commitSha },
    repository,
    pusher: { name: owner },
    sender: { login: owner },
  });
}

function githubHost(buildJob: BuildJob): string {
  return buildJob.githubBaseUrl ? new URL(buildJob.githubBaseUrl).host : "github.com";
}

function actScript(buildJob: BuildJob): string {
  const eventType = buildJob.pullRequestNumber ? "pull_request" : "push";
  const jobFlag = buildJob.jobKey ? `-j ${buildJob.jobKey} ` : "";
  return [
    "set -e",
    'export PATH="/Users/admin/flutter/bin:/opt/homebrew/bin:/opt/dart-sdk/bin:/opt/flutter/bin:$PATH"',
    `cd ${buildJob.repo}`,
    `act ${eventType} -W .openci/${buildJob.workflowFileName} ${jobFlag}` +
      "-P macos-latest=-self-hosted " +
      "-P macos-14=-self-hosted " +
      "-P macos-15=-self-hosted " +
      "-P ubuntu-latest=-self-hosted " +
      "-e /tmp/openci-event.json " +
      "--env-file /tmp/openci-env " +
      "--secret-file /tmp/openci-secrets",
  ].join("\n");
}

function shortJobId(buildJobId: string): string {
  return buildJobId.length >= 8 ? buildJobId.slice(0, 8) : buildJobId;
}

async function writeFileToContainer(
  name: string,
  remotePath: string,
  content: string,
): Promise<void> {
  const workDir = await mkdtemp(join(tmpdir(), "openci-copy-"));
  const localPath = join(workDir, "file");
  try {
    await writeFile(localPath, content);
    await runSimple(
      "docker",
      ["cp", localPath, `${name}:${remotePath}`],
      `Failed to copy ${remotePath}`,
    );
  } finally {
    await rm(workDir, { recursive: true, force: true });
  }
}

async function runDockerBuild(input: {
  buildJob: BuildJob;
  runId: string;
  envVars: Record<string, string>;
  secretVars: Record<string, string>;
  workerId: string;
}): Promise<void> {
  const { buildJob, runId, envVars, secretVars, workerId } = input;
  const name = `openci-${workerId}-${shortJobId(buildJob.id)}`;
  try {
    await logInfo(buildJob.id, runId, `Creating container ${name} from ${dockerImage}...`);
    await runSimple(
      "docker",
      ["create", "--name", name, dockerImage],
      `Failed to create container ${name}`,
    );
    await runSimple("docker", ["start", name], `Failed to start container ${name}`);

    await writeFileToContainer(name, "/tmp/openci-env", envFileContent(envVars));
    await writeFileToContainer(name, "/tmp/openci-secrets", envFileContent(secretVars));
    await writeFileToContainer(name, "/tmp/openci-event.json", buildEventPayload(buildJob));

    await logInfo(buildJob.id, runId, `Cloning repository ${buildJob.owner}/${buildJob.repo}...`);
    const cloneUrl = `https://x-access-token:${buildJob.installationToken}@${githubHost(buildJob)}/${buildJob.owner}/${buildJob.repo}.git`;
    await runProcess({
      command: "docker",
      args: ["exec", name, "bash", "-c", `git clone --depth 1 --no-checkout ${cloneUrl}`],
      buildJob,
      runId,
      logOutput: true,
    });

    await fetchAndCheckout(buildJob, runId, (command) =>
      runProcess({
        command: "docker",
        args: ["exec", name, "bash", "-c", command],
        buildJob,
        runId,
        logOutput: true,
      }),
    );

    await writeFileToContainer(name, "/tmp/openci-act.sh", actScript(buildJob));
    await runProcess({
      command: "docker",
      args: ["exec", name, "chmod", "+x", "/tmp/openci-act.sh"],
      buildJob,
      runId,
      logOutput: true,
    });
    await runCancellableAct(buildJob, runId, (signal) =>
      runProcess({
        command: "docker",
        args: ["exec", name, "/bin/bash", "-l", "/tmp/openci-act.sh"],
        buildJob,
        runId,
        logOutput: true,
        signal,
      }),
    );
  } finally {
    await runSimple("docker", ["rm", "-f", name], `Failed to remove container ${name}`).catch(
      (error: unknown) =>
        logWarning(buildJob.id, runId, `Error removing container: ${String(error)}`),
    );
  }
}

function lumeSshArgs(vmName: string, remoteCommand: string): string[] {
  return [
    "ssh",
    vmName,
    "--user",
    sshUser,
    "--password",
    sshPassword,
    "--timeout",
    "10",
    "--",
    remoteCommand,
  ];
}

async function writeFileToVm(vmName: string, remotePath: string, content: string): Promise<void> {
  const encoded = Buffer.from(content, "utf8").toString("base64");
  await runSimple(
    "lume",
    lumeSshArgs(vmName, `rm -f ${remotePath} ${remotePath}.b64`),
    `Failed to reset ${remotePath}`,
  );
  for (let i = 0; i < encoded.length; i += 4096) {
    const chunk = encoded.slice(i, i + 4096);
    await runSimple(
      "lume",
      lumeSshArgs(vmName, `printf %s '${chunk}' >> ${remotePath}.b64`),
      `Failed to write ${remotePath}`,
    );
  }
  await runSimple(
    "lume",
    lumeSshArgs(vmName, `base64 -D < ${remotePath}.b64 > ${remotePath} && rm ${remotePath}.b64`),
    `Failed to decode ${remotePath}`,
  );
}

async function waitForVmReady(vmName: string): Promise<void> {
  for (let attempt = 0; attempt < 120; attempt++) {
    try {
      await runSimple("lume", lumeSshArgs(vmName, "echo ready"), "VM not ready");
      return;
    } catch {
      await new Promise((resolve) => setTimeout(resolve, 2_000));
    }
  }
  throw new Error("VM boot timeout: VM did not respond");
}

async function killVmProcessGroup(vmProcess: ChildProcess | undefined): Promise<void> {
  if (!vmProcess?.pid) return;
  try {
    process.kill(-vmProcess.pid, "SIGTERM");
  } catch {
    return;
  }
  await delay(3_000);
  try {
    process.kill(-vmProcess.pid, "SIGKILL");
  } catch {
    // The VM process exited after SIGTERM.
  }
}

async function killLumeRunByName(vmName: string): Promise<void> {
  await runSimple(
    "pkill",
    ["-TERM", "-f", `lume run ${vmName}`],
    `Failed to terminate VM process ${vmName}`,
  ).catch(() => undefined);
  await delay(3_000);
  await runSimple(
    "pkill",
    ["-KILL", "-f", `lume run ${vmName}`],
    `Failed to kill VM process ${vmName}`,
  ).catch(() => undefined);
}

async function setupDirectSsh(vmName: string): Promise<void> {
  try {
    await runSimple("test", ["-f", sshKeyPath], "SSH key not found");
  } catch {
    await runSimple(
      "ssh-keygen",
      ["-t", "ed25519", "-f", sshKeyPath, "-N", "", "-q"],
      "Failed to generate SSH key",
    );
  }
  const publicKey = await runSimple("cat", [`${sshKeyPath}.pub`], "Failed to read SSH public key");
  await runSimple(
    "lume",
    lumeSshArgs(
      vmName,
      `mkdir -p ~/.ssh && printf '%s\\n' '${publicKey.trim()}' >> ~/.ssh/authorized_keys && chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys`,
    ),
    "Failed to install SSH key",
  );
}

async function getVmIp(vmName: string): Promise<string> {
  const ipPattern = /\b(\d{1,3}(?:\.\d{1,3}){3})\b/u;
  for (let attempt = 0; attempt < 15; attempt++) {
    const output = await runSimple(
      "lume",
      lumeSshArgs(vmName, "ipconfig getifaddr en0"),
      "Failed to get VM IP",
    ).catch(() => "");
    const match = ipPattern.exec(output);
    if (match?.[1]) return match[1];
    await new Promise((resolve) => setTimeout(resolve, 3_000));
  }
  throw new Error(`Failed to get VM IP for ${vmName}`);
}

function directSshArgs(vmIp: string, command: string[]): string[] {
  return [
    "-o",
    "StrictHostKeyChecking=no",
    "-o",
    "UserKnownHostsFile=/dev/null",
    "-o",
    "LogLevel=ERROR",
    "-o",
    "RequestTTY=no",
    "-o",
    "ServerAliveInterval=30",
    "-o",
    "ServerAliveCountMax=5",
    "-i",
    sshKeyPath,
    `${sshUser}@${vmIp}`,
    ...command,
  ];
}

async function runMacVmBuild(input: {
  buildJob: BuildJob;
  runId: string;
  envVars: Record<string, string>;
  secretVars: Record<string, string>;
  workerId: string;
}): Promise<void> {
  const { buildJob, runId, envVars, secretVars, workerId } = input;
  const vmName = `openci-vm-${workerId}-${shortJobId(buildJob.id)}`;
  let vmProcess: ChildProcess | undefined;
  try {
    await logInfo(buildJob.id, runId, `Cloning VM ${baseVmName} to ${vmName}...`);
    await runSimple("lume", ["clone", baseVmName, vmName], `Failed to clone VM ${vmName}`);

    vmProcess = spawn("lume", ["run", vmName, "--no-display"], {
      stdio: "ignore",
      detached: true,
    });
    vmProcess.unref();
    await logInfo(buildJob.id, runId, "Waiting for VM to be ready...");
    await waitForVmReady(vmName);
    await setupDirectSsh(vmName);
    const vmIp = await getVmIp(vmName);
    await logInfo(buildJob.id, runId, "VM is ready!");

    await writeFileToVm(vmName, "/tmp/openci-env", envFileContent(envVars));
    await writeFileToVm(vmName, "/tmp/openci-secrets", envFileContent(secretVars));
    await writeFileToVm(vmName, "/tmp/openci-event.json", buildEventPayload(buildJob));

    await logInfo(buildJob.id, runId, `Cloning repository ${buildJob.owner}/${buildJob.repo}...`);
    const cloneUrl = `https://x-access-token:${buildJob.installationToken}@${githubHost(buildJob)}/${buildJob.owner}/${buildJob.repo}.git`;
    await runProcess({
      command: "lume",
      args: lumeSshArgs(vmName, `git clone --depth 1 --no-checkout ${cloneUrl}`),
      buildJob,
      runId,
      logOutput: true,
    });

    await fetchAndCheckout(buildJob, runId, (command) =>
      runProcess({
        command: "lume",
        args: lumeSshArgs(vmName, command),
        buildJob,
        runId,
        logOutput: true,
      }),
    );

    await writeFileToVm(vmName, "/tmp/openci-act.sh", actScript(buildJob));
    await runProcess({
      command: "lume",
      args: lumeSshArgs(vmName, "chmod +x /tmp/openci-act.sh"),
      buildJob,
      runId,
      logOutput: true,
    });
    await runCancellableAct(buildJob, runId, (signal) =>
      runProcess({
        command: "ssh",
        args: directSshArgs(vmIp, ["/bin/zsh", "-l", "/tmp/openci-act.sh"]),
        buildJob,
        runId,
        logOutput: true,
        signal,
      }),
    );
  } finally {
    let stopped = true;
    await runSimple("lume", ["stop", vmName], `Failed to stop VM ${vmName}`).catch(
      (error: unknown) => {
        stopped = false;
        return logWarning(buildJob.id, runId, `Error stopping VM: ${String(error)}`);
      },
    );
    if (!stopped) {
      await logWarning(buildJob.id, runId, `Force-killing VM process for ${vmName}`);
      await killVmProcessGroup(vmProcess);
      await killLumeRunByName(vmName);
    }
    await runSimple("lume", ["delete", vmName, "--force"], `Failed to delete VM ${vmName}`).catch(
      (error: unknown) => logWarning(buildJob.id, runId, `Error deleting VM: ${String(error)}`),
    );
  }
}

async function fetchAndCheckout(
  buildJob: BuildJob,
  runId: string,
  exec: (command: string) => Promise<void>,
): Promise<void> {
  await logInfo(buildJob.id, runId, `Fetching commit ${buildJob.commitSha}...`);
  try {
    await exec(`git -C ${buildJob.repo} fetch --depth 1 origin ${buildJob.commitSha}`);
  } catch (error) {
    if (!buildJob.pullRequestNumber) throw error;
    await logInfo(
      buildJob.id,
      runId,
      `Direct fetch failed, trying PR ref pull/${buildJob.pullRequestNumber}/head...`,
    );
    await exec(
      `git -C ${buildJob.repo} fetch --depth 1 origin pull/${buildJob.pullRequestNumber}/head`,
    );
  }
  await exec(`git -C ${buildJob.repo} checkout ${buildJob.commitSha}`);
  await logInfo(buildJob.id, runId, "Repository cloned successfully");
}

async function runCancellableAct(
  buildJob: BuildJob,
  runId: string,
  run: (signal: AbortSignal) => Promise<void>,
): Promise<void> {
  await logInfo(buildJob.id, runId, "Running workflow with act...");
  const abortController = new AbortController();
  const cancelTimer = setInterval(() => {
    void isJobCancelled(buildJob.id).then((cancelled) => {
      if (cancelled) abortController.abort();
    });
  }, 5_000);
  try {
    await run(abortController.signal);
  } finally {
    clearInterval(cancelTimer);
  }
}

export async function runBuildJob(input: {
  buildJob: BuildJob;
  runId: string;
  envVars: Record<string, string>;
  secretVars: Record<string, string>;
  workerId: string;
}): Promise<void> {
  const { buildJob, runId, envVars, secretVars, workerId } = input;
  if (!buildJob.installationToken) throw new Error("installationToken is missing");
  if (!buildJob.commitSha) throw new Error("commitSha is missing");
  if (!buildJob.workflowFileName) throw new Error("workflowFileName is missing");

  if (process.platform === "linux") {
    await runDockerBuild({ buildJob, runId, envVars, secretVars, workerId });
  } else {
    await runMacVmBuild({ buildJob, runId, envVars, secretVars, workerId });
  }
}
