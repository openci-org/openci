import * as core from "@actions/core";
import AdmZip from "adm-zip";
import * as fs from "fs";
import * as os from "os";
import * as path from "path";
import * as plist from "plist";
import {
  addBuildToBetaGroup,
  createProvisioningProfile,
  generateAscJwt,
  getAppIdByBundleId,
  getBetaGroupIdByName,
  getOrCreateCertificate,
  listEnabledDeviceIds,
  pollBuildProcessing,
  preflightCheck,
  type ProfileResult,
} from "./asc";
import {
  buildNoPubArg,
  configureSwiftPackageManager,
  parseSwiftPackageManagerMode,
  patchFlutterIosDistributionSigning,
} from "./flutter";
import { exec, execAndCapture } from "./helpers";

const KEYCHAIN_NAME = "openci-build.keychain";
const KEYCHAIN_PASSWORD = "openci_temp_password";
const APPLE_WWDR_CERTIFICATE_URLS = [
  "https://www.apple.com/certificateauthority/AppleWWDRCAG2.cer",
  "https://www.apple.com/certificateauthority/AppleWWDRCAG3.cer",
  "https://www.apple.com/certificateauthority/AppleWWDRCAG4.cer",
  "https://www.apple.com/certificateauthority/AppleWWDRCAG5.cer",
  "https://www.apple.com/certificateauthority/AppleWWDRCAG6.cer",
];
type IosDistributionMethod = "app-store" | "ad-hoc";

function parseDistributionMethod(value: string): IosDistributionMethod {
  if (value === "app-store" || value === "ad-hoc") {
    return value;
  }
  throw new Error(`Unsupported iOS distribution-method: ${value}. Use "app-store" or "ad-hoc".`);
}

function parseBooleanInput(inputName: string, value: string, defaultValue: boolean): boolean {
  const normalized = value.trim().toLowerCase();
  if (normalized === "") {
    return defaultValue;
  }
  if (["true", "1", "yes", "on"].includes(normalized)) {
    return true;
  }
  if (["false", "0", "no", "off"].includes(normalized)) {
    return false;
  }
  throw new Error(`Unsupported ${inputName}: ${value}. Use "true" or "false".`);
}

