import { randomUUID } from "crypto";
import { getFirestore } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";
import { onRequest } from "firebase-functions/v2/https";

function getRequestOrigin(request: any): { protocol: string; host: string; origin: string } {
  const forwardedHost = request.headers["x-forwarded-host"];
  const directHost = request.headers.host;

  let hostHeader = forwardedHost || directHost || "";
  if (Array.isArray(hostHeader)) {
    hostHeader = hostHeader[0] || "";
  }

  let host = typeof hostHeader === "string" ? hostHeader.trim() : "";
  const commaIndex = host.indexOf(",");
  if (commaIndex !== -1) {
    host = host.substring(0, commaIndex).trim();
  }

  if (!host || host.indexOf("google.internal") !== -1 || host.indexOf("run.app") !== -1) {
    // デフォルトの本番ドメイン
    const defaultHost = "openci-b1b91.web.app";
    return { protocol: "https", host: defaultHost, origin: `https://${defaultHost}` };
  }

  if (host.indexOf("localhost") === 0 || host.indexOf("127.0.0.1") === 0) {
    return { protocol: "http", host, origin: `http://${host}` };
  }

  const protocol = "https";
  return { protocol, host, origin: `${protocol}://${host}` };
}

export const getMobileconfig = onRequest(async (request, response) => {
  const userId = request.query.userId;
  if (typeof userId !== "string" || !userId) {
    logger.warn("getMobileconfig request is missing userId query parameter");
    response.status(400).send("Missing userId query parameter");
    return;
  }

  const { protocol, host, origin } = getRequestOrigin(request);
  const callbackUrl = `${protocol}://${host}/register-device?userId=${encodeURIComponent(userId)}&amp;redirectOrigin=${encodeURIComponent(origin)}`;

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

  const queryRedirectOrigin = request.query.redirectOrigin;
  let redirectOrigin = "https://openci-b1b91.web.app";
  if (typeof queryRedirectOrigin === "string" && queryRedirectOrigin) {
    redirectOrigin = queryRedirectOrigin;
  } else {
    const { origin } = getRequestOrigin(request);
    redirectOrigin = origin;
  }

  try {
    let bodyStr = "";
    if (request.rawBody) {
      bodyStr = request.rawBody.toString("latin1");
    } else if (Buffer.isBuffer(request.body)) {
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

    const redirectUrl = `${redirectOrigin}/?enrolled=true&udid=${encodeURIComponent(udid)}#/distributions`;
    logger.info(`Redirecting device to ${redirectUrl}`);
    response.writeHead(301, {
      Location: redirectUrl,
      "Content-Length": "0",
    });
    response.end();
  } catch (error) {
    logger.error("Failed in registerDevice callback", { error, userId });
    response.status(500).send("Internal Server Error");
  }
});
