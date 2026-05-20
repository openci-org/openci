import * as actionsExec from "@actions/exec";

interface ExecOptions {
  cwd?: string;
  silent?: boolean;
}

export async function exec(command: string, options?: ExecOptions): Promise<void> {
  await actionsExec.exec("bash", ["-c", command], {
    cwd: options?.cwd,
    silent: options?.silent ?? false,
  });
}

export async function execAndCapture(command: string, options?: ExecOptions): Promise<string> {
  let output = "";
  await actionsExec.exec("bash", ["-c", command], {
    cwd: options?.cwd,
    silent: options?.silent ?? true,
    listeners: {
      stdout: (data: Buffer) => {
        output += data.toString();
      },
    },
  });
  return output;
}
