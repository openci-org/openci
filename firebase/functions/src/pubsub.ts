import { PubSub } from "@google-cloud/pubsub";
import * as logger from "firebase-functions/logger";

const pubsub = new PubSub();
const BUILD_JOBS_TOPIC = "build-jobs";

export async function publishBuildJobCreated(buildJobId: string): Promise<void> {
  try {
    await pubsub.topic(BUILD_JOBS_TOPIC).publishMessage({
      data: Buffer.from(buildJobId),
    });
    logger.info(`Published build job to Pub/Sub: ${buildJobId}`);
  } catch (error) {
    logger.error(`Failed to publish build job to Pub/Sub: ${buildJobId}`, error);
  }
}
