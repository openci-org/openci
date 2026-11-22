import { accessSync, cpSync, readdirSync, statSync } from "node:fs";
import { join } from "node:path";

const content = "dist";
const next = "../landing_page/out";

function filesIn(directory) {
  return readdirSync(directory, { recursive: true }).filter((path) =>
    statSync(join(directory, path)).isFile(),
  );
}

// Locale directories already contain the blog, pricing and docs. Copy files
// individually so a second owner for any actual URL fails the build.
const pages = ["en", "ja", "studio", "_next"].flatMap((directory) =>
  filesIn(join(next, directory)).map((path) => join(directory, path)),
);
const root = readdirSync(next).filter(
  (path) => path === "index.html" || path.endsWith(".txt"),
);
const assets = filesIn("../landing_page/public").filter(
  (path) => path !== "favicon.png",
);
for (const path of [...pages, ...assets, ...root]) {
  cpSync(join(next, path), join(content, path), {
    force: false,
    errorOnExist: true,
  });
}
for (const path of [
  "en",
  "ja",
  "en/pricing",
  "ja/docs",
  "studio",
  "studio/about",
  "ja/releases",
]) {
  accessSync(join(content, path, "index.html"));
}
