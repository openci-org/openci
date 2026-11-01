import { cp, mkdir, readFile, rm, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const project = process.argv[2];
if (!project || !/^[a-z][a-z0-9-]{4,28}[a-z0-9]$/.test(project)) {
  throw new Error("Usage: node infra/deploy/prepare-core.mjs PROJECT_ID");
}
const firebase = path.join(root, "firebase");
const configPath = path.join(firebase, `firebase.${project}.local.json`);
const config = JSON.parse(await readFile(configPath, "utf8"));
if (config.hosting.site !== project) throw new Error("Unexpected deployment project");
const target = path.join(firebase, ".deploy", project, "functions");
await readFile(path.join(firebase, "lib/functions/core.js")); // Build first.
const environment = await readFile(path.join(firebase, `.env.${project}`), "utf8");
if (!/^OPENCI_SELF_HOSTED=(?:true|"true"|'true')$/m.test(environment)) {
  throw new Error(
    "Core bootstrap requires OPENCI_SELF_HOSTED=true; use the full entry point for cloud billing",
  );
}
await rm(target, { recursive: true, force: true });
await mkdir(target, { recursive: true });
await cp(path.join(firebase, "lib"), path.join(target, "lib"), { recursive: true });
await cp(path.join(firebase, "generated"), path.join(target, "generated"), { recursive: true });
await cp(path.join(firebase, `.env.${project}`), path.join(target, `.env.${project}`));
const pkg = JSON.parse(await readFile(path.join(firebase, "package.json"), "utf8"));
pkg.main = "lib/functions/core.js";
pkg.scripts = {};
delete pkg.devDependencies;
await writeFile(path.join(target, "package.json"), JSON.stringify(pkg, null, 2) + "\n");
config.functions = [
  {
    source: `.deploy/${project}/functions`,
    codebase: "openci",
    runtime: "nodejs22",
    ignore: ["node_modules", ".env*", "*.log"],
  },
];
await writeFile(
  path.join(firebase, `firebase.${project}.core.local.json`),
  JSON.stringify(config, null, 2) + "\n",
);
console.log(`Core-only package prepared for ${project}. Use only for initial bootstrap.`);
