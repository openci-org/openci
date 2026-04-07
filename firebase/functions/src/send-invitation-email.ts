import * as logger from "firebase-functions/logger";
import { Resend } from "resend";
import { defineSecret } from "firebase-functions/params";

const resendApiKey = defineSecret("RESEND_API_KEY");

export { resendApiKey };

interface InvitationEmailParams {
  to: string;
  token: string;
  teamName: string;
  inviterEmail: string;
}

interface TeamAddedEmailParams {
  to: string;
  teamName: string;
  inviterEmail: string;
}

export async function sendInvitationEmail({
  to,
  token,
  teamName,
  inviterEmail,
}: InvitationEmailParams): Promise<void> {
  const resend = new Resend(resendApiKey.value());
  const inviteUrl = `https://dashboard.openci.org/invite/${token}`;

  const { error } = await resend.emails.send({
    from: "OpenCI <noreply@openci.org>",
    to,
    subject: `[OpenCI] You've been invited to join "${teamName}"`,
    html: `
      <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 560px; margin: 0 auto; padding: 40px 20px;">
        <h1 style="font-size: 24px; font-weight: 600; color: #1a1a1a; margin-bottom: 8px;">
          Welcome to OpenCI 🚀
        </h1>
        <p style="font-size: 16px; color: #4a4a4a; line-height: 1.6;">
          <strong>${inviterEmail}</strong> has invited you to join the
          <strong>"${teamName}"</strong> team on OpenCI.
        </p>
        <div style="margin: 32px 0;">
          <a href="${inviteUrl}"
             style="display: inline-block; background-color: #6366f1; color: #ffffff; text-decoration: none; padding: 12px 32px; border-radius: 8px; font-size: 16px; font-weight: 500;">
            Accept Invitation
          </a>
        </div>
        <p style="font-size: 14px; color: #888888;">
          This invitation expires in 7 days.<br/>
          If you didn't expect this email, you can safely ignore it.
        </p>
        <hr style="border: none; border-top: 1px solid #e5e5e5; margin: 32px 0;" />
        <p style="font-size: 12px; color: #aaaaaa;">
          OpenCI — CI/CD for everyone
        </p>
      </div>
    `,
  });

  if (error) {
    logger.error("Failed to send invitation email", { to, error });
    throw new Error(`Failed to send invitation email: ${error.message}`);
  }

  logger.info("Invitation email sent", { to, teamName });
}

export async function sendTeamAddedEmail({
  to,
  teamName,
  inviterEmail,
}: TeamAddedEmailParams): Promise<void> {
  const resend = new Resend(resendApiKey.value());

  const { error } = await resend.emails.send({
    from: "OpenCI <noreply@openci.org>",
    to,
    subject: `[OpenCI] You've been added to "${teamName}"`,
    html: `
      <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 560px; margin: 0 auto; padding: 40px 20px;">
        <h1 style="font-size: 24px; font-weight: 600; color: #1a1a1a; margin-bottom: 8px;">
          You're now a member of "${teamName}" 🎉
        </h1>
        <p style="font-size: 16px; color: #4a4a4a; line-height: 1.6;">
          <strong>${inviterEmail}</strong> has added you to the
          <strong>"${teamName}"</strong> team on OpenCI.
        </p>
        <div style="margin: 32px 0;">
          <a href="https://dashboard.openci.org"
             style="display: inline-block; background-color: #6366f1; color: #ffffff; text-decoration: none; padding: 12px 32px; border-radius: 8px; font-size: 16px; font-weight: 500;">
            Open Dashboard
          </a>
        </div>
        <hr style="border: none; border-top: 1px solid #e5e5e5; margin: 32px 0;" />
        <p style="font-size: 12px; color: #aaaaaa;">
          OpenCI — CI/CD for everyone
        </p>
      </div>
    `,
  });

  if (error) {
    logger.error("Failed to send team added email", { to, error });
    // Don't throw here — user was already added, email is best-effort
  } else {
    logger.info("Team added email sent", { to, teamName });
  }
}
