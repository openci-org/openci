import * as core from "@actions/core";
import { exec } from "./helpers";
import * as fs from "fs";
import * as path from "path";

export async function deployWeb(): Promise<void> {
  const workingDirectory = core.getInput("working-directory") || ".";
  const buildArgs = core.getInput("build-args") || "";
  const saJson = core.getInput("firebase-service-account") || "";
  const preview = core.getInput("preview") === "true";

  // Build
  core.startGroup("Build web");
  await exec(`flutter build web ${buildArgs}`.trim(), { cwd: workingDirectory });
  core.endGroup();

  if (!saJson) {
    core.info("No firebase-service-account provided, skipping deploy.");
    return;
  }

  // Find firebase.json
  core.startGroup("Deploy to Firebase Hosting");

  let firebaseDir = findFirebaseDir(workingDirectory);
  if (!firebaseDir) {
    firebaseDir = findFirebaseDir(".");
  }

  if (!firebaseDir) {
    throw new Error("firebase.json not found in the repository");
  }
  core.info(`Found firebase.json in ${firebaseDir}`);

  // Copy build output
  const publicDir = path.join(firebaseDir, "public");
  fs.rmSync(publicDir, { recursive: true, force: true });
  fs.cpSync(path.join(workingDirectory, "build/web"), publicDir, {
    recursive: true,
  });

  // Ensure firebase CLI
  await ensureFirebaseCli();

  // Deploy
  fs.writeFileSync("/tmp/firebase-sa.json", saJson);
  process.env.GOOGLE_APPLICATION_CREDENTIALS = "/tmp/firebase-sa.json";

  const projectId = JSON.parse(saJson).project_id;

  if (preview) {
    const channel = await getShortSha();
    core.info(`Deploying to preview channel: ${channel}`);
    await exec(
      `firebase hosting:channel:deploy "${channel}" --project "${projectId}" --non-interactive`,
      { cwd: firebaseDir },
    );
  } else {
    core.info("Deploying to live site");
    await exec(`firebase deploy --only hosting --project "${projectId}" --non-interactive`, {
      cwd: firebaseDir,
    });
  }

  fs.rmSync("/tmp/firebase-sa.json", { force: true });
  core.endGroup();
}

function findFirebaseDir(startDir: string): string | null {
  const { execSync } = require("child_process");
  try {
    const result = execSync(
      `find ${startDir} -name firebase.json -not -path '*/node_modules/*' | head -1`,
      { encoding: "utf-8" },
    ).trim();
    if (!result) return null;
    return path.dirname(result);
  } catch {
    return null;
  }
}

async function ensureFirebaseCli(): Promise<void> {
  try {
    await exec("firebase --version", { silent: true });
  } catch {
    core.info("Installing firebase-tools via npm...");
    try {
      await exec("npm --version", { silent: true });
    } catch {
      core.info("Installing Node.js...");
      const arch = process.arch === "arm64" ? "arm64" : "x64";
      const nodeVersion = "v20.18.3";
      await exec(
        `curl -fSL "https://nodejs.org/dist/${nodeVersion}/node-${nodeVersion}-darwin-${arch}.tar.gz" -o /tmp/node.tar.gz`,
      );
      await exec("tar -xzf /tmp/node.tar.gz -C /tmp");
      process.env.PATH = `/tmp/node-${nodeVersion}-darwin-${arch}/bin:${process.env.PATH}`;
    }
    await exec("npm i -g firebase-tools");
  }
}

async function getShortSha(): Promise<string> {
  const { execSync } = require("child_process");
  try {
    return execSync("git rev-parse --short HEAD", { encoding: "utf-8" }).trim();
  } catch {
    return `preview-${Date.now()}`;
  }
}