export async function buildAndSignIos(): Promise<void> {
  const workingDirectory = core.getInput("working-directory") || ".";
  const buildArgs = core.getInput("build-args") || "";
  const swiftPackageManagerMode = parseSwiftPackageManagerMode(
    core.getInput("swift-package-manager") || "inherit",
  );
  const patchFlutterDistributionSigning = parseBooleanInput(
    "patch-flutter-ios-distribution-signing",
    core.getInput("patch-flutter-ios-distribution-signing") || "",
    true,
  );
  const scheme = core.getInput("scheme") || "Runner";
  const certPrivateKey = core
    .getInput("certificate-private-key", { required: true })
    .replace(/\\n/g, "\n");
  const ascKeyId = core.getInput("asc-key-id", { required: true });
  const ascIssuerId = core.getInput("asc-issuer-id", { required: true });
  const ascPrivateKey = core.getInput("asc-private-key", { required: true }).replace(/\\n/g, "\n");
  const buildNumberInput = core.getInput("build-number") || "";
  const distributionMethod = parseDistributionMethod(
    core.getInput("distribution-method") || "app-store",
  );
  const uploadToAppStoreConnectInput = core.getInput("upload-to-app-store-connect") || "";
  const uploadToAppStoreConnect = uploadToAppStoreConnectInput
    ? uploadToAppStoreConnectInput === "true"
    : distributionMethod === "app-store";
  const sentryAuthToken = core.getInput("sentry-auth-token") || "";
  const shorebirdEnabled = parseBooleanInput("shorebird", core.getInput("shorebird") || "", false);
  const shorebirdToken = core.getInput("shorebird-token") || "";
  const flutterVersionInput = core.getInput("flutter-version") || "";
  const testflightBetaGroupNamesInput = core.getInput("testflight-beta-group-names") || "";
  const testflightMaxWaitMinutesInput = core.getInput("testflight-max-wait-minutes") || "20";
  const testflightMaxWaitMinutes = parseInt(testflightMaxWaitMinutesInput, 10);

  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), "openci-ios-"));

  try {
    console.log("🚀 OpenCI iOS Sign & Build");
    console.log(`   Working directory: ${workingDirectory}`);
    console.log(`   Scheme: ${scheme}`);
    console.log(`   Distribution: ${distributionMethod}`);
    console.log(`   Swift Package Manager: ${swiftPackageManagerMode}`);
    console.log(
      `   Patch Flutter iOS Distribution signing: ${patchFlutterDistributionSigning ? "enabled" : "disabled"}`,
    );
    console.log(`   Shorebird release: ${shorebirdEnabled ? "enabled" : "disabled"}`);
    console.log("");

    // ── Step 1: Configure Flutter dependency manager ────────
    core.startGroup("Step 1: Configuring Flutter dependency manager");
    const pubGetAlreadyRan = await configureSwiftPackageManager(
      swiftPackageManagerMode,
      workingDirectory,
    );
    core.endGroup();

    const flavor = parseFlavor(buildArgs);
    const { bundleId, teamId: appleTeamId } = parsePbxproj(workingDirectory, flavor);

    // ── Step 2: Generate ASC JWT ────────────────────────────
    core.startGroup("Step 2: Generating App Store Connect JWT");
    const ascKeyPath = path.join(tmpDir, "AuthKey.p8");
    fs.writeFileSync(ascKeyPath, ascPrivateKey);
    const jwt = await generateAscJwt(ascKeyId, ascIssuerId, ascKeyPath);
    console.log("  ✅ JWT generated");
    core.endGroup();

    // ── Step 3: Preflight check ─────────────────────────────
    core.startGroup("Step 3: Preflight version check");
    const parsed = parseVersion(workingDirectory);
    const version = parsed.version;
    const buildNumber = buildNumberInput || parsed.buildNumber;
    console.log(`   Version: ${version}+${buildNumber}`);
    if (uploadToAppStoreConnect) {
      await preflightCheck(jwt, bundleId, version, buildNumber);
    } else {
      console.log("  Skipping App Store Connect upload preflight check");
    }
    core.endGroup();

    // ── Step 4: Get or create distribution certificate ──────
    core.startGroup("Step 4: Setting up distribution certificate");
    const certKeyPath = path.join(tmpDir, "cert_key.pem");
    fs.writeFileSync(certKeyPath, certPrivateKey);
    const cert = await getOrCreateCertificate(jwt, certKeyPath, tmpDir);
    console.log(`  Certificate ID: ${cert.certificateId}`);
    core.endGroup();

    // ── Step 5: Create provisioning profile ─────────────────
    core.startGroup("Step 5: Creating provisioning profile");
    const profileType = distributionMethod === "app-store" ? "IOS_APP_STORE" : "IOS_APP_ADHOC";
    const deviceIds = distributionMethod === "ad-hoc" ? await listEnabledDeviceIds(jwt) : [];
    const profile = await createProvisioningProfile(
      jwt,
      cert.certificateId,
      bundleId,
      profileType,
      deviceIds,
    );
    console.log(`  ✅ Profile ${profile.reused ? "reused" : "created"}`);
    console.log(`     Name: ${profile.name}`);
    console.log(`     UUID: ${profile.uuid}`);
    core.endGroup();

    // ── Step 6: Setup keychain ──────────────────────────────
    core.startGroup("Step 6: Setting up temporary keychain");
    await setupKeychain();
    console.log("  ✅ Keychain created");
    core.endGroup();

    // ── Step 7: Import certificate ──────────────────────────
    core.startGroup("Step 7: Importing certificate");
    await importAppleWwdrCertificates(tmpDir);
    await importCertificate(cert.p12Base64, cert.password, tmpDir);
    console.log("  ✅ Certificate imported");
    core.endGroup();

    // ── Step 8: Patch Flutter iOS signing fallback ──────────
    core.startGroup("Step 8: Patching Flutter iOS distribution signing");
    if (patchFlutterDistributionSigning) {
      await patchFlutterIosDistributionSigning();
    } else {
      console.log("  Skipping Flutter iOS Distribution signing patch");
    }
    await assertAppleDistributionIdentityAvailable();
    core.endGroup();

    // ── Step 9: Install provisioning profile ────────────────
    core.startGroup("Step 9: Installing provisioning profile");
    await installProvisioningProfile(profile, bundleId);
    console.log(`  ✅ Profile installed (UUID: ${profile.uuid})`);
    core.endGroup();

    // ── Step 10: Edit xcodeproj ─────────────────────────────
    core.startGroup("Step 10: Configuring Xcode project for manual signing");
    editXcodeProject(workingDirectory, bundleId, appleTeamId, profile);
    console.log("  ✅ Xcode project updated for manual signing");
    core.endGroup();

    // ── Step 11: Generate ExportOptions.plist ───────────────
    core.startGroup("Step 11: Generating ExportOptions.plist");
    const exportOptionsPath = path.resolve(workingDirectory, "ExportOptions.plist");
    generateExportOptions(
      exportOptionsPath,
      appleTeamId,
      bundleId,
      profile.name,
      distributionMethod,
    );
    console.log("  ✅ ExportOptions.plist generated");
    core.endGroup();

    // ── Step 11.5: Setup Shorebird (Optional) ───────────────
    if (shorebirdEnabled) {
      core.startGroup("Step 11.5: Setting up Shorebird");
      if (shorebirdToken) {
        process.env.SHOREBIRD_TOKEN = shorebirdToken;
        console.log("  ✅ SHOREBIRD_TOKEN environment variable set");
      }
      try {
        await exec("which shorebird", { silent: true });
        console.log("  ✅ Shorebird CLI is already installed");
      } catch {
        console.log("  ⏳ Shorebird CLI not found. Installing...");
        await exec(
          "curl --proto '=https' --tlsv1.2 https://raw.githubusercontent.com/shorebirdtech/install/main/install.sh -sSf | bash",
        );
        const shorebirdBinPath = path.join(os.homedir(), ".shorebird", "bin");
        core.addPath(shorebirdBinPath);
        process.env.PATH = `${shorebirdBinPath}${path.delimiter}${process.env.PATH}`;
        console.log("  ✅ Shorebird CLI installed and added to PATH");
      }
      core.endGroup();
    }

    // ── Step 12: Flutter build IPA ──────────────────────────
    core.startGroup(
      shorebirdEnabled ? "Step 12: Building IPA with Shorebird" : "Step 12: Building IPA",
    );
    console.log("  ⏳ This may take several minutes...");
    const buildNumberArg = buildNumberInput ? `--build-number=${buildNumber}` : "";
    const noPubArg = buildNoPubArg(pubGetAlreadyRan, buildArgs);
    const privateKeysDir = path.join(os.homedir(), "private_keys");
    fs.mkdirSync(privateKeysDir, { recursive: true });
    const apiKeyDest = path.join(privateKeysDir, `AuthKey_${ascKeyId}.p8`);
    fs.copyFileSync(ascKeyPath, apiKeyDest);

    if (shorebirdEnabled) {
      let flutterVersion = flutterVersionInput;
      if (!flutterVersion) {
        flutterVersion = (await detectFlutterVersion()) || "";
        if (flutterVersion) {
          console.log(
            `  🐦 Shorebird release: auto-detected Flutter version ${flutterVersion} from host`,
          );
        }
      } else {
        console.log(`  🐦 Shorebird release: using Flutter version ${flutterVersion} from input`);
      }
      const versionArg = flutterVersion ? `--flutter-version=${flutterVersion}` : "";
      await exec(
        `shorebird release ios --export-options-plist="${exportOptionsPath}" ${versionArg} ${buildNumberArg} ${buildArgs}`.trim(),
        { cwd: workingDirectory },
      );
    } else {
      await exec(
        `flutter build ipa ${noPubArg} --release --export-options-plist="${exportOptionsPath}" ${buildNumberArg} ${buildArgs}`.trim(),
        { cwd: workingDirectory },
      );
    }

    // Verify IPA was actually created
    const ipaDir = path.join(workingDirectory, "build", "ios", "ipa");
    const ipaFiles = fs.existsSync(ipaDir)
      ? fs.readdirSync(ipaDir).filter((f) => f.endsWith(".ipa"))
      : [];
    if (ipaFiles.length === 0) {
      throw new Error("IPA file was not created. The export step may have failed.");
    }
    console.log("  ✅ IPA built and exported");

    if (sentryAuthToken) {
      console.log("  Uploading debug symbols to Sentry...");
      try {
        process.env.SENTRY_AUTH_TOKEN = sentryAuthToken;
        await exec("dart run sentry_dart_plugin", { cwd: workingDirectory });
        console.log("  ✅ Sentry upload complete");
      } catch (error) {
        console.log(`  ⚠️ Sentry upload failed: ${error}`);
      }
    }

    core.endGroup();

    const ipaPath = path.resolve(ipaDir, ipaFiles[0]);
    core.setOutput("ipa-path", ipaPath);
    core.setOutput("artifact-directory", path.resolve(ipaDir));
    core.setOutput("distribution-method", distributionMethod);

    if (uploadToAppStoreConnect) {
      // ── Step 13: Upload to App Store Connect ─────────────────
      core.startGroup("Step 13: Uploading to App Store Connect");
      console.log(`  ⏳ Uploading ${ipaFiles[0]}...`);
      const uploadOutput = await execAndCapture(
        `xcrun altool --upload-app --type ios -f "${ipaPath}" --apiKey "${ascKeyId}" --apiIssuer "${ascIssuerId}" 2>&1`,
      );
      if (uploadOutput.includes("ERROR")) {
        throw new Error(`Upload to App Store Connect failed:\n${uploadOutput.trim()}`);
      }
      console.log("  ✅ IPA uploaded to App Store Connect");
      core.endGroup();

      // ── Step 13.5: Distribute to TestFlight Beta Groups ─────
      if (testflightBetaGroupNamesInput.trim()) {
        core.startGroup("Step 13.5: Distributing to TestFlight Beta Groups");
        if (Number.isNaN(testflightMaxWaitMinutes) || testflightMaxWaitMinutes <= 0) {
          console.log(
            "  ⚠️ Distribution was requested, but testflight-max-wait-minutes is 0. Skipping automatic distribution.",
          );
        } else {
          try {
            const groupNames = testflightBetaGroupNamesInput
              .split(",")
              .map((n) => n.trim())
              .filter(Boolean);

            console.log(`  Target beta groups: ${groupNames.join(", ")}`);
            const appId = await getAppIdByBundleId(jwt, bundleId);

            // Wait for Apple to process the build
            const buildId = await pollBuildProcessing(
              jwt,
              appId,
              version,
              buildNumber,
              testflightMaxWaitMinutes,
            );

            // Add the build to each beta group
            for (const groupName of groupNames) {
              console.log(`  Distributing build to group: ${groupName}...`);
              try {
                const groupId = await getBetaGroupIdByName(jwt, appId, groupName);
                await addBuildToBetaGroup(jwt, buildId, groupId);
                console.log(`  ✅ Successfully distributed to ${groupName}`);
              } catch (err) {
                console.log(`  ❌ Failed to distribute to ${groupName}: ${String(err)}`);
                throw err;
              }
            }
          } catch (e) {
            throw new Error(`TestFlight Beta distribution failed: ${String(e)}`);
          }
        }
        core.endGroup();
      }
    } else {
      console.log("  Skipping App Store Connect upload");
    }

    // ── Cleanup ─────────────────────────────────────────────
    core.startGroup("Cleanup");
    await cleanupKeychain();
    fs.rmSync(apiKeyDest, { force: true });
    console.log("  ✅ Temporary keychain and API key removed");
    core.endGroup();

    // ── OTA Distribution ────────────────────────────────────
    await handleOtaDistribution(ipaPath);

    console.log("");
    console.log("🎉 iOS Sign & Build complete!");
    console.log(`   IPA: ${ipaPath}`);
  } finally {
    fs.rmSync(tmpDir, { recursive: true, force: true });
  }
}

