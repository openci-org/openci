import { accessSync, cpSync, readdirSync, rmSync, statSync } from "node:fs";
import { join } from "node:path";

const hosting = "build/hosting";
const archive = "../landing_page/out";
const archivePublic = "../landing_page/public";

rmSync(hosting, { recursive: true, force: true });
cpSync("dist", hosting, { recursive: true });

// The Astro site owns the homepage and favicon. Next owns Studio and the release archive.
const assets = readdirSync(archivePublic, { recursive: true }).filter(
  (path) =>
    path !== "favicon.png" && statSync(join(archivePublic, path)).isFile(),
);
for (const path of ["studio", "ja/releases", "_next", ...assets]) {
  cpSync(join(archive, path), join(hosting, path), {
    recursive: true,
    force: false,
    errorOnExist: true,
  });
}

for (const path of ["studio", "studio/about", "ja/releases"]) {
  accessSync(join(hosting, path, "index.html"));
}
