import { chmod, readFile } from "node:fs/promises";

import { build } from "esbuild";

const packageJson = JSON.parse(await readFile("package.json", "utf8"));

await build({
  bundle: true,
  define: {
    __PACKAGE_VERSION__: JSON.stringify(packageJson.version),
  },
  entryPoints: ["src/index.ts"],
  external: [
    "@google-cloud/secret-manager",
    "@google-cloud/secret-manager/*",
    "@sentry/node",
    "@sentry/node/*",
    "firebase-admin",
    "firebase-admin/*",
    "google-auth-library",
    "google-auth-library/*",
  ],
  format: "cjs",
  outfile: "dist/index.cjs",
  platform: "node",
  sourcemap: true,
  target: "node22",
});

await chmod("dist/index.cjs", 0o755);
