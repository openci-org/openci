import { existsSync } from "fs";
import { readFile } from "fs/promises";

import { absolutePath } from "./paths";
import type { Inputs } from "./types";

export async function storageBucket(inputs: Inputs): Promise<string> {
  if (inputs.storageBucket) {
    return inputs.storageBucket;
  }

  const optionsPath = absolutePath(inputs.firebaseOptionsPath, inputs.workingDirectory);
  if (!existsSync(optionsPath)) {
    return "";
  }

  const text = await readFile(optionsPath, "utf8");
  const patterns = [
    /storageBucket\s*:\s*['"]([^'"]+)['"]/,
    /['"]storageBucket['"]\s*:\s*['"]([^'"]+)['"]/,
  ];

  for (const pattern of patterns) {
    const match = text.match(pattern);
    if (match?.[1]) {
      return match[1];
    }
  }

  return "";
}
