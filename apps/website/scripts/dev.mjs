import { spawn } from "node:child_process";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";
import { dev } from "astro";

const site = fileURLToPath(new URL("../", import.meta.url));
const landing = fileURLToPath(new URL("../../landing_page/", import.meta.url));
const next = createRequire(
  new URL("../../landing_page/package.json", import.meta.url),
);
const content = await dev({
  root: site,
  server: { host: "127.0.0.1", port: 0 },
});
const args = process.argv
  .slice(2)
  .map((arg) => (arg === "--host" ? "--hostname" : arg));
if (!args.some((arg) => ["-p", "--port"].includes(arg)))
  args.push("--port", process.env.PORT || "4321");
const child = spawn(
  process.execPath,
  [next.resolve("next/dist/bin/next"), "dev", ...args],
  {
    cwd: landing,
    stdio: "inherit",
    env: {
      ...process.env,
      OPENCI_CONTENT_ORIGIN: `http://127.0.0.1:${content.address.port}`,
    },
  },
);
for (const signal of ["SIGINT", "SIGTERM"])
  process.once(signal, () => child.kill(signal));
child.once("exit", async (code) => {
  await content.stop();
  process.exitCode = code ?? 0;
});