// ══════════════════════════════════════════════════════════════
// Keychain
// ══════════════════════════════════════════════════════════════

async function setupKeychain(): Promise<void> {
  await exec(`security delete-keychain ${shellQuote(KEYCHAIN_NAME)}`, { silent: true }).catch(
    () => {},
  );
  await exec(
    `security create-keychain -p ${shellQuote(KEYCHAIN_PASSWORD)} ${shellQuote(KEYCHAIN_NAME)}`,
  );
  await exec(
    `security unlock-keychain -p ${shellQuote(KEYCHAIN_PASSWORD)} ${shellQuote(KEYCHAIN_NAME)}`,
  );
  await exec(`security set-keychain-settings -t 3600 -u ${shellQuote(KEYCHAIN_NAME)}`);
  await exec(`security list-keychains -d user -s ${shellQuote(keychainPath())} login.keychain-db`);
  await exec(`security default-keychain -s ${shellQuote(keychainPath())}`);
}

async function importAppleWwdrCertificates(tmpDir: string): Promise<void> {
  const certDir = path.join(tmpDir, "apple-wwdr");
  fs.mkdirSync(certDir, { recursive: true });

  for (const url of APPLE_WWDR_CERTIFICATE_URLS) {
    const fileName = path.basename(url);
    const certPath = path.join(certDir, fileName);
    await exec(
      `curl --fail --silent --show-error --location --retry 3 -o ${shellQuote(certPath)} ${shellQuote(url)}`,
      { silent: true },
    );
    await exec(`security import ${shellQuote(certPath)} -k ${shellQuote(keychainPath())}`, {
      silent: true,
    }).catch(() => {
      console.log(`  Apple WWDR certificate already present or skipped: ${fileName}`);
    });
  }

  console.log("  ✅ Apple WWDR intermediate certificates installed");
}

