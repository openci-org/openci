import * as core from "@actions/core";
import * as fs from "fs";
import * as path from "path";

export function main(): void {
  try {
    const secret = core.getInput("secret", { required: true });
    const filePath = core.getInput("path", { required: true });
    const encoding = core.getInput("encoding") || "base64";

    saveSecret({ secret, filePath, encoding });
  } catch (error) {
    if (error instanceof Error) {
      core.setFailed(error.message);
    } else {
      core.setFailed("An unknown error occurred");
    }
  }
}

export function saveSecret({
  secret,
  filePath,
  encoding,
}: {
  secret: string;
  filePath: string;
  encoding: string;
}): void {
  const dir = path.dirname(filePath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  let buffer: Buffer;
  if (encoding === "base64") {
    buffer = Buffer.from(secret, "base64");
  } else if (encoding === "raw") {
    buffer = Buffer.from(secret, "utf-8");
  } else {
    throw new Error(`Unsupported encoding: '${encoding}' (must be 'base64' or 'raw')`);
  }

  fs.writeFileSync(filePath, buffer);
}
