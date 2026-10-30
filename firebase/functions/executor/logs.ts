import { randomUUID } from "node:crypto";
import { StringDecoder } from "node:string_decoder";
import type { DataConnect } from "firebase-admin/data-connect";
import * as sdk from "@openci/logs-admin";
import type { Stream } from "./model.js";

/** Holds only a possible secret prefix, preserving live output between frames. */
export class StreamingRedactor {
  private pending = "";
  private readonly values: string[];
  private readonly lookahead: number;
  constructor(values: string[]) {
    this.values = [...new Set(values.filter(Boolean))].sort((a, b) => b.length - a.length);
    this.lookahead = Math.max(1, ...this.values.map((value) => value.length));
    if (this.lookahead > 65536) throw new Error("Secret too large");
  }
  push(value: string, final = false): string {
    this.pending += value;
    let position = 0;
    const output: string[] = [];
    while (position < this.pending.length) {
      const remaining = this.pending.length - position;
      if (
        !final &&
        remaining < this.lookahead &&
        this.values.some(
          (secret) => secret.length > remaining && secret.startsWith(this.pending.slice(position)),
        )
      )
        break;
      const match = this.values.find((secret) => this.pending.startsWith(secret, position));
      if (match) {
        output.push("[REDACTED]");
        position += match.length;
      } else {
        const character = String.fromCodePoint(this.pending.codePointAt(position)!);
        output.push(character);
        position += character.length;
      }
    }
    this.pending = this.pending.slice(position);
    return output.join("");
  }
}

export class ExecutionLogs {
  private sequence = 0n;
  constructor(
    private readonly dc: DataConnect,
    private readonly teamId: string,
    private readonly runId: string,
  ) {}

  async start(stepId: string, name: string, stepOrder: number): Promise<void> {
    const variables = { teamId: this.teamId, runId: this.runId, stepId, name, stepOrder };
    try {
      await sdk.createBuildStep(this.dc, variables);
    } catch {
      const step = (
        await sdk.getBuildStepWriteState(this.dc, {
          teamId: this.teamId,
          runId: this.runId,
          stepId,
        })
      ).data.run?.steps[0];
      if (
        !step ||
        step.name !== name ||
        step.stepOrder !== stepOrder ||
        step.status !== "IN_PROGRESS"
      )
        throw new Error("Step creation failed");
    }
  }
  async finish(stepId: string, status: string, durationMs: number): Promise<void> {
    const variables = {
      teamId: this.teamId,
      runId: this.runId,
      stepId,
      status,
      durationMs: String(Math.max(0, Math.floor(durationMs))),
    };
    try {
      await sdk.updateBuildStep(this.dc, variables);
    } catch {
      const step = (
        await sdk.getBuildStepWriteState(this.dc, {
          teamId: this.teamId,
          runId: this.runId,
          stepId,
        })
      ).data.run?.steps[0];
      if (!step || step.status !== status || step.durationMs !== variables.durationMs)
        throw new Error("Step completion failed");
    }
  }
  async append(stepId: string, stream: Stream, message: string): Promise<void> {
    const variables = {
      teamId: this.teamId,
      runId: this.runId,
      stepId,
      stream,
      message,
      logId: randomUUID(),
      source: stepId === "run_workflow" ? "workflow" : "worker",
      occurredAt: new Date().toISOString(),
    };
    for (let retry = 0; retry < 3; retry++) {
      try {
        await sdk.appendBuildLog(this.dc, {
          ...variables,
          expectedLastSequence: String(this.sequence),
          sequence: String(this.sequence + 1n),
        });
        this.sequence++;
        return;
      } catch {
        const run = (
          await sdk.getBuildLogWriteState(this.dc, {
            teamId: this.teamId,
            runId: this.runId,
            logIds: [variables.logId],
          })
        ).data.run;
        if (!run) throw new Error("Log run missing");
        this.sequence = BigInt(run.lastLogSequence);
        // FSC serializes UUIDs without hyphens; randomUUID uses RFC 4122 form.
        const existing = run.logs.find(
          (log) =>
            log.logId.replaceAll("-", "").toLowerCase() === variables.logId.replaceAll("-", ""),
        );
        if (existing) {
          if (
            existing.message !== message ||
            existing.stepId !== stepId ||
            existing.stream !== stream ||
            existing.source !== variables.source
          )
            throw new Error("Log identity conflict");
          return;
        }
      }
    }
    throw new Error("Log persistence failed");
  }

  output(stepId: string, secrets: string[]) {
    const streams = Object.fromEntries(
      (["stdout", "stderr"] as const).map((stream) => [
        stream,
        { decoder: new StringDecoder("utf8"), redactor: new StreamingRedactor(secrets), text: "" },
      ]),
    ) as Record<Stream, { decoder: StringDecoder; redactor: StreamingRedactor; text: string }>;
    const flushText = async (stream: Stream, final: boolean) => {
      const state = streams[stream];
      // Keep individual records well below FSC's 16 KiB UTF-8 limit.
      while (state.text) {
        const newline = state.text.indexOf("\n");
        if (newline < 0 && Buffer.byteLength(state.text) < 8192 && !final) return;
        let message = "";
        let length = 0;
        for (const character of state.text) {
          const bytes = Buffer.byteLength(character);
          if (length + bytes > 8192) break;
          message += character;
          length += bytes;
          if (character === "\n") break;
        }
        state.text = state.text.slice(message.length);
        await this.append(stepId, stream, message);
      }
    };
    return {
      write: async (stream: Stream, bytes: Buffer) => {
        const state = streams[stream];
        state.text += state.redactor.push(state.decoder.write(bytes));
        await flushText(stream, false);
      },
      flush: async () => {
        for (const stream of ["stdout", "stderr"] as const) {
          const state = streams[stream];
          state.text += state.redactor.push(state.decoder.end(), true);
          await flushText(stream, true);
        }
      },
    };
  }
}