async function importCertificate(
  p12Base64: string,
  password: string,
  tmpDir: string,
): Promise<void> {
  const p12Path = path.join(tmpDir, "import.p12");
  fs.writeFileSync(p12Path, Buffer.from(p12Base64, "base64"));
  await exec(
    `security import ${shellQuote(p12Path)} -k ${shellQuote(keychainPath())} -P ${shellQuote(password)} -T /usr/bin/codesign -T /usr/bin/security`,
  );
  await exec(
    `security set-key-partition-list -S "apple-tool:,apple:,codesign:" -k ${shellQuote(KEYCHAIN_PASSWORD)} ${shellQuote(keychainPath())}`,
  );
  fs.rmSync(p12Path, { force: true });
}

async function assertAppleDistributionIdentityAvailable(): Promise<void> {
  const outputs = await logCodeSigningIdentities();
  if (outputs.some((output) => output.includes("Apple Distribution"))) {
    return;
  }

  throw new Error(
    "Apple Distribution identity was imported but is not available as a valid code signing identity. " +
      `find-identity output: ${outputs.join("\n").trim() || "(empty)"}`,
  );
}

async function logCodeSigningIdentities(): Promise<string[]> {
  const commands = [
    `security find-identity -p codesigning -v ${shellQuote(keychainPath())}`,
    `security find-identity -p codesigning -v ${shellQuote(KEYCHAIN_NAME)}`,
    "security find-identity -p codesigning -v",
  ];
  const outputs: string[] = [];

  console.log("  Code signing identities:");
  for (const command of commands) {
    const output = await execAndCapture(command).catch(
      (error) => `Unable to run ${command}: ${error}`,
    );
    outputs.push(output);
    console.log(`  $ ${command}`);
    console.log(indentOutput(output.trim() || "(empty)"));
  }

  return outputs;
}

