import { randomUUID } from "crypto";
import { getFirestore } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";
import { onRequest } from "firebase-functions/v2/https";

export const getMobileconfig = onRequest(async (request, response) => {
  const userId = request.query.userId;
  if (typeof userId !== "string" || !userId) {
    logger.warn("getMobileconfig request is missing userId query parameter");
    response.status(400).send("Missing userId query parameter");
    return;
  }

  const host = request.headers.host || "openci.org";
  const protocol = host.startsWith("localhost") || host.startsWith("127.0.0.1") ? "http" : "https";
  const callbackUrl = `${protocol}://${host}/register-device?userId=${encodeURIComponent(userId)}`;

  const profileUuid = randomUUID();

  const configXml = `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>PayloadContent</key>
  <dict>
    <key>URL</key>
    <string>${callbackUrl}</string>
    <key>DeviceAttributes</key>
    <array>
      <string>UDID</string>
      <string>IMEI</string>
      <string>ICCID</string>
      <string>VERSION</string>
      <string>PRODUCT</string>
    </array>
  </dict>
  <key>PayloadDescription</key>
  <string>Profile to register your iOS device UDID for OpenCI App Distribution.</string>
  <key>PayloadDisplayName</key>
  <string>OpenCI Device UDID Enrollment</string>
  <key>PayloadIdentifier</key>
  <string>org.openci.profile-service</string>
  <key>PayloadOrganization</key>
  <string>OpenCI</string>
  <key>PayloadType</key>
  <string>Profile Service</string>
  <key>PayloadUUID</key>
  <string>${profileUuid}</string>
  <key>PayloadVersion</key>
  <integer>1</integer>
</dict>
</plist>`;

  response.set("Content-Type", "application/x-apple-aspen-config; charset=utf-8");
  response.set("Content-Disposition", 'attachment; filename="openci-udid.mobileconfig"');
  response.status(200).send(configXml);
});

export const registerDevice = onRequest(async (request, response) => {
  const userId = request.query.userId;
  if (typeof userId !== "string" || !userId) {
    logger.warn("registerDevice callback request is missing userId query parameter");
    response.status(400).send("Missing userId query parameter");
    return;
  }

  const host = request.headers.host || "openci.org";
  const protocol = host.startsWith("localhost") || host.startsWith("127.0.0.1") ? "http" : "https";

  try {
    let bodyStr = "";
    if (Buffer.isBuffer(request.body)) {
      bodyStr = request.body.toString("latin1");
    } else if (typeof request.body === "string") {
      bodyStr = request.body;
    } else {
      bodyStr = JSON.stringify(request.body);
    }

    const udidMatch = bodyStr.match(/<key>UDID<\/key>\s*<string>([^<]+)<\/string>/i);
    const udid = udidMatch && udidMatch[1] ? udidMatch[1].trim() : null;

    if (!udid) {
      logger.warn("registerDevice: Could not find UDID in payload body", {
        bodySnippet: bodyStr.substring(0, 500),
      });
      response.status(400).send("Could not extract UDID from profile installation payload");
      return;
    }

    const productMatch = bodyStr.match(/<key>PRODUCT<\/key>\s*<string>([^<]+)<\/string>/i);
    const product = productMatch && productMatch[1] ? productMatch[1].trim() : "Unknown";

    const versionMatch = bodyStr.match(/<key>VERSION<\/key>\s*<string>([^<]+)<\/string>/i);
    const osVersion = versionMatch && versionMatch[1] ? versionMatch[1].trim() : "Unknown";

    logger.info(
      `Successfully extracted UDID ${udid} for user ${userId} (Product: ${product}, OS: ${osVersion})`,
    );

    const db = getFirestore();
    await db.collection("users_v0").doc(userId).set(
      {
        udid,
        deviceProduct: product,
        deviceOsVersion: osVersion,
        updatedAt: new Date().toISOString(),
      },
      { merge: true },
    );

    const redirectUrl = `${protocol}://${host}/#/app-distributions?enrolled=true&udid=${encodeURIComponent(udid)}`;
    logger.info(`Redirecting device to ${redirectUrl}`);
    response.redirect(302, redirectUrl);
  } catch (error) {
    logger.error("Failed in registerDevice callback", { error, userId });
    response.status(500).send("Internal Server Error");
  }
});
