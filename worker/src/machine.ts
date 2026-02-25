import os from "node:os";

export function getMachineInfo() {
  const cpus = os.cpus();
  const totalMemoryGB = (os.totalmem() / 1024 / 1024 / 1024).toFixed(1);
  const freeMemoryGB = (os.freemem() / 1024 / 1024 / 1024).toFixed(1);
  return {
    hostname: os.hostname(),
    platform: os.platform(),
    arch: os.arch(),
    cpuModel: cpus[0]?.model?.trim() ?? "unknown",
    cpuCores: cpus.length,
    totalMemoryGB,
    freeMemoryGB,
  };
}
