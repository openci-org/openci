import { emailLayout } from "./base-layout";

function escapeHtml(str: string): string {
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

export interface InvitationEmailParams {
  orgName: string;
  role: string;
  inviteLink: string;
}

export function buildInvitationEmail(params: InvitationEmailParams): {
  subject: string;
  html: string;
} {
  const subject = `You've been invited to join ${params.orgName} on OpenCI`;

  const body = `
<h2 style="font-size:18px;margin:0 0 16px;">You're invited to ${escapeHtml(params.orgName)}</h2>
<p style="color:#333;line-height:1.6;">
  You have been invited to join <strong>${escapeHtml(params.orgName)}</strong>
  as a <strong>${escapeHtml(params.role)}</strong>.
</p>
<p style="text-align:center;margin:32px 0;">
  <a href="${escapeHtml(params.inviteLink)}"
     style="background-color:#000;color:#fff;padding:12px 24px;border-radius:6px;text-decoration:none;font-weight:600;">
    Accept Invitation
  </a>
</p>
<p style="color:#666;font-size:14px;">
  Or copy this link: ${escapeHtml(params.inviteLink)}
</p>`;

  const html = emailLayout({
    title: subject,
    body,
    isDevelopment: process.env.NODE_ENV === "development",
  });

  return { subject, html };
}
