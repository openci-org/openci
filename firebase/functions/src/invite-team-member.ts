import { getAuth } from "firebase-admin/auth";
import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/https";
import * as logger from "firebase-functions/logger";

import { db } from "./firebase";
import { invitationsCollectionPath, teamsCollectionPath } from "./firestore-collection-paths";
import { resendApiKey, sendInvitationEmail, sendTeamAddedEmail } from "./send-invitation-email";

export const inviteTeamMember = onCall(
  {
    region: "asia-northeast1",
    secrets: [resendApiKey],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Unauthenticated");
    }

    const callerUid = request.auth.uid;
    const { email, teamId } = request.data as { email: string; teamId: string };

    if (!email || !teamId) {
      throw new HttpsError("invalid-argument", "Missing email or teamId");
    }

    // Validate team exists and caller is a member
    const teamRef = db.collection(teamsCollectionPath).doc(teamId);
    const teamDoc = await teamRef.get();

    if (!teamDoc.exists) {
      throw new HttpsError("not-found", "Team not found");
    }

    const teamData = teamDoc.data()!;
    const members: string[] = teamData.members || [];

    if (!members.includes(callerUid)) {
      throw new HttpsError("permission-denied", "You are not a member of this team");
    }

    // Get caller's email for the invitation message
    const callerRecord = await getAuth().getUser(callerUid);
    const inviterEmail = callerRecord.email ?? "A team member";

    // Check if user already has an OpenCI account
    try {
      const userRecord = await getAuth().getUserByEmail(email);
      const inviteeUid = userRecord.uid;

      // User exists — check if already a member
      if (members.includes(inviteeUid)) {
        throw new HttpsError("already-exists", "User is already a member of this team");
      }

      // Add directly to team
      await teamRef.update({
        members: FieldValue.arrayUnion(inviteeUid),
        updatedAt: FieldValue.serverTimestamp(),
      });

      logger.info(`User ${inviteeUid} added to team ${teamId} by ${callerUid}`);

      // Send notification email (best-effort)
      await sendTeamAddedEmail({
        to: email,
        teamName: teamData.name,
        inviterEmail,
      });

      return { status: "added", inviteeUid };
    } catch (error: any) {
      if (error.code !== "auth/user-not-found") {
        // Re-throw if it's not "user not found" (e.g., already-exists)
        throw error;
      }
    }

    // User does NOT have an account — create a pending invitation

    // Check for existing pending invitation (same email + same team)
    const existingInvitations = await db
      .collection(invitationsCollectionPath)
      .where("email", "==", email)
      .where("teamId", "==", teamId)
      .where("status", "==", "pending")
      .get();

    const token = crypto.randomUUID();
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

    if (!existingInvitations.empty) {
      // Update existing invitation (re-invite: new token, reset expiry)
      const existingDoc = existingInvitations.docs[0];
      await existingDoc.ref.update({
        token,
        invitedBy: callerUid,
        expiresAt,
        updatedAt: FieldValue.serverTimestamp(),
      });

      logger.info(`Re-invited ${email} to team ${teamId} (updated existing invitation)`);
    } else {
      // Create new invitation
      const invitationRef = db.collection(invitationsCollectionPath).doc();
      await invitationRef.set({
        id: invitationRef.id,
        email,
        teamId,
        teamName: teamData.name,
        invitedBy: callerUid,
        token,
        status: "pending",
        createdAt: FieldValue.serverTimestamp(),
        expiresAt,
      });

      logger.info(`Created invitation for ${email} to team ${teamId}`);
    }

    // Send invitation email
    await sendInvitationEmail({
      to: email,
      token,
      teamName: teamData.name,
      inviterEmail,
    });

    return { status: "invited" };
  },
);