function keychainPath(): string {
  return path.join(os.homedir(), "Library", "Keychains", `${KEYCHAIN_NAME}-db`);
}

function indentOutput(output: string): string {
  return output
    .split("\n")
    .map((line) => `    ${line}`)
    .join("\n");
}

function shellQuote(value: string): string {
  return `'${value.replace(/'/g, "'\\''")}'`;
}

async function cleanupKeychain(): Promise<void> {
  await exec("security default-keychain -s login.keychain-db", { silent: true }).catch(() => {});
  await exec("security list-keychains -d user -s login.keychain-db", { silent: true }).catch(
    () => {},
  );
  await exec(`security delete-keychain "${KEYCHAIN_NAME}"`, { silent: true }).catch(() => {});
}

// ══════════════════════════════════════════════════════════════
// Provisioning Profile
// ══════════════════════════════════════════════════════════════

async function installProvisioningProfile(profile: ProfileResult, bundleId: string): Promise<void> {
  const profileDir = path.join(os.homedir(), "Library/MobileDevice/Provisioning Profiles");
  fs.mkdirSync(profileDir, { recursive: true });

  const files = fs.readdirSync(profileDir);
  for (const file of files) {
    if (!file.endsWith(".mobileprovision")) continue;
    const filePath = path.join(profileDir, file);
    try {
      const content = fs.readFileSync(filePath, "utf-8");
      if (content.includes("OpenCI") && content.includes(bundleId)) {
        console.log(`  🗑️  Removing old local profile: ${file}`);
        fs.rmSync(filePath, { force: true });
      }
    } catch {}
  }

  const destPath = path.join(profileDir, `${profile.uuid}.mobileprovision`);
  fs.writeFileSync(destPath, Buffer.from(profile.profileContent, "base64"));
}

// ══════════════════════════════════════════════════════════════
// Xcode Project
// ══════════════════════════════════════════════════════════════

