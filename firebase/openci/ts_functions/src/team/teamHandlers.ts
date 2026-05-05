import { randomUUID } from "node:crypto";

import { getAuth } from "firebase-admin/auth";
import { logger } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import {
  addTeamMember,
  createInvitation,
  findExistingPendingInvitation,
  listTeamMembers,
  reinviteInvitation,
} from "../firestoreData";
import { accessSecret } from "../secretManager";
import { verifyTeamMembership } from "./teamAuth";

interface TeamIdRequest {
  teamId: string;
}

interface InviteTeamMemberRequest extends TeamIdRequest {
  email: string;
}

function requireNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.length === 0) {
    throw new HttpsError("invalid-argument", `${field} is required`);
  }
  return value;
}

async function sendEmail({
  to,
  subject,
  html,
}: {
  to: string;
  subject: string;
  html: string;
}): Promise<void> {
  const apiKey = await accessSecret("RESEND_API_KEY");
  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: "OpenCI <noreply@openci.org>",
      to,
      subject,
      html,
    }),
  });
  if (!response.ok) {
    throw new Error(`Failed to send email: ${response.status} ${await response.text()}`);
  }
}

async function sendInvitationEmail({
  to,
  token,
  teamName,
  inviterEmail,
}: {
  to: string;
  token: string;
  teamName: string;
  inviterEmail: string;
}): Promise<void> {
  const inviteUrl = `https://dashboard.openci.org/invite/${token}`;
  await sendEmail({
    to,
    subject: `[OpenCI] You've been invited to join "${teamName}"`,
    html: `
      <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 560px; margin: 0 auto; padding: 40px 20px;">
        <h1 style="font-size: 24px; font-weight: 600; color: #1a1a1a; margin-bottom: 8px;">Welcome to OpenCI</h1>
        <p style="font-size: 16px; color: #4a4a4a; line-height: 1.6;">
          <strong>${inviterEmail}</strong> has invited you to join the <strong>"${teamName}"</strong> team on OpenCI.
        </p>
        <div style="margin: 32px 0;">
          <a href="${inviteUrl}" style="display: inline-block; background-color: #6366f1; color: #ffffff; text-decoration: none; padding: 12px 32px; border-radius: 8px; font-size: 16px; font-weight: 500;">Accept Invitation</a>
        </div>
        <p style="font-size: 14px; color: #888888;">This invitation expires in 7 days.<br/>If you didn't expect this email, you can safely ignore it.</p>
      </div>
    `,
  });
}

async function sendTeamAddedEmail({
  to,
  teamName,
  inviterEmail,
}: {
  to: string;
  teamName: string;
  inviterEmail: string;
}): Promise<void> {
  try {
    await sendEmail({
      to,
      subject: `[OpenCI] You've been added to "${teamName}"`,
      html: `
        <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 560px; margin: 0 auto; padding: 40px 20px;">
          <h1 style="font-size: 24px; font-weight: 600; color: #1a1a1a; margin-bottom: 8px;">You're now a member of "${teamName}"</h1>
          <p style="font-size: 16px; color: #4a4a4a; line-height: 1.6;">
            <strong>${inviterEmail}</strong> has added you to the <strong>"${teamName}"</strong> team on OpenCI.
          </p>
          <div style="margin: 32px 0;">
            <a href="https://dashboard.openci.org" style="display: inline-block; background-color: #6366f1; color: #ffffff; text-decoration: none; padding: 12px 32px; border-radius: 8px; font-size: 16px; font-weight: 500;">Open Dashboard</a>
          </div>
        </div>
      `,
    });
  } catch (error) {
    logger.warn("Failed to send team added email", { to, error });
  }
}

export const getTeamMembers = onCall<TeamIdRequest, Promise<{ members: unknown[] }>>(
  async (request) => {
    const teamId = requireNonEmptyString(request.data?.teamId, "teamId");
    if (!request.auth) throw new HttpsError("unauthenticated", "Unauthenticated");
    const result = await listTeamMembers(
      { teamId },
      { impersonate: { authClaims: request.auth.token } },
    );

    return {
      members: result.data.teamMembers.map((member: { userId: string; user: Record<string, unknown> }) => ({
        uid: member.userId,
        email: member.user.email,
        displayName: member.user.displayName ?? null,
        photoURL: member.user.photoUrl ?? null,
      })),
    };
  },
);

export const inviteTeamMember = onCall<
  InviteTeamMemberRequest,
  Promise<{ status: "added" | "invited"; inviteeUid?: string }>
>(async (request) => {
  const auth = request.auth;
  if (!auth) {
    throw new HttpsError("unauthenticated", "Unauthenticated");
  }

  const teamId = requireNonEmptyString(request.data?.teamId, "teamId");
  const email = requireNonEmptyString(request.data?.email, "email").trim().toLowerCase();
  const teamData = await verifyTeamMembership(auth, teamId);

  const callerUser = await getAuth()
    .getUser(auth.uid)
    .catch(() => undefined);
  const inviterEmail = callerUser?.email ?? "A team member";
  const teamName = typeof teamData.name === "string" ? teamData.name : "";

  const existingUser = await getAuth()
    .getUserByEmail(email)
    .catch(() => undefined);
  if (existingUser) {
    await addTeamMember({ teamId, userId: existingUser.uid, email }).catch((error) => {
      if (String(error).includes("already")) {
        throw new HttpsError("already-exists", "User is already a member of this team");
      }
      throw error;
    });

    await sendTeamAddedEmail({ to: email, teamName, inviterEmail });
    return { status: "added", inviteeUid: existingUser.uid };
  }

  const token = randomUUID();
  const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString();
  const existingInvitations = await findExistingPendingInvitation(
    { email, teamId },
    { impersonate: { authClaims: auth.token } },
  );

  if (existingInvitations.data.invitations.length > 0) {
    await reinviteInvitation(
      {
        id: existingInvitations.data.invitations[0]!.id,
        teamId,
        token,
        expiresAt,
      },
      { impersonate: { authClaims: auth.token } },
    );
  } else {
    await createInvitation(
      {
        email,
        teamId,
        teamNameSnapshot: teamName,
        token,
        expiresAt,
      },
      { impersonate: { authClaims: auth.token } },
    );
  }

  await sendInvitationEmail({ to: email, token, teamName, inviterEmail });
  return { status: "invited" };
});
