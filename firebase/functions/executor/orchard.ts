import { request as httpRequest } from "node:http";
import { request as httpsRequest } from "node:https";
import { setTimeout as delay } from "node:timers/promises";
import WebSocket from "ws";
import type { Dispatch, Stream } from "./model.js";

export interface OrchardOptions {
  url: string;
  account: string;
  token: string;
  ca?: string;
  allowLocalHttp?: boolean;
  useWorkerMemory?: boolean;
}
type Output = (stream: Stream, data: Buffer) => Promise<void>;
// Orchard's 32 KiB message limit includes the JSON envelope and base64 encoding.
const stdinChunkBytes = 16 * 1024;

function record(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== "object" || Array.isArray(value))
    throw new Error("Invalid Orchard VM");
  return value as Record<string, unknown>;
}

export class OrchardExecutor {
  private readonly base: URL;
  private readonly authorization: string;
  constructor(private readonly options: OrchardOptions) {
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
    )
      throw new Error("Invalid Orchard configuration");
    this.authorization = `Basic ${Buffer.from(`${options.account}:${options.token}`).toString("base64")}`;
  }

  private url(resource: string) {
    return new URL(`${this.base.href.replace(/\/+$/, "")}/v1/${resource}`);
  }

  private async request(
    method: string,
    resource: string,
    body?: unknown,
    signal?: AbortSignal,
  ): Promise<{ status: number; value?: unknown }> {
    signal?.throwIfAborted();
    const url = this.url(resource);
    return new Promise((resolve, reject) => {
      const request = (url.protocol === "https:" ? httpsRequest : httpRequest)(
        url,
        {
          method,
          signal,
          ca: this.options.ca || undefined,
          rejectUnauthorized: true,
          headers: { authorization: this.authorization, "content-type": "application/json" },
        },
        (response) => {
          let bytes = 0;
          const chunks: Buffer[] = [];
          response.on("data", (chunk: Buffer) => {
            bytes += chunk.length;
            if (bytes > 4 * 1024 * 1024) request.destroy(new Error("Orchard response too large"));
            else chunks.push(chunk);
          });
          response.on("error", () => reject(new Error("Orchard request failed")));
          response.on("end", () => {
            try {
              const status = response.statusCode ?? 0;
              // Error bodies can contain the request, including credentials.
              const value: unknown =
                status === 200 && bytes
                  ? JSON.parse(Buffer.concat(chunks).toString("utf8"))
                  : undefined;
              resolve({ status, value });
            } catch {
              reject(new Error("Invalid Orchard response"));
            }
          });
        },
      );
      const timer = setTimeout(
        () => request.destroy(new Error("Orchard request timed out")),
        10000,
      );
      request.on("close", () => clearTimeout(timer));
      request.on("error", () => reject(new Error("Orchard request failed")));
      request.end(body === undefined ? undefined : JSON.stringify(body));
    });
  }

  async create(dispatch: Dispatch, signal: AbortSignal): Promise<void> {
    if (this.options.useWorkerMemory) await this.checkWorkerMemory(dispatch.memoryMiB, signal);
    let status: number | undefined;
    try {
      status = (
        await this.request(
          "POST",
          "vms",
          {
            name: dispatch.vmName,
            image: dispatch.image,
            headless: true,
            os: "darwin",
            cpu: dispatch.cpu,
            memory: this.options.useWorkerMemory ? 0 : dispatch.memoryMiB,
            resources: {
              "org.cirruslabs.logical-cores": dispatch.cpu,
              "org.cirruslabs.memory-mib": dispatch.memoryMiB,
              "org.cirruslabs.tart-vms": 1,
            },
          },
          signal,
        )
      ).status;
    } catch {
      /* Never blindly replay a potentially committed create. */
    }
    signal.throwIfAborted();
    const vm = await this.request(
      "GET",
      `vms/${encodeURIComponent(dispatch.vmName)}`,
      undefined,
      signal,
    );
    if (
      (status !== undefined && ![200, 201, 409].includes(status)) ||
      vm.status !== 200 ||
      record(vm.value).name !== dispatch.vmName ||
      record(vm.value).image !== dispatch.image
    )
      throw new Error("VM creation could not be confirmed");
  }

  private async checkWorkerMemory(minimumMiB: number, signal: AbortSignal): Promise<void> {
    const [workers, vms] = await Promise.all([
      this.request("GET", "workers", undefined, signal),
      this.request("GET", "vms", undefined, signal),
    ]);
    if (
      workers.status !== 200 ||
      vms.status !== 200 ||
      !Array.isArray(workers.value) ||
      !Array.isArray(vms.value)
    )
      throw new Error("Worker memory configuration unavailable");
    const defaults = new Map<string, number>();
    for (const value of workers.value) {
      const worker = record(value);
      if (
        worker.scheduling_paused === true ||
        (worker.runtime ?? "tart") !== "tart" ||
        (worker.arch ?? "arm64") !== "arm64"
      )
        continue;
      const seen = Date.parse(String(worker.last_seen ?? ""));
      if (!Number.isFinite(seen) || seen < Date.now() - 180000 || seen > Date.now() + 60000)
        continue;
      const resources = record(worker.resources);
      const memory = worker.defaultMemory;
      const slots = resources["org.cirruslabs.tart-vms"];
      const total = resources["org.cirruslabs.memory-mib"];
      if (
        typeof memory !== "number" ||
        !Number.isSafeInteger(memory) ||
        memory < minimumMiB ||
        typeof slots !== "number" ||
        !Number.isSafeInteger(slots) ||
        slots < 1 ||
        typeof total !== "number" ||
        !Number.isSafeInteger(total) ||
        memory * slots > total ||
        typeof worker.name !== "string"
      )
        throw new Error("Unsafe worker memory configuration");
      defaults.set(worker.name, memory);
    }
    if (!defaults.size) throw new Error("Worker memory configuration unavailable");
    for (const value of vms.value) {
      const vm = record(value);
      const memory = Math.max(Number(vm.memory ?? 0), Number(vm.assignedMemory ?? 0));
      const limit = vm.worker ? defaults.get(String(vm.worker)) : Math.min(...defaults.values());
      // Slot partitioning is safe only while all VMs fit their worker's partition.
      // Reject mixed, larger manual VMs before requesting another default-sized VM.
      if (limit !== undefined && (!Number.isSafeInteger(memory) || memory < 0 || memory > limit))
        throw new Error("VM exceeds worker memory partition");
    }
  }

  async ready(vmName: string, signal: AbortSignal): Promise<void> {
    const deadline = Date.now() + 180000;
    while (Date.now() < deadline) {
      signal.throwIfAborted();
      const vm = await this.request("GET", `vms/${encodeURIComponent(vmName)}`, undefined, signal);
      if (vm.status !== 200 || record(vm.value).status === "failed")
        throw new Error("VM startup failed");
      try {
        // This probe alone is safe to repeat after an uncertain connection.
        const probeSignal = AbortSignal.any([signal, AbortSignal.timeout(5000)]);
        if ((await this.exec(vmName, "true\n", async () => {}, probeSignal)) === 0) return;
      } catch {
        signal.throwIfAborted();
      }
      await delay(2000, undefined, { signal });
    }
    throw new Error("VM readiness timed out");
  }

  async remove(vmName: string): Promise<void> {
    const resource = `vms/${encodeURIComponent(vmName)}`;
    const result = await this.request("DELETE", resource);
    if (![200, 204, 404].includes(result.status)) throw new Error("VM deletion failed");
    if ((await this.request("GET", resource)).status !== 404)
      throw new Error("VM deletion is not yet confirmed");
  }

  async vmNames(): Promise<string[]> {
    const response = await this.request("GET", "vms");
    if (response.status !== 200 || !Array.isArray(response.value))
      throw new Error("VM inventory unavailable");
    return response.value.map((vm: unknown) => {
      const name = record(vm).name;
      if (typeof name !== "string") throw new Error("Invalid VM name");
      return name;
    });
  }

  exec(vmName: string, script: string, output: Output, signal: AbortSignal): Promise<number> {
    signal.throwIfAborted();
    if (Buffer.byteLength(script) > 1024 * 1024) throw new Error("Command input too large");
    const url = this.url(`vms/${encodeURIComponent(vmName)}/exec`);
    url.protocol = url.protocol === "https:" ? "wss:" : "ws:";
    url.searchParams.set("command", "/bin/bash -s");
    url.searchParams.set("interactive", "true");
    return new Promise((resolve, reject) => {
      const ws = new WebSocket(url, {
        headers: { authorization: this.authorization },
        ca: this.options.ca || undefined,
        rejectUnauthorized: true,
        handshakeTimeout: 10000,
        maxPayload: 1024 * 1024,
        followRedirects: false,
      });
      let settled = false;
      let exit: number | undefined;
      let queued = 0;
      let pending = Promise.resolve();
      const finish = (error?: Error) => {
        if (settled) return;
        settled = true;
        signal.removeEventListener("abort", abort);
        ws.terminate();
        // Drain accepted output before returning: cleanup/flush must not race
        // an in-flight log write after a disconnect or cancellation.
        void pending.then(
          () => {
            if (error || exit === undefined)
              reject(error ?? new Error("Command ended without exit status"));
            else resolve(exit);
          },
          () => reject(new Error("Log persistence failed")),
        );
      };
      const abort = () => finish(new Error("Command interrupted"));
      signal.addEventListener("abort", abort, { once: true });
      if (signal.aborted) {
        abort();
        return;
      }
      ws.on("open", () => {
        const bytes = Buffer.from(script);
        for (let offset = 0; offset < bytes.length; offset += stdinChunkBytes) {
          const chunk = bytes.subarray(offset, offset + stdinChunkBytes);
          ws.send(JSON.stringify({ type: "stdin", data: chunk.toString("base64") }));
        }
        ws.send(JSON.stringify({ type: "stdin", data: "" }));
      });
      ws.on("error", () => finish(new Error("Command connection failed")));
      ws.on("unexpected-response", (_request, response) => {
        response.resume();
        finish(new Error("Command connection refused"));
      });
      ws.on("message", (raw) => {
        if (settled) return;
        try {
          const frame = JSON.parse(raw.toString());
          if (
            frame.type === "exit" &&
            Number.isSafeInteger(frame.exit?.code) &&
            exit === undefined
          ) {
            exit = frame.exit.code;
            finish();
          } else if (
            (frame.type === "stdout" || frame.type === "stderr") &&
            typeof frame.data === "string" &&
            exit === undefined &&
            /^[A-Za-z0-9+/]*={0,2}$/.test(frame.data)
          ) {
            const data = Buffer.from(frame.data, "base64");
            queued += data.length;
            if (queued > 4 * 1024 * 1024) throw new Error();
            ws.pause();
            pending = pending.then(async () => {
              await output(frame.type, data);
              queued -= data.length;
              if (!settled && queued === 0) ws.resume();
            });
            void pending.catch(() => finish(new Error("Log persistence failed")));
          } else throw new Error();
        } catch {
          finish(new Error("Invalid command response"));
        }
      });
      ws.on("close", () => finish());
    });
  }
}
