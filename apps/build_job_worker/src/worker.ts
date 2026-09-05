import { NativeConnection, Worker } from "@temporalio/worker";
import * as activities from "./activities";

const taskQueue = "openci-build-job-worker";

async function run(): Promise<void> {
  const address = process.env.TEMPORAL_ADDRESS || "localhost:7233";
  const connection = await NativeConnection.connect({ address });

  try {
    const worker = await Worker.create({
      connection,
      namespace: "default",
      taskQueue,
      workflowsPath: require.resolve("./workflows"),
      activities,
      shutdownGraceTime: "10s",
    });

    console.info("Starting build job worker", { address, taskQueue });
    await worker.run();
  } finally {
    await connection.close();
  }
}

run().catch((error: unknown) => {
  console.error("Build job worker failed", error);
  process.exitCode = 1;
});
