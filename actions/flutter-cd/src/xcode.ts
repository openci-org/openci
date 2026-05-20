import * as fs from "fs";
import * as os from "os";
import * as path from "path";
import { exec } from "./helpers";

const COMPILATION_CACHE_SETTINGS = ["COMPILATION_CACHE_ENABLE_CACHING = True", ""];

export function prepareXcodeCompilationCacheXcconfig(tmpDir: string): string {
  const xcconfigPath = path.join(tmpDir, "openci-xcode-compilation-cache.xcconfig");
  fs.writeFileSync(xcconfigPath, COMPILATION_CACHE_SETTINGS.join("\n"));
  return xcconfigPath;
}

export function appendXcodeCompilationCacheSettings(xcconfigPath: string): void {
  fs.appendFileSync(xcconfigPath, COMPILATION_CACHE_SETTINGS.join("\n"));
}

export async function reportXcodeCompilationCache(): Promise<void> {
  const derivedDataDir = path.join(os.homedir(), "Library", "Developer", "Xcode", "DerivedData");
  const cacheDir = path.join(derivedDataDir, "CompilationCache.noindex");

  console.log("  Xcode compilation cache:");
  if (!fs.existsSync(cacheDir)) {
    console.log(`  Not found: ${cacheDir}`);
    return;
  }

  await exec(`du -sh ${shellQuote(cacheDir)} || true`);
  await exec(
    `find ${shellQuote(cacheDir)} -type f | wc -l | awk '{ print "  File count: " $1 }' || true`,
  );

  console.log("  Recent CompilationCacheMetrics:");
  await exec(
    [
      "find",
      shellQuote(derivedDataDir),
      "-path '*/Logs/Build/*.xcactivitylog'",
      "-type f",
      "-mtime -1",
      "-print0",
      "| xargs -0 zgrep -a -h 'CompilationCacheMetrics' 2>/dev/null",
      "| tail -n 20",
      "|| true",
    ].join(" "),
  );
}

function shellQuote(value: string): string {
  return `'${value.replace(/'/g, "'\\''")}'`;
}