function editXcodeProject(
  workingDirectory: string,
  bundleId: string,
  appleTeamId: string,
  profile: ProfileResult,
): void {
  const pbxprojPath = path.join(workingDirectory, "ios/Runner.xcodeproj/project.pbxproj");
  if (!fs.existsSync(pbxprojPath)) {
    throw new Error(`project.pbxproj not found at ${pbxprojPath}`);
  }

  let content = fs.readFileSync(pbxprojPath, "utf-8");

  content = content.replaceAll("CODE_SIGN_STYLE = Automatic;", "CODE_SIGN_STYLE = Manual;");
  content = content.replace(/DEVELOPMENT_TEAM = [^;]*;/g, `DEVELOPMENT_TEAM = ${appleTeamId};`);
  content = content
    .replaceAll(
      'CODE_SIGN_IDENTITY = "Apple Development";',
      'CODE_SIGN_IDENTITY = "Apple Distribution";',
    )
    .replaceAll(
      'CODE_SIGN_IDENTITY = "iPhone Developer";',
      'CODE_SIGN_IDENTITY = "Apple Distribution";',
    )
    .replaceAll(
      '"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "iPhone Developer";',
      '"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "Apple Distribution";',
    );

  content = content.replaceAll(
    `PRODUCT_BUNDLE_IDENTIFIER = ${bundleId};`,
    `PRODUCT_BUNDLE_IDENTIFIER = ${bundleId};\n\t\t\t\tPROVISIONING_PROFILE_SPECIFIER = "${profile.name}";\n\t\t\t\tPROVISIONING_PROFILE = "${profile.uuid}";`,
  );

  fs.writeFileSync(pbxprojPath, content);
}

// ══════════════════════════════════════════════════════════════
// ExportOptions.plist
// ══════════════════════════════════════════════════════════════

function generateExportOptions(
  outputPath: string,
  teamId: string,
  bundleId: string,
  profileName: string,
  distributionMethod: IosDistributionMethod,
): void {
  const plist = `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>${distributionMethod}</string>
    <key>teamID</key>
    <string>${teamId}</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>${bundleId}</key>
        <string>${profileName}</string>
    </dict>
    <key>signingCertificate</key>
    <string>Apple Distribution</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>`;
  fs.writeFileSync(outputPath, plist);
}

// ══════════════════════════════════════════════════════════════
// Xcode project parsing
// ══════════════════════════════════════════════════════════════

function parseFlavor(buildArgs: string): string | undefined {
  const match = buildArgs.match(/--flavor\s+(\S+)|--flavor=(\S+)/);
  if (match) {
    return match[1] || match[2];
  }
  return undefined;
}

