export const orchardWorkerNameLabel = "org.cirruslabs.orchard.worker-name";

const linuxPlatform = {
  os: "linux",
  runtime: "vetu",
  arch: "amd64",
  slots: "org.openci.vetu-vms",
} as const;
const linuxSmall = {
  ...linuxPlatform,
  vm: { cpu: 1, memoryMiB: 2048, image: "base-linux" },
} as const;

export const orchardMachines = {
  "macos-latest": {
    os: "darwin",
    runtime: "tart",
    arch: "arm64",
    slots: "org.cirruslabs.tart-vms",
  },
  "linux-small": linuxSmall,
  "linux-medium": {
    ...linuxPlatform,
    vm: { cpu: 2, memoryMiB: 4096, image: "base-linux" },
  },
  "linux-large": {
    ...linuxPlatform,
    vm: { cpu: 4, memoryMiB: 8192, image: "base-linux" },
  },
  // Old jobs retain their stored machine when retried.
  "linux-latest": linuxSmall,
} as const;

export type WorkerMachine = keyof typeof orchardMachines;

export function isWorkerMachine(value: unknown): value is WorkerMachine {
  return typeof value === "string" && Object.hasOwn(orchardMachines, value);
}

export function isLinuxMachine(value: unknown): boolean {
  return isWorkerMachine(value) && orchardMachines[value].os === "linux";
}

export function isDispatchEnabled(
  job: { runsOn?: string | null; repositoryId?: string | null; githubBaseUrl?: string | null },
  linuxRepositoryId: string,
): boolean {
  return (
    job.runsOn === "macos-latest" ||
    (isLinuxMachine(job.runsOn) &&
      !!linuxRepositoryId &&
      job.repositoryId === linuxRepositoryId &&
      job.githubBaseUrl === "https://github.com")
  );
}
