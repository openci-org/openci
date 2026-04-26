#!/usr/bin/env node

import { parseConfig } from "./config.js";
import { initFirebase } from "./dataconnect.js";
import { pollForJobs } from "./worker.js";

async function main(): Promise<void> {
  const config = parseConfig(process.argv.slice(2));
  if (!config) return;

  initFirebase(config.serviceAccountPath);
  await pollForJobs(config);
}

main().catch((error: unknown) => {
  console.error(error instanceof Error ? error.stack ?? error.message : String(error));
  process.exit(1);
});

