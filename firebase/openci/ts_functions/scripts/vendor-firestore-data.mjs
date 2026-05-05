import { cpSync, mkdirSync, rmSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const functionsDir = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const repoRoot = resolve(functionsDir, "../../..");
const source = resolve(repoRoot, "packages/firestore_data");
const destination = resolve(functionsDir, ".firebase-local-packages/firestore_data");

rmSync(destination, { force: true, recursive: true });
mkdirSync(dirname(destination), { recursive: true });
cpSync(source, destination, {
  recursive: true,
  filter: (path) => !path.includes("node_modules"),
});
