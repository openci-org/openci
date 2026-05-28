import { getFirestore } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";
import { onRequest } from "firebase-functions/v2/https";

function escapeXml(unsafe: string): string {
  return unsafe.replace(/[<>&'"]/g, (c) => {
    switch (c) {
      case "<":
        return "&lt;";
      case ">":
        return "&gt;";
      case "&":
        return "&amp;";
      case "'":
        return "&apos;";
      case '"':
        return "&quot;";
      default:
        return c;
    }
  });
}

export const iosManifest = onRequest(async (request, response) => {
  const buildJobId = request.query.buildJobId;
  if (typeof buildJobId !== "string" || !buildJobId) {
    logger.warn("iosManifest request is missing buildJobId query parameter");
    response.status(400).send("Missing buildJobId query parameter");
    return;
  }

  try {
    const db = getFirestore();
    const docRef = db.collection("build_jobs_v0").doc(buildJobId);
    const doc = await docRef.get();

    if (!doc.exists) {
      logger.warn(`iosManifest: Build job ${buildJobId} not found`);
      response.status(404).send("Build job not found");
      return;
    }

    const data = doc.data();
    if (!data) {
      logger.warn(`iosManifest: Build job ${buildJobId} contains no data`);
      response.status(404).send("Build job data is empty");
      return;
    }

    await docRef.update({
      otaDownloadedAt: new Date().toISOString(),
    });

    const ipaUrl = data.ipaUrl;
    const bundleId = data.bundleId || "org.openci.dashboard";
    const ipaVersion = data.ipaVersion || "1.0.0";
    const appName = data.appName || "OpenCI App";

    if (!ipaUrl) {
      logger.warn(`iosManifest: Build job ${buildJobId} does not have an ipaUrl`);
      response.status(400).send("Build job does not contain a compiled app URL");
      return;
    }

    const safeIpaUrl = escapeXml(ipaUrl);
    const safeBundleId = escapeXml(bundleId);
    const safeIpaVersion = escapeXml(ipaVersion);
    const safeAppName = escapeXml(appName);

    const plistXml = `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>items</key>
  <array>
    <dict>
      <key>assets</key>
      <array>
        <dict>
          <key>kind</key>
          <string>software-package</string>
          <key>url</key>
          <string>${safeIpaUrl}</string>
        </dict>
      </array>
      <key>metadata</key>
      <dict>
        <key>bundle-identifier</key>
        <string>${safeBundleId}</string>
        <key>bundle-version</key>
        <string>${safeIpaVersion}</string>
        <key>kind</key>
        <string>software</string>
        <key>title</key>
        <string>${safeAppName}</string>
      </dict>
    </dict>
  </array>
</dict>
</plist>`;

    response.set("Content-Type", "text/xml; charset=utf-8");
    response.status(200).send(plistXml);
  } catch (error) {
    logger.error("Failed to generate iosManifest plist", { error, buildJobId });
    response.status(500).send("Internal Server Error");
  }
});
