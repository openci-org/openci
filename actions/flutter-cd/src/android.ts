import * as core from "@actions/core";
import * as fs from "fs";
import { google } from "googleapis";
import * as os from "os";
import * as path from "path";
import { exec } from "./helpers";

function parseBooleanInput(inputName: string, value: string, defaultValue: boolean): boolean {
  if (!value) {
    return defaultValue;
  }
  if (value.toLowerCase() === "true") {
    return true;
  }
  if (value.toLowerCase() === "false") {
    return false;
  }
  throw new Error(`Input ${inputName} must be 'true' or 'false'`);
}

export async function deployAndroid(): Promise<void> {
  const workingDirectory = core.getInput("working-directory") || ".";
  const buildArgs = core.getInput("build-args") || "";
  const buildNumberInput = core.getInput("build-number") || "";
  const buildNumber = buildNumberInput ? parseInt(buildNumberInput, 10) : null;
  const flavor = parseFlavor(buildArgs);

  const keystoreBase64 = core.getInput("android-keystore-base64") || "";
  const keystorePassword = core.getInput("android-keystore-password") || "";
  const keyAlias = core.getInput("android-key-alias") || "";
  const keyPassword = core.getInput("android-key-password") || "";

  const serviceAccountJson = core.getInput("google-play-service-account-json") || "";
  const track = core.getInput("google-play-track") || "internal";
  const explicitPackageName = core.getInput("android-package-name") || "";

  const shorebirdEnabled = parseBooleanInput("shorebird", core.getInput("shorebird") || "", false);
  const shorebirdToken = core.getInput("shorebird-token") || "";
  const flutterVersion = core.getInput("flutter-version") || "";
  const otaEnabled = core.getInput("ota-distribution") === "true";

  const tempDir = fs.mkdtempSync(path.join(os.tmpdir(), "openci-android-"));
  const keystorePath = path.join(tempDir, "keystore.jks");
  const propertiesPath = path.join(workingDirectory, "android", "key.properties");

  let restoreSigning = false;

  try {
    core.startGroup("Step 1: Set up Android signing");
    if (keystoreBase64) {
      console.log("  Restoring signing keystore and key.properties...");
      const keystoreBuffer = Buffer.from(keystoreBase64, "base64");
      fs.writeFileSync(keystorePath, keystoreBuffer);

      const propertiesContent = [
        `storeFile=${keystorePath}`,
        `storePassword=${keystorePassword}`,
        `keyAlias=${keyAlias}`,
        `keyPassword=${keyPassword}`,
      ].join("\n");

      fs.writeFileSync(propertiesPath, propertiesContent);
      restoreSigning = true;
      console.log(`  ✅ Signing config restored at ${propertiesPath}`);
    } else {
      console.log("  ⚠️ No keystore provided, building with default signing (debug key)");
    }
    core.endGroup();

    // ── Step 1.5: Setup Shorebird (Optional) ───────────────
    if (shorebirdEnabled) {
      core.startGroup("Step 1.5: Setting up Shorebird");
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

    // ── Step 2: Build Artifacts (AAB & APK) ─────────────────
    let aabPath = "";
    let apkPath = "";

    const buildNumberArg = buildNumber !== null ? `--build-number=${buildNumber}` : "";

    if (shorebirdEnabled) {
      core.startGroup("Step 2: Building with Shorebird");
      const flutterVersionArg = flutterVersion ? `--flutter-version=${flutterVersion}` : "";
      const artifactArg = otaEnabled ? "--artifact apk" : "";
      const flutterArgs = `${buildNumberArg} ${buildArgs}`.trim();
      const separator = flutterArgs ? "--" : "";

      console.log(`  🐦 Running shorebird release android...`);
      await exec(
        `shorebird release android ${flutterVersionArg} ${artifactArg} ${separator} ${flutterArgs}`.trim(),
        { cwd: workingDirectory },
      );

      aabPath =
        findFile(path.join(workingDirectory, "build", "app", "outputs"), ".aab", flavor) || "";
      apkPath =
        findFile(path.join(workingDirectory, "build", "app", "outputs"), ".apk", flavor) || "";

      if (otaEnabled && !fs.existsSync(apkPath)) {
        throw new Error(`APK file not found at ${apkPath}`);
      }
      if ((serviceAccountJson || !otaEnabled) && !fs.existsSync(aabPath)) {
        throw new Error(`AAB file not found at ${aabPath}`);
      }

      if (otaEnabled) {
        console.log(`  ✅ APK built successfully at ${apkPath}`);
        core.setOutput("apk-path", apkPath);
      }
      if (serviceAccountJson || !otaEnabled) {
        console.log(`  ✅ AAB built successfully at ${aabPath}`);
        core.setOutput("aab-path", aabPath);
      }
      core.endGroup();
    } else {
      // 1. Build AAB (if Play Store deployment or explicit release is expected)
      if (serviceAccountJson || !otaEnabled) {
        core.startGroup("Step 2.1: Building AAB");
        await exec(`flutter build appbundle --release ${buildNumberArg} ${buildArgs}`.trim(), {
          cwd: workingDirectory,
        });

        aabPath =
          findFile(path.join(workingDirectory, "build", "app", "outputs"), ".aab", flavor) || "";

        if (!fs.existsSync(aabPath)) {
          throw new Error(`AAB file not found at ${aabPath}`);
        }
        console.log(`  ✅ AAB built successfully at ${aabPath}`);
        core.setOutput("aab-path", aabPath);
        core.endGroup();
      }

      // 2. Build APK (for OTA distribution)
      if (otaEnabled) {
        core.startGroup("Step 2.2: Building APK for OTA");
        await exec(`flutter build apk --release ${buildNumberArg} ${buildArgs}`.trim(), {
          cwd: workingDirectory,
        });

        apkPath =
          findFile(path.join(workingDirectory, "build", "app", "outputs"), ".apk", flavor) || "";

        if (!fs.existsSync(apkPath)) {
          throw new Error(`APK file not found at ${apkPath}`);
        }
        console.log(`  ✅ APK built successfully at ${apkPath}`);
        core.setOutput("apk-path", apkPath);
        core.endGroup();
      }
    }

    // ── Step 3: Google Play Console Distribution ───────────
    if (serviceAccountJson && aabPath) {
      core.startGroup("Step 3: Uploading AAB to Google Play Console");
      const packageName = explicitPackageName || detectPackageName(workingDirectory, flavor);
      console.log(`  Package name: ${packageName}`);
      console.log(`  Target Track: ${track}`);

      const auth = new google.auth.GoogleAuth({
        credentials: JSON.parse(serviceAccountJson),
        scopes: ["https://www.googleapis.com/auth/androidpublisher"],
      });

      const publisher = google.androidpublisher({
        version: "v3",
        auth,
      });

      console.log("  Creating a new edit session...");
      const edit = await publisher.edits.insert({
        packageName,
      });
      const editId = edit.data.id;
      if (!editId) {
        throw new Error("Failed to create edit session");
      }

      console.log(`  Uploading bundle from: ${aabPath}`);
      const bundle = await publisher.edits.bundles.upload({
        editId,
        packageName,
        media: {
          mimeType: "application/octet-stream",
          body: fs.createReadStream(aabPath),
        },
      });

      const versionCode = bundle.data.versionCode;
      if (!versionCode) {
        throw new Error("AAB upload succeeded but no versionCode was returned");
      }
      console.log(`  ✅ AAB uploaded. Version Code: ${versionCode}`);

      console.log(`  Assigning release to track: ${track}`);
      await publisher.edits.tracks.update({
        editId,
        packageName,
        track,
        requestBody: {
          track,
          releases: [
            {
              versionCodes: [versionCode.toString()],
              status: "completed",
            },
          ],
        },
      });

      console.log("  Committing edit session...");
      await publisher.edits.commit({
        editId,
        packageName,
      });
      console.log("  ✅ Google Play deployment completed successfully.");
      core.endGroup();
    } else {
      console.log("  Google Play credentials not provided; skipping AAB upload");
    }

    // ── Step 4: OTA Distribution ─────────────────────────────
    if (otaEnabled && apkPath) {
      await handleAndroidOtaDistribution(workingDirectory, apkPath, flavor);
    }
  } catch (error) {
    console.error(`  ❌ Android deployment failed: ${error}`);
    throw error;
  } finally {
    core.startGroup("Cleanup");
    if (restoreSigning) {
      if (fs.existsSync(propertiesPath)) {
        fs.rmSync(propertiesPath, { force: true });
        console.log("  Removed temporary key.properties");
      }
    }
    if (fs.existsSync(tempDir)) {
      fs.rmSync(tempDir, { recursive: true, force: true });
      console.log("  Cleaned up temporary keystore directories");
    }
    core.endGroup();
  }
}

async function handleAndroidOtaDistribution(
  workingDirectory: string,
  apkPath: string,
  flavor?: string,
): Promise<void> {
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

  core.startGroup("Android OTA Distribution (Upload & Registration)");

  let appName = "App";
  let packageName = "";
  let apkVersion = "1.0.0";

  try {
    packageName = detectPackageName(workingDirectory, flavor);
    const pubspecPath = path.join(workingDirectory, "pubspec.yaml");
    if (fs.existsSync(pubspecPath)) {
      const pubspecContent = fs.readFileSync(pubspecPath, "utf8");
      const nameMatch = pubspecContent.match(/^name:\s*(.+)$/m);
      if (nameMatch) {
        appName = nameMatch[1].trim();
      }
      const versionMatch = pubspecContent.match(/^version:\s*(.+)$/m);
      if (versionMatch) {
        apkVersion = versionMatch[1].trim();
      }
    }
  } catch (error) {
    console.error(`  ⚠️ Failed to parse Android metadata: ${error}`);
  }

  console.log(`  App Name: ${appName}`);
  console.log(`  Package Name: ${packageName}`);
  console.log(`  Version: ${apkVersion}`);

  const filename = `${buildJobId}.apk`;
  const uploadUrl = `${openciServerUrl}/builds/${buildJobId}/artifacts?name=${encodeURIComponent(filename)}`;

  console.log(`  Uploading APK to openci_server: ${uploadUrl}`);

  try {
    const fileStream = fs.createReadStream(apkPath);
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

    const apkUrl = uploadData.downloadUrl;
    console.log(`  Uploaded successfully. Download URL: ${apkUrl}`);

    const patchUrl = `${openciServerUrl}/builds/${buildJobId}`;
    console.log(`  Updating build job metadata at openci_server: ${patchUrl}`);

    const patchResponse = await fetch(patchUrl, {
      method: "PATCH",
      headers: {
        Authorization: `Bearer ${idToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        ipaUrl: apkUrl,
        bundleId: packageName,
        ipaVersion: apkVersion,
        appName,
        hasIpa: true,
      }),
    });

    if (!patchResponse.ok) {
      const errorText = await patchResponse.text();
      throw new Error(`PATCH build job failed with status ${patchResponse.status}: ${errorText}`);
    }

    console.log("  ✅ Android OTA distribution setup completed successfully.");
  } catch (error) {
    console.error(`  ❌ Failed to complete OTA distribution: ${error}`);
    throw error;
  } finally {
    core.endGroup();
  }
}

function detectPackageName(workingDirectory: string, flavor?: string): string {
  const gradlePath = path.join(workingDirectory, "android", "app", "build.gradle.kts");
  const gradlePathGroovy = path.join(workingDirectory, "android", "app", "build.gradle");

  let content = "";
  if (fs.existsSync(gradlePath)) {
    content = fs.readFileSync(gradlePath, "utf8");
  } else if (fs.existsSync(gradlePathGroovy)) {
    content = fs.readFileSync(gradlePathGroovy, "utf8");
  } else {
    throw new Error(
      "Gradle build file not found. Could not auto-detect package name. Please specify 'android-package-name' input.",
    );
  }

  if (flavor) {
    const flavorRegex = new RegExp(
      flavor + "\\s*\\{[^}]*applicationId\\s*=?\\s*['\"]([^'\"]+)['\"]",
    );
    const flavorMatch = content.match(flavorRegex);
    if (flavorMatch) {
      return flavorMatch[1];
    }
  }

  const defaultConfigMatch = content.match(
    /defaultConfig\s*\\{[^}]*applicationId\\s*=?\s*['"]([^'"]+)['"]/,
  );
  if (defaultConfigMatch) {
    return defaultConfigMatch[1];
  }

  const match = content.match(/applicationId\s*=?\s*['"]([^'"]+)['"]/);
  if (match) {
    return match[1];
  }

  throw new Error(
    "Unable to parse applicationId from gradle configuration. Please specify 'android-package-name' input.",
  );
}

function parseFlavor(buildArgs: string): string | undefined {
  const match = buildArgs.match(/--flavor\s+(\S+)|--flavor=(\S+)/);
  return match ? match[1] || match[2] : undefined;
}

function findFile(dir: string, extension: string, flavor?: string): string | undefined {
  if (!fs.existsSync(dir)) {
    return undefined;
  }
  const files = fs.readdirSync(dir);
  let fallback: string | undefined;

  for (const file of files) {
    const filePath = path.join(dir, file);
    const stat = fs.statSync(filePath);
    if (stat.isDirectory()) {
      const found = findFile(filePath, extension, flavor);
      if (found) {
        if (flavor && found.toLowerCase().includes(flavor.toLowerCase())) {
          return found;
        }
        if (!fallback) {
          fallback = found;
        }
      }
    } else if (file.endsWith(extension)) {
      if (flavor && file.toLowerCase().includes(flavor.toLowerCase())) {
        return filePath;
      }
      if (!fallback) {
        fallback = filePath;
      }
    }
  }
  return fallback;
}
