import * as core from "@actions/core";
import { deployAndroid } from "./src/android";
import { buildAndSignIos } from "./src/ios";
import { buildSignAndNotarizeMacos } from "./src/macos";
import { deployWeb } from "./src/web";

async function run(): Promise<void> {
  try {
    const platform = core.getInput("platform", { required: true });

    switch (platform) {
      case "web":
        await deployWeb();
        break;
      case "ios":
        await buildAndSignIos();
        break;
      case "macos":
        await buildSignAndNotarizeMacos();
        break;
      case "android":
        await deployAndroid();
        break;
      default:
        throw new Error(`Unsupported platform: ${platform}`);
    }
  } catch (error) {
    if (error instanceof Error) {
      core.setFailed(error.message);
    } else {
      core.setFailed(String(error));
    }
  }
}

void run();
