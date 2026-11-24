export const orchardMachines = {
  "macos-latest": {
    os: "darwin",
    runtime: "tart",
    arch: "arm64",
    slots: "org.cirruslabs.tart-vms",
  },
  "linux-latest": {
    os: "linux",
    runtime: "vetu",
    arch: "amd64",
    slots: "org.openci.vetu-vms",
  },
} as const;

export type WorkerMachine = keyof typeof orchardMachines;

export function isWorkerMachine(value: unknown): value is WorkerMachine {
  return value === "macos-latest" || value === "linux-latest";
}

export function isDispatchEnabled(
  job: { runsOn?: string | null; repositoryId?: string | null; githubBaseUrl?: string | null },
  linuxRepositoryId: string,
): boolean {
  return (
    job.runsOn === "macos-latest" ||
    (job.runsOn === "linux-latest" &&
      !!linuxRepositoryId &&
      job.repositoryId === linuxRepositoryId &&
      job.githubBaseUrl === "https://github.com")
  );
}
