import * as core from "@actions/core";
import * as fs from "fs";
import { google } from "googleapis";
import * as os from "os";
import * as path from "path";
import { exec } from "./helpers";

export async function deployAndroid(): Promise<void> {
  const workingDirectory = core.getInput("working-directory") || ".";
  const buildArgs = core.getInput("build-args") || "";
  const buildNumberInput = core.getInput("build-number") || "";
  const buildNumber = buildNumberInput ? parseInt(buildNumberInput, 10) : null;

  const keystoreBase64 = core.getInput("android-keystore-base64") || "";
  const keystorePassword = core.getInput("android-keystore-password") || "";
  const keyAlias = core.getInput("android-key-alias") || "";
  const keyPassword = core.getInput("android-key-password") || "";

  const serviceAccountJson = core.getInput("google-play-service-account-json") || "";
  const track = core.getInput("google-play-track") || "internal";
  const explicitPackageName = core.getInput("android-package-name") || "";

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

    core.startGroup("Step 2: Build App Bundle (AAB)");
    const buildNumberArg = buildNumber !== null ? `--build-number=${buildNumber}` : "";
    await exec(`flutter build appbundle --release ${buildNumberArg} ${buildArgs}`.trim(), {
      cwd: workingDirectory,
    });

    const aabPath = path.join(
      workingDirectory,
      "build",
      "app",
      "outputs",
      "bundle",
      "release",
      "app-release.aab",
    );

    if (!fs.existsSync(aabPath)) {
      throw new Error(`AAB file not found at ${aabPath}`);
    }
    console.log(`  ✅ AAB built successfully at ${aabPath}`);
    core.setOutput("aab-path", aabPath);
    core.endGroup();

    if (serviceAccountJson) {
      core.startGroup("Step 3: Uploading AAB to Google Play Console");
      const packageName = explicitPackageName || detectPackageName(workingDirectory);
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

function detectPackageName(workingDirectory: string): string {
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

  const match = content.match(/applicationId\s*=?\s*['"]([^'"]+)['"]/);
  if (match) {
    return match[1];
  }

  throw new Error(
    "Unable to parse applicationId from gradle configuration. Please specify 'android-package-name' input.",
  );
}
