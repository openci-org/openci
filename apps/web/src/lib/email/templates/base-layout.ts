function escapeHtml(str: string): string {
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

export function emailLayout(options: {
  title: string;
  body: string;
  isDevelopment?: boolean;
}): string {
  const devBanner = options.isDevelopment
    ? `<div style="background-color:#fbbf24;color:#000;text-align:center;padding:8px 16px;font-weight:700;font-size:14px;">&#128679; This is a development environment / &#12371;&#12428;&#12399;&#38283;&#30330;&#29872;&#22659;&#12391;&#12377;</div>`
    : "";

  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>${escapeHtml(options.title)}</title>
</head>
<body style="margin:0;padding:0;background-color:#f4f4f5;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">
${devBanner}
<table width="100%" cellpadding="0" cellspacing="0" style="padding:32px 16px;">
<tr><td align="center">
<table width="600" cellpadding="0" cellspacing="0" style="background:#fff;border-radius:8px;padding:32px;">
<tr><td>
<h1 style="font-size:20px;margin:0 0 24px;">OpenCI</h1>
${options.body}
</td></tr>
</table>
<p style="color:#999;font-size:12px;margin-top:16px;">&copy; OpenCI. All rights reserved.</p>
</td></tr>
</table>
</body>
</html>`;
}
