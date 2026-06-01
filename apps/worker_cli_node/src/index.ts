#!/usr/bin/env node

import { parseConfig } from "./config.js";
import { initFirebase } from "./firestore.js";
import { pollForJobs } from "./worker/worker.js";

async function main(): Promise<void> {
  const config = parseConfig(process.argv.slice(2));
  if (!config) return;

  initFirebase(config.serviceAccountPath, config.projectNumber);
  await pollForJobs(config);
}

main().catch((error: unknown) => {
  console.error(error instanceof Error ? (error.stack ?? error.message) : String(error));
  process.exit(1);
});
