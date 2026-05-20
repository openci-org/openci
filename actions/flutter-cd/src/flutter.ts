import * as fs from "fs";
import * as path from "path";
import { exec, execAndCapture } from "./helpers";

export type SwiftPackageManagerMode = "inherit" | "enabled" | "disabled";

const flutterIosSigningPattern = String.raw`r'^\s*\d+\).+"(.+Develop(ment|er).+)"$'`;
const patchedFlutterIosSigningPattern = String.raw`r'^\s*\d+\).+"(.+(Develop(ment|er)|Distribution).+)"$'`;
const iosSigningPatternDeclaration =
  /final _securityFindIdentityDeveloperIdentityExtractionPattern = RegExp\(\s*([\s\S]*?)\s*\);/;

interface FlutterVersionInfo {
  flutterRoot?: unknown;
}

export function parseSwiftPackageManagerMode(value: string): SwiftPackageManagerMode {
  const normalized = value.trim().toLowerCase();

  if (normalized === "" || normalized === "inherit" || normalized === "auto") {
    return "inherit";
  }
  if (normalized === "enabled" || normalized === "enable" || normalized === "true") {
    return "enabled";
  }
  if (normalized === "disabled" || normalized === "disable" || normalized === "false") {
    return "disabled";
  }

  throw new Error(
    `Unsupported swift-package-manager: ${value}. Use "inherit", "enabled", or "disabled".`,
  );
}

export async function configureSwiftPackageManager(
  mode: SwiftPackageManagerMode,
  workingDirectory: string,
): Promise<boolean> {
  if (mode === "inherit") {
    console.log("  Swift Package Manager: inherit current Flutter setting");
    return false;
  }

  const configCommand =
    mode === "enabled"
      ? "flutter config --enable-swift-package-manager"
      : "flutter config --no-enable-swift-package-manager";

  console.log(`  Swift Package Manager: ${mode}`);
  await exec(configCommand);
  await exec("flutter pub get", { cwd: workingDirectory });
  return true;
}

export async function patchFlutterIosDistributionSigning(): Promise<boolean> {
  const flutterRoot = await detectFlutterRoot();
  const codeSigningPath = path.join(
    flutterRoot,
    "packages/flutter_tools/lib/src/ios/code_signing.dart",
  );

  if (!fs.existsSync(codeSigningPath)) {
    throw new Error(`Flutter iOS code signing source not found at ${codeSigningPath}`);
  }

  const content = fs.readFileSync(codeSigningPath, "utf8");
  const patternDeclaration = content.match(iosSigningPatternDeclaration);
  if (patternDeclaration?.[0].includes("Distribution")) {
    console.log("  Flutter iOS signing regex already accepts Apple Distribution certificates");
    return false;
  }

  if (!content.includes(flutterIosSigningPattern)) {
    console.log(
      "  Flutter iOS signing regex did not match the known issue #176636 pattern; leaving Flutter unchanged",
    );
    return false;
  }

  const patchedContent = content.replace(
    flutterIosSigningPattern,
    () => patchedFlutterIosSigningPattern,
  );
  if (!patchedContent.includes(patchedFlutterIosSigningPattern)) {
    throw new Error("Failed to patch Flutter iOS signing regex");
  }

  fs.writeFileSync(codeSigningPath, patchedContent);
  removeFlutterToolCache(flutterRoot);

  console.log("  Patched Flutter iOS signing regex for Apple Distribution certificates");
  return true;
}

export function buildNoPubArg(pubGetAlreadyRan: boolean, buildArgs: string): string {
  if (!pubGetAlreadyRan || buildArgs.includes("--no-pub")) {
    return "";
  }
  return "--no-pub";
}

async function detectFlutterRoot(): Promise<string> {
  try {
    const versionOutput = await execAndCapture("flutter --version --machine");
    const versionInfo = JSON.parse(versionOutput) as FlutterVersionInfo;
    if (typeof versionInfo.flutterRoot === "string" && versionInfo.flutterRoot.trim() !== "") {
      return versionInfo.flutterRoot;
    }
  } catch (error) {
    console.log(`  Unable to read flutterRoot from flutter --version --machine: ${error}`);
  }

  const flutterPath = (await execAndCapture("command -v flutter")).trim();
  if (flutterPath === "") {
    throw new Error("Unable to locate Flutter SDK because flutter is not on PATH");
  }

  return path.dirname(path.dirname(fs.realpathSync(flutterPath)));
}

function removeFlutterToolCache(flutterRoot: string): void {
  for (const relativePath of [
    "bin/cache/flutter_tools.snapshot",
    "bin/cache/flutter_tools.stamp",
  ]) {
    const cachePath = path.join(flutterRoot, relativePath);
    fs.rmSync(cachePath, { force: true });
    console.log(`  Removed ${relativePath}`);
  }
}
