import { execFile } from "node:child_process";
import { promisify } from "node:util";
import type { SupabaseWorkerClient } from "./supabase.js";
import type { Build } from "./types.js";

const execFileAsync = promisify(execFile);

const BASE_VM_NAME = "sequoia-base";
const VM_BOOT_TIMEOUT_SECONDS = 60;

interface ExecResult {
  stdout: string;
  stderr: string;
  exitCode: number;
}

async function runCommand(command: string, args: string[]): Promise<ExecResult> {
  try {
    const { stdout, stderr } = await execFileAsync(command, args, {
      maxBuffer: 10 * 1024 * 1024,
    });
    return { stdout, stderr, exitCode: 0 };
  } catch (err: unknown) {
    const e = err as { stdout?: string; stderr?: string; code?: number };
    return {
      stdout: e.stdout ?? "",
      stderr: e.stderr ?? "",
      exitCode: e.code ?? 1,
    };
  }
}

async function tartExec(vmName: string, command: string): Promise<ExecResult> {
  const preamble = [
    "export GIT_TERMINAL_PROMPT=0",
    "export GIT_ASKPASS=''",
    "git config --global --unset-all credential.helper 2>/dev/null; true",
  ].join(" && ");
  return runCommand("tart", ["exec", vmName, "/bin/zsh", "-l", "-c", `${preamble} && ${command}`]);
}

async function tartExecStrict(vmName: string, command: string, label: string): Promise<ExecResult> {
  const result = await tartExec(vmName, command);
  if (result.exitCode !== 0) {
    throw new Error(`${label} failed (exit ${result.exitCode}): ${result.stderr || result.stdout}`);
  }
  return result;
}

async function waitForVmReady(vmName: string, onLog: (msg: string) => void): Promise<void> {
  for (let i = 0; i < VM_BOOT_TIMEOUT_SECONDS; i++) {
    const result = await runCommand("tart", ["exec", vmName, "echo", "ready"]);
    if (result.exitCode === 0) {
      onLog(`VM ready after ${i + 1}s`);
      return;
    }
    if (i > 0 && i % 10 === 0) {
      onLog(`Still waiting for VM... (${i}s)`);
    }
    await new Promise((r) => setTimeout(r, 1000));
  }
  throw new Error("VM boot timeout: Guest Agent did not respond.");
}

export interface BuildRunner {
  vmName: string;
  build: Build;
  workerId: string;
  supabase: SupabaseWorkerClient;
  onLog: (message: string) => void;
}

export async function executeBuild(runner: BuildRunner): Promise<"success" | "failure"> {
  const { build, workerId, supabase, onLog } = runner;
  const vmName = `openci-vm-${workerId}-${build.id.slice(0, 8)}`;
  runner.vmName = vmName;

  const buildRunId = await supabase.createBuildRun(build.id);

  const log = (message: string, level: "info" | "warn" | "error" = "info") => {
    onLog(message);
    if (buildRunId) {
      supabase.insertLog(buildRunId, build.id, message, level).catch(() => {});
    }
  };

  try {
    const { yaml_definition: yamlDefinition } = build;

    if (!yamlDefinition) {
      throw new Error("No workflow YAML found for this build");
    }

    log(`Cloning VM ${BASE_VM_NAME} → ${vmName}`);
    const cloneResult = await runCommand("tart", ["clone", BASE_VM_NAME, vmName]);
    if (cloneResult.exitCode !== 0) {
      throw new Error(`tart clone failed: ${cloneResult.stderr}`);
    }

    log("Starting VM (headless)...");
    execFile("tart", ["run", "--no-graphics", vmName], (err) => {
      if (err) log(`VM process exited: ${err.message}`, "warn");
    });

    log("Waiting for VM to be ready...");
    await waitForVmReady(vmName, log);

    const {
      github_owner: owner,
      github_repo: repo,
      commit_sha: commitSha,
      installation_token: installationToken,
    } = build;

    let cloneUrl: string;
    if (installationToken) {
      cloneUrl = `https://x-access-token:${installationToken}@github.com/${owner}/${repo}.git`;
    } else {
      cloneUrl = `https://github.com/${owner}/${repo}.git`;
    }

    log(`Cloning ${owner}/${repo}...`);
    await tartExecStrict(vmName, `git clone --depth 1 ${cloneUrl}`, "git clone");

    if (commitSha) {
      log(`Checking out ${commitSha.slice(0, 7)}...`);
      await tartExec(
        vmName,
        `cd ${repo} && git fetch --depth 1 origin ${commitSha} && git checkout ${commitSha}`,
      );
    }

    log("Writing workflow YAML...");
    const escapedYaml = yamlDefinition.replace(/'/g, "'\\''");
    await tartExecStrict(
      vmName,
      `mkdir -p ${repo}/.github/workflows && echo '${escapedYaml}' > ${repo}/.github/workflows/openci.yaml`,
      "write yaml",
    );

    log("Installing act...");
    await tartExecStrict(vmName, "which act || brew install act", "act install");

    log("Running workflow with act...");
    const actRun = await tartExec(
      vmName,
      `cd ${repo} && act push -P macos-latest=-self-hosted 2>&1`,
    );

    if (actRun.stdout) log(actRun.stdout);
    if (actRun.stderr) log(actRun.stderr);

    if (actRun.exitCode !== 0) {
      throw new Error(`act failed with exit code ${actRun.exitCode}`);
    }

    log("Build completed successfully!");
    await supabase.updateBuildStatus(build.id, "success");
    if (buildRunId) await supabase.completeBuildRun(buildRunId, "success");
    return "success";
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err);
    log(`Build failed: ${message}`, "error");
    await supabase.updateBuildStatus(build.id, "failure");
    if (buildRunId) await supabase.completeBuildRun(buildRunId, "failure");
    return "failure";
  } finally {
    log("Cleaning up VM...");
    await runCommand("tart", ["stop", vmName]).catch(() => {});
    await runCommand("tart", ["delete", vmName]).catch(() => {});
  }
}

export async function cleanupOrphanedVms(workerId: string): Promise<string[]> {
  const cleaned: string[] = [];
  const result = await runCommand("tart", ["list"]);
  if (result.exitCode !== 0) return cleaned;

  const prefix = `openci-vm-${workerId}-`;
  for (const line of result.stdout.split("\n")) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("Source")) continue;

    const parts = trimmed.split(/\s+/);
    const vmName = parts.find((p) => p.startsWith(prefix));
    if (!vmName) continue;

    const state = parts[parts.length - 1];
    if (state === "running") continue;

    await runCommand("tart", ["delete", vmName]);
    cleaned.push(vmName);
  }
  return cleaned;
}
