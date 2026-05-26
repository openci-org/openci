import { getFirestore } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";
import { onRequest } from "firebase-functions/v2/https";

export const installOta = onRequest(async (request, response) => {
  const buildJobId = request.query.buildJobId;
  if (typeof buildJobId !== "string" || !buildJobId) {
    logger.warn("installOta request is missing buildJobId query parameter");
    response.status(400).send("Missing buildJobId query parameter");
    return;
  }

  try {
    const db = getFirestore();
    const doc = await db.collection("build_jobs_v0").doc(buildJobId).get();

    if (!doc.exists) {
      logger.warn(`installOta: Build job ${buildJobId} not found`);
      response.status(404).send("Build job not found");
      return;
    }

    const data = doc.data();
    if (!data) {
      logger.warn(`installOta: Build job ${buildJobId} contains no data`);
      response.status(404).send("Build job data is empty");
      return;
    }

    const appName = data.appName || "OpenCI App";
    const runCount = data.runCount || "";
    const ipaVersion = data.ipaVersion || "1.0.0";

    let proto = "https";
    const xForwardedHost = request.headers["x-forwarded-host"];
    let host = "";
    if (xForwardedHost) {
      const parsedHost = Array.isArray(xForwardedHost) ? xForwardedHost[0] : xForwardedHost;
      if (parsedHost) {
        host = parsedHost;
      }
    }
    if (!host) {
      host = request.get("host") || "";
    }

    if (host.includes("localhost") || host.includes("127.0.0.1")) {
      proto = "http";
    } else {
      const forwardedProto = request.headers["x-forwarded-proto"];
      if (forwardedProto) {
        const parsedProto = Array.isArray(forwardedProto) ? forwardedProto[0] : forwardedProto;
        if (parsedProto) {
          proto = parsedProto;
        }
      }
    }
    const origin = `${proto}://${host}`;

    const manifestUrl = `${origin}/iosManifest?buildJobId=${buildJobId}`;
    const installUrl = `itms-services://?action=download-manifest&url=${encodeURIComponent(manifestUrl)}`;

    const html = `<!DOCTYPE html>
<html lang="ja">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${appName} をインストール - OpenCI</title>
  <style>
    :root {
      --primary: #007AFF;
      --bg: #0d1117;
      --card-bg: #161b22;
      --text: #c9d1d9;
      --text-bold: #f0f6fc;
      --border: #30363d;
      --success: #3fb950;
    }
    body {
      margin: 0;
      padding: 0;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      background-color: var(--bg);
      color: var(--text);
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      box-sizing: border-box;
      padding: 20px;
    }
    .card {
      background-color: var(--card-bg);
      border: 1px solid var(--border);
      border-radius: 16px;
      padding: 32px;
      max-width: 400px;
      width: 100%;
      text-align: center;
      box-shadow: 0 8px 24px rgba(0,0,0,0.3);
    }
    h1 {
      color: var(--text-bold);
      font-size: 20px;
      margin-bottom: 8px;
      font-weight: 600;
    }
    .meta {
      font-size: 13px;
      color: #8b949e;
      margin-bottom: 24px;
    }
    .meta span {
      display: inline-block;
      background-color: #21262d;
      padding: 3px 8px;
      border-radius: 12px;
      margin: 0 4px;
      border: 1px solid var(--border);
    }
    .install-btn {
      display: inline-block;
      background-color: var(--success);
      color: white;
      text-decoration: none;
      font-size: 16px;
      font-weight: bold;
      padding: 14px 28px;
      border-radius: 8px;
      border: none;
      cursor: pointer;
      width: 100%;
      box-sizing: border-box;
      transition: background-color 0.2s ease, transform 0.1s ease;
    }
    .install-btn:active {
      background-color: #2ea043;
      transform: scale(0.98);
    }
    .warning-banner {
      background-color: rgba(248, 81, 73, 0.1);
      border: 1px solid rgba(248, 81, 73, 0.4);
      color: #f85149;
      border-radius: 8px;
      padding: 14px;
      font-size: 12px;
      margin-bottom: 20px;
      text-align: left;
      line-height: 1.5;
    }
    .copy-page-btn {
      display: inline-block;
      background-color: #21262d;
      color: var(--text);
      text-decoration: none;
      font-size: 14px;
      font-weight: bold;
      padding: 12px 24px;
      border-radius: 8px;
      border: 1px solid var(--border);
      cursor: pointer;
      width: 100%;
      box-sizing: border-box;
      margin-top: 12px;
      transition: background-color 0.2s ease;
    }
    .copy-page-btn:active {
      background-color: #30363d;
    }
    .tips {
      margin-top: 24px;
      font-size: 12px;
      color: #8b949e;
      text-align: left;
      line-height: 1.5;
      border-top: 1px solid var(--border);
      padding-top: 16px;
    }
    .tips ol {
      margin: 8px 0 0 0;
      padding-left: 20px;
    }
    .tips li {
      margin-bottom: 6px;
    }
  </style>
  <script>
    function detectSafari() {
      const ua = navigator.userAgent;
      const isIOS = /iPad|iPhone|iPod/.test(ua) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1);
      
      const isChrome = /CriOS/.test(ua);
      const isFirefox = /FxiOS/.test(ua);
      const isEdge = /EdgiOS/.test(ua);
      const isBrave = /Brave/.test(ua) || (navigator.brave && typeof navigator.brave.isBrave === 'function');
      const isInApp = /LINE|FBAN|FBAV|Instagram|Twitter|Slack|MicroMessenger/i.test(ua);
      
      return isIOS && /Safari/.test(ua) && !isChrome && !isFirefox && !isEdge && !isBrave && !isInApp;
    }

    function copyPageUrl() {
      const url = window.location.href;
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(url).then(onSuccess, onFailure);
      } else {
        const textarea = document.createElement('textarea');
        textarea.value = url;
        textarea.style.position = 'fixed';
        document.body.appendChild(textarea);
        textarea.select();
        try {
          document.execCommand('copy');
          onSuccess();
        } catch (err) {
          onFailure();
        }
        document.body.removeChild(textarea);
      }
      
      function onSuccess() {
        const btn = document.getElementById('copy-btn');
        btn.innerText = 'コピー完了！Safariに貼り付けてください';
        btn.style.backgroundColor = '#3fb950';
        btn.style.color = 'white';
        setTimeout(() => {
          btn.innerText = 'Safari用にURLをコピーする';
          btn.style.backgroundColor = '#21262d';
          btn.style.color = 'var(--text)';
        }, 3000);
      }
      
      function onFailure() {
        alert('URLのコピーに失敗しました。ブラウザのアドレスバーから手動でコピーしてください。');
      }
    }

    window.onload = function() {
      const isSafari = detectSafari();
      if (!isSafari) {
        document.getElementById('non-safari-warning').style.display = 'block';
        document.getElementById('copy-btn').style.display = 'block';
      } else {
        setTimeout(function() {
          window.location.href = "${installUrl}";
        }, 1000);
      }
    };
  </script>
</head>
<body>
  <div class="card">
    <div id="non-safari-warning" class="warning-banner" style="display: none;">
      ⚠️ BraveやChromeなどのサードパーティ製ブラウザや、LINE/Slack等のアプリ内ブラウザではiOSアプリをインストールできません。<br>
      URLをコピーして <strong>Safari</strong> で開いてください。
    </div>

    <h1>${appName}</h1>
    <div class="meta">
      <span>Version ${ipaVersion}</span>
      <span>Build #${runCount}</span>
    </div>
    
    <a href="${installUrl}" class="install-btn">インストールを開始する</a>
    <button id="copy-btn" class="copy-page-btn" style="display: none;" onclick="copyPageUrl()">Safari用にURLをコピーする</button>
    
    <div class="tips">
      <strong>💡 インストールできない場合:</strong>
      <ol>
        <li>このページを<strong>Safari</strong>で開いているか確認してください。LINEや他アプリの内蔵ブラウザではインストールが開始されない場合があります。</li>
        <li>「信頼されていないエンタープライズ開発元」と表示された場合は、iOSの「設定」アプリ ＞「一般」 ＞「VPNとデバイス管理」から、開発元の証明書を「信頼」に設定してください。</li>
      </ol>
    </div>
  </div>
</body>
</html>`;

    response.set("Content-Type", "text/html; charset=utf-8");
    response.status(200).send(html);
  } catch (error) {
    logger.error("Failed to generate installOta page", { error, buildJobId });
    response.status(500).send("Internal Server Error");
  }
});
