import { randomUUID } from "node:crypto";
import { TestWorkflowEnvironment } from "@temporalio/testing";
import { bundleWorkflowCode, Worker } from "@temporalio/worker";
import type { WorkflowBundle } from "@temporalio/worker";
import { afterAll, beforeAll, describe, expect, it, vi } from "vitest";
import type * as activities from "../src/activities";

describe("EchoWorkflow", () => {
  let environment: TestWorkflowEnvironment | undefined;
  let workflowBundle: WorkflowBundle;

  beforeAll(async () => {
    workflowBundle = await bundleWorkflowCode({
      workflowsPath: require.resolve("../src/workflows.ts"),
    });
    environment = await TestWorkflowEnvironment.createLocal({
      server: {
        executable: { type: "cached-download", version: "v1.8.3" },
      },
    });
  });

  afterAll(async () => {
    await environment?.teardown();
  });

  async function execute(EchoActivity: typeof activities.EchoActivity): Promise<string> {
    if (!environment) {
      throw new Error("Test environment has not started");
    }

    const taskQueue = `echo-test-${randomUUID()}`;
    const worker = await Worker.create({
      connection: environment.nativeConnection,
      taskQueue,
      workflowBundle,
      activities: { EchoActivity },
    });

    return await worker.runUntil(
      environment.client.workflow.execute("EchoWorkflow", {
        workflowId: randomUUID(),
        taskQueue,
        args: ["input"],
        workflowExecutionTimeout: "15s",
      }),
    );
  }

  it("returns the Activity result", async () => {
    const EchoActivity = vi
      .fn<typeof activities.EchoActivity>()
      .mockResolvedValue("activity result");

    await expect(execute(EchoActivity)).resolves.toBe("activity result");
    expect(EchoActivity).toHaveBeenCalledExactlyOnceWith("input");
  });

  it("retries a failed Activity and returns its successful result", async () => {
    const EchoActivity = vi
      .fn<typeof activities.EchoActivity>()
      .mockRejectedValueOnce(new Error("temporary failure"))
      .mockResolvedValue("recovered result");

    await expect(execute(EchoActivity)).resolves.toBe("recovered result");
    expect(EchoActivity).toHaveBeenCalledTimes(2);
  });

  it("propagates the Activity error after three attempts", async () => {
    const EchoActivity = vi
      .fn<typeof activities.EchoActivity>()
      .mockRejectedValue(new Error("activity failed"));

    await expect(execute(EchoActivity)).rejects.toMatchObject({
      name: "WorkflowFailedError",
      cause: {
        name: "ActivityFailure",
        cause: { message: "activity failed" },
      },
    });
    expect(EchoActivity).toHaveBeenCalledTimes(3);
  });
});
