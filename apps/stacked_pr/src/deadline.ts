import { performance } from "node:perf_hooks";
import { RetryException } from "./models.js";

/** Stop starting work before Cloud Tasks can retry a timed-out invocation. */
export class Deadline {
  private readonly started = performance.now();
  constructor(private readonly budgetMs: number) {}
  limit(maximumMs: number): number {
    const remaining = this.budgetMs - (performance.now() - this.started);
    if (remaining <= 0) throw new RetryException("Execution deadline reached");
    return Math.max(1, Math.floor(Math.min(remaining, maximumMs)));
  }
}
