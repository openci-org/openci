import { request as httpRequest } from "node:http";
import { request as httpsRequest } from "node:https";

export interface VmSize {
  cpu: number;
  memoryMiB: number;
}
export interface VmReservation extends VmSize {
  vmName: string;
}
export interface OrchardSnapshot {
  workers: Record<string, unknown>[];
  vms: Record<string, unknown>[];
}

const cpuResource = "org.cirruslabs.logical-cores";
const memoryResource = "org.cirruslabs.memory-mib";
const vmResource = "org.cirruslabs.tart-vms";

function object(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    throw new Error("Invalid Orchard resource");
  }
  return value as Record<string, unknown>;
}
function positive(value: unknown): number {
  return typeof value === "number" && Number.isSafeInteger(value) && value > 0 ? value : 0;
}
function name(value: unknown): string {
  if (typeof value !== "string" || !value) throw new Error("Missing Orchard resource name");
  return value;
}

interface Resources extends VmSize {
  slots: number;
}

/** Includes existing VMs and reservations whose VM is not visible in Orchard yet. */
export function hasOrchardCapacity(
  snapshot: OrchardSnapshot,
  reservations: VmReservation[],
  requested: VmSize,
  now = Date.now(),
): boolean {
  if (!positive(requested.cpu) || !positive(requested.memoryMiB)) {
    throw new Error("Invalid VM size");
  }
  const workers = new Map<string, Resources>();
  for (const worker of snapshot.workers) {
    if (
      worker.scheduling_paused === true ||
      (worker.runtime ?? "tart") !== "tart" ||
      (worker.arch ?? "arm64") !== "arm64"
    )
      continue;
    const seen = Date.parse(String(worker.last_seen ?? ""));
    if (!Number.isFinite(seen) || seen < now - 180000 || seen > now + 60000) continue;
    const resources = object(worker.resources ?? {});
    const workerName = name(worker.name);
    if (workers.has(workerName)) throw new Error("Duplicate Orchard worker");
    workers.set(workerName, {
      cpu: positive(resources[cpuResource]),
      memoryMiB: positive(resources[memoryResource]),
      slots: positive(resources[vmResource]),
    });
  }
  const pending: Resources[] = [];
  const vmNames = new Set<string>();
  for (const vm of snapshot.vms) {
    const vmName = name(vm.name);
    if (vmNames.has(vmName)) throw new Error("Duplicate Orchard VM");
    vmNames.add(vmName);
    // Assigned VMs on offline/paused/other-runtime workers cannot consume the
    // eligible workers' capacity. Unassigned VMs still compete for their slots.
    if (vm.worker && !workers.has(String(vm.worker))) continue;
    const resources = object(vm.resources ?? {});
    const size: Resources = {
      cpu: Math.max(positive(resources[cpuResource]), positive(vm.assignedCPU), positive(vm.cpu)),
      memoryMiB: Math.max(
        positive(resources[memoryResource]),
        positive(vm.assignedMemory),
        positive(vm.memory),
      ),
      slots: positive(resources[vmResource]) || 1,
    };
    if (!size.cpu || !size.memoryMiB) throw new Error("Unknown Orchard VM resource usage");
    const worker = workers.get(String(vm.worker ?? ""));
    if (worker) {
      worker.cpu -= size.cpu;
      worker.memoryMiB -= size.memoryMiB;
      worker.slots -= size.slots;
    } else pending.push(size);
  }
  for (const reservation of reservations) {
    if (!positive(reservation.cpu) || !positive(reservation.memoryMiB)) {
      throw new Error("Invalid reserved VM size");
    }
    if (!vmNames.has(reservation.vmName)) pending.push({ ...reservation, slots: 1 });
  }
  function place(size: Resources): boolean {
    const candidates = [...workers.values()]
      .filter(
        (worker) =>
          worker.slots >= size.slots &&
          worker.cpu >= size.cpu &&
          worker.memoryMiB >= size.memoryMiB,
      )
      .sort((a, b) => a.memoryMiB - b.memoryMiB || a.cpu - b.cpu);
    const worker = candidates[0];
    if (!worker) return false;
    worker.cpu -= size.cpu;
    worker.memoryMiB -= size.memoryMiB;
    worker.slots -= size.slots;
    return true;
  }
  pending.sort((a, b) => b.memoryMiB - a.memoryMiB || b.cpu - a.cpu);
  return pending.every(place) && place({ ...requested, slots: 1 });
}

export class OrchardCapacityClient {
  private readonly base: URL;
  constructor(
    private readonly options: {
      url: string;
      account: string;
      token: string;
      ca?: string;
      allowLocalHttp?: boolean;
    },
  ) {
    this.base = new URL(options.url);
    const local =
      options.allowLocalHttp &&
      this.base.protocol === "http:" &&
      ["localhost", "127.0.0.1"].includes(this.base.hostname);
    if (
      (!local && this.base.protocol !== "https:") ||
      this.base.username ||
      this.base.password ||
      this.base.search ||
      this.base.hash ||
      !options.account ||
      !options.token
    ) {
      throw new Error("Invalid Orchard configuration");
    }
  }

  async snapshot(): Promise<OrchardSnapshot> {
    const [workers, vms] = await Promise.all([this.read("workers"), this.read("vms")]);
    return { workers, vms };
  }

  private read(resource: "workers" | "vms"): Promise<Record<string, unknown>[]> {
    const url = new URL(`${this.base.href.replace(/\/+$/, "")}/v1/${resource}`);
    return new Promise((resolve, reject) => {
      const request = (url.protocol === "https:" ? httpsRequest : httpRequest)(
        url,
        {
          method: "GET",
          ca: this.options.ca || undefined,
          rejectUnauthorized: true,
          headers: {
            authorization: `Basic ${Buffer.from(`${this.options.account}:${this.options.token}`).toString("base64")}`,
          },
        },
        (response) => {
          const chunks: Buffer[] = [];
          let bytes = 0;
          response.on("data", (chunk: Buffer) => {
            bytes += chunk.length;
            if (bytes > 4 * 1024 * 1024) request.destroy(new Error("Orchard response too large"));
            else chunks.push(chunk);
          });
          response.on("error", reject);
          response.on("end", () => {
            try {
              if (response.statusCode !== 200) throw new Error("Orchard capacity unavailable");
              const value: unknown = JSON.parse(Buffer.concat(chunks).toString("utf8"));
              if (!Array.isArray(value)) throw new Error("Invalid Orchard resource list");
              resolve(value.map(object));
            } catch {
              reject(new Error("Orchard capacity unavailable"));
            }
          });
        },
      );
      // A wall-clock deadline also bounds a peer continuously sending chunks.
      const timer = setTimeout(
        () => request.destroy(new Error("Orchard request timed out")),
        10000,
      );
      request.on("close", () => clearTimeout(timer));
      request.on("error", reject);
      request.end();
    });
  }
}
