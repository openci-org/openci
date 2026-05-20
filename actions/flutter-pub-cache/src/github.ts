import { appendFileSync } from "fs";

export function setOutput(name: string, value: string): void {
  const outputPath = process.env.GITHUB_OUTPUT;
  if (!outputPath) {
    return;
  }
  appendFileSync(outputPath, `${name}=${value}\n`);
}

export function warning(message: string): void {
  console.log(`::warning::${message.replace(/\r?\n/g, "%0A")}`);
}