function parsePbxproj(
  workingDirectory: string,
  flavor?: string,
): { bundleId: string; teamId: string } {
  const pbxprojPath = path.join(workingDirectory, "ios/Runner.xcodeproj/project.pbxproj");
  if (!fs.existsSync(pbxprojPath)) {
    throw new Error("project.pbxproj not found. Is this a Flutter iOS project?");
  }

  const content = fs.readFileSync(pbxprojPath, "utf-8");

  // 1. Extract XCBuildConfiguration section
  const startIdx = content.indexOf("/* Begin XCBuildConfiguration section */");
  const endIdx = content.indexOf("/* End XCBuildConfiguration section */");
  if (startIdx === -1 || endIdx === -1) {
    throw new Error("XCBuildConfiguration section not found in project.pbxproj");
  }
  const section = content.substring(startIdx, endIdx);

  // 2. Parse configurations
  const blocks = section.split("isa = XCBuildConfiguration;");
  const configs: { name: string; bundleId?: string; teamId?: string }[] = [];
  for (let i = 1; i < blocks.length; i++) {
    const block = blocks[i];
    const nameMatch = block.match(/name\s*=\s*(?:"([^"]+)"|([^;\s]+))\s*;/);
    if (!nameMatch) continue;
    const configName = nameMatch[1] || nameMatch[2];

    const bundleMatch = block.match(/PRODUCT_BUNDLE_IDENTIFIER\s*=\s*([^;\s]+)\s*;/);
    const teamMatch = block.match(/DEVELOPMENT_TEAM\s*=\s*([^;\s]+)\s*;/);

    configs.push({
      name: configName,
      bundleId: bundleMatch ? bundleMatch[1].replace(/"|;/g, "").trim() : undefined,
      teamId: teamMatch ? teamMatch[1].replace(/"|;/g, "").trim() : undefined,
    });
  }

  // 3. Find target configuration matching the flavor
  let targetConfig: { name: string; bundleId?: string; teamId?: string } | undefined;
  if (flavor) {
    const lowerFlavor = flavor.toLowerCase();
    targetConfig = configs.find((c) => c.name.toLowerCase() === `release-${lowerFlavor}`);
    if (!targetConfig)
      targetConfig = configs.find((c) => c.name.toLowerCase() === `profile-${lowerFlavor}`);
    if (!targetConfig)
      targetConfig = configs.find((c) => c.name.toLowerCase() === `debug-${lowerFlavor}`);
    if (!targetConfig)
      targetConfig = configs.find((c) => c.name.toLowerCase().includes(lowerFlavor));
  } else {
    targetConfig = configs.find((c) => c.name.toLowerCase() === "release");
    if (!targetConfig) targetConfig = configs.find((c) => c.name.toLowerCase() === "profile");
    if (!targetConfig) targetConfig = configs.find((c) => c.name.toLowerCase() === "debug");
  }

  // 4. Extract bundle ID and team ID
  let bundleId = targetConfig?.bundleId;
  if (!bundleId) {
    // Fallback: any valid PRODUCT_BUNDLE_IDENTIFIER
    const validConfig = configs.find(
      (c) => c.bundleId && !c.bundleId.includes("$(") && !c.bundleId.includes("Tests"),
    );
    bundleId = validConfig?.bundleId;
  }
  if (!bundleId) {
    throw new Error("No valid PRODUCT_BUNDLE_IDENTIFIER found in project.pbxproj");
  }

  // Team ID fallback to first found globally or in configs
  let teamId = targetConfig?.teamId;
  if (!teamId) {
    const teamMatches = content.match(/DEVELOPMENT_TEAM = ([A-Z0-9]+);/);
    teamId = teamMatches ? teamMatches[1] : undefined;
  }
  if (!teamId) {
    const validConfig = configs.find((c) => c.teamId);
    teamId = validConfig?.teamId;
  }
  if (!teamId) {
    throw new Error(
      "DEVELOPMENT_TEAM not found in project.pbxproj. Open the project in Xcode and set your team first.",
    );
  }

  console.log(`  📦 Auto-detected bundle ID: ${bundleId}`);
  console.log(`  👥 Auto-detected team ID: ${teamId}`);

  return { bundleId, teamId };
}

// ══════════════════════════════════════════════════════════════
// Version parsing
// ══════════════════════════════════════════════════════════════

function parseVersion(workingDirectory: string): { version: string; buildNumber: string } {
  const pubspecPath = path.join(workingDirectory, "pubspec.yaml");
  if (!fs.existsSync(pubspecPath)) {
    throw new Error("pubspec.yaml not found");
  }

  const content = fs.readFileSync(pubspecPath, "utf-8");
  const match = content.match(/^version:\s*(\S+)/m);
  if (!match) {
    throw new Error("version not found in pubspec.yaml");
  }

  const raw = match[1];
  const [version, buildNumber] = raw.includes("+") ? raw.split("+") : [raw, "1"];
  return { version, buildNumber };
}

// ══════════════════════════════════════════════════════════════
// OTA Distribution
// ══════════════════════════════════════════════════════════════

async function parsePlistBuffer(buffer: Buffer): Promise<any> {
  const tempFile = path.join(
    os.tmpdir(),
    `temp-${Date.now()}-${Math.random().toString(36).substring(7)}.plist`,
  );
  try {
    fs.writeFileSync(tempFile, buffer);
    // Convert binary plist to xml1 format (in place conversion)
    await exec(`plutil -convert xml1 "${tempFile}"`, { silent: true });
    const convertedContent = fs.readFileSync(tempFile, "utf8");
    return plist.parse(convertedContent);
  } catch (error) {
    console.log(`  (Fallback) plutil failed, trying direct plist parse: ${error}`);
    return plist.parse(buffer.toString("utf8"));
  } finally {
    try {
      if (fs.existsSync(tempFile)) {
        fs.unlinkSync(tempFile);
      }
    } catch {
      // ignore
    }
  }
}

async function handleOtaDistribution(ipaPath: string): Promise<void> {
  const otaEnabled = core.getInput("ota-distribution") === "true";
  if (!otaEnabled) {
    console.log("  Skipping iOS OTA distribution (ota-distribution is not true)");
    return;
  }

  const buildJobId = process.env.OPENCI_BUILD_JOB_ID;
  if (!buildJobId) {
    console.log("  ⚠️ Skipping OTA distribution: OPENCI_BUILD_JOB_ID is not set.");
    return;
  }

  const openciServerUrl = process.env.OPENCI_SERVER_URL;
  if (!openciServerUrl) {
    console.log("  ⚠️ Skipping OTA distribution: OPENCI_SERVER_URL is not set.");
    return;
  }

  const idToken = process.env.OPENCI_ID_TOKEN;
  if (!idToken) {
    console.log("  ⚠️ Skipping OTA distribution: OPENCI_ID_TOKEN is not set.");
    return;
  }

  core.startGroup("iOS OTA Distribution (Upload & Registration)");
  console.log(`  Extracting metadata from IPA: ${ipaPath}`);

  let appName = "App";
  let bundleId = "";
  let ipaVersion = "1.0.0";
  let provisionedUdids: string[] = [];

  try {
    const zip = new AdmZip(ipaPath);
    const zipEntries = zip.getEntries();

    // 1. Info.plist の探索と抽出
    const infoPlistEntry = zipEntries.find((entry) =>
      entry.entryName.match(/^Payload\/[^/]+\.app\/Info\.plist$/),
    );
    if (infoPlistEntry) {
      const plistBuffer = zip.readFile(infoPlistEntry);
      if (plistBuffer) {
        const parsed = (await parsePlistBuffer(plistBuffer)) as any;
        appName = parsed.CFBundleName || parsed.CFBundleDisplayName || appName;
        bundleId = parsed.CFBundleIdentifier || bundleId;
        ipaVersion = parsed.CFBundleShortVersionString || parsed.CFBundleVersion || ipaVersion;
      }
    }

    // 2. embedded.mobileprovision の探索と抽出
    const provisionEntry = zipEntries.find((entry) =>
      entry.entryName.match(/^Payload\/[^/]+\.app\/embedded\.mobileprovision$/),
    );
    if (provisionEntry) {
      const provisionBuffer = zip.readFile(provisionEntry);
      if (provisionBuffer) {
        const contentStr = provisionBuffer.toString("latin1");
        const plistMatch = contentStr.match(/<plist[^>]*>[\s\S]*?<\/plist>/);
        if (plistMatch) {
          const parsedProvision = plist.parse(plistMatch[0]) as any;
          if (
            parsedProvision.ProvisionedDevices &&
            Array.isArray(parsedProvision.ProvisionedDevices)
          ) {
            provisionedUdids = parsedProvision.ProvisionedDevices;
            console.log(
              `  Found ${provisionedUdids.length} provisioned device UDID(s) in profile.`,
            );
          }
        }
      }
    }
  } catch (error) {
    console.error(`  ⚠️ Failed to parse IPA metadata: ${error}`);
  }

  console.log(`  App Name: ${appName}`);
  console.log(`  Bundle ID: ${bundleId}`);
  console.log(`  Version: ${ipaVersion}`);

  const filename = `${buildJobId}.ipa`;
  const uploadUrl = `${openciServerUrl}/builds/${buildJobId}/artifacts?name=${encodeURIComponent(filename)}`;

  console.log(`  Uploading IPA to openci_server: ${uploadUrl}`);

  try {
    const fileStream = fs.createReadStream(ipaPath);
    const uploadResponse = await fetch(uploadUrl, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${idToken}`,
        "Content-Type": "application/octet-stream",
      },
      body: fileStream as any,
      duplex: "half",
    } as any);

    if (!uploadResponse.ok) {
      const errorText = await uploadResponse.text();
      throw new Error(`Upload failed with status ${uploadResponse.status}: ${errorText}`);
    }

    const uploadData = (await uploadResponse.json()) as { success: boolean; downloadUrl: string };
    if (!uploadData.success || !uploadData.downloadUrl) {
      throw new Error(
        `Upload succeeded but response format was invalid: ${JSON.stringify(uploadData)}`,
      );
    }

    const ipaUrl = uploadData.downloadUrl;
    console.log(`  Uploaded successfully. Download URL: ${ipaUrl}`);

    // openci_server の PATCH /builds/[id] を叩いて更新する
    const patchUrl = `${openciServerUrl}/builds/${buildJobId}`;
    console.log(`  Updating build job metadata at openci_server: ${patchUrl}`);

    const patchResponse = await fetch(patchUrl, {
      method: "PATCH",
      headers: {
        Authorization: `Bearer ${idToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        ipaUrl,
        bundleId,
        ipaVersion,
        appName,
        provisionedUdids,
        hasIpa: true,
      }),
    });

    if (!patchResponse.ok) {
      const errorText = await patchResponse.text();
      throw new Error(`PATCH build job failed with status ${patchResponse.status}: ${errorText}`);
    }

    console.log("  ✅ iOS OTA distribution setup completed successfully.");
  } catch (error) {
    console.error(`  ❌ Failed to complete OTA distribution: ${error}`);
    throw error;
  } finally {
    core.endGroup();
  }
}

async function detectFlutterVersion(): Promise<string | undefined> {
  try {
    const output = await execAndCapture("flutter --version");
    const match = output.match(/Flutter\s+(\d+\.\d+\.\d+)/);
    if (match) {
      return match[1];
    }
  } catch (error) {
    console.log(`  ⚠️ Failed to detect Flutter version: ${error}`);
  }
  return undefined;
}
