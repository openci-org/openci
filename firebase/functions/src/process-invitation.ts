import { FieldValue } from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";
import { onCall, HttpsError } from "firebase-functions/https";
import { beforeUserCreated } from "firebase-functions/identity";

import { db } from "./firebase";
import { invitationsCollectionPath, teamsCollectionPath, usersCollectionPath } from "./firestore-collection-paths";

/**
 * Triggered when a new user signs up via Firebase Auth.
 * Checks for pending invitations matching the user's email and
 * automatically adds them to the invited teams.
 */
export const processInvitationsOnSignUp = beforeUserCreated(
  { region: "asia-northeast1" },
  async (event) => {
    const user = event.data;
    if (!user) return;

    const email = user.email;
    if (!email) return;

    const pendingInvitations = await db
      .collection(invitationsCollectionPath)
      .where("email", "==", email)
      .where("status", "==", "pending")
      .get();

    if (pendingInvitations.empty) {
      logger.info(`No pending invitations found for ${email}`);
      return;
    }

    const uid = user.uid;
    const now = new Date();

    for (const doc of pendingInvitations.docs) {
      const invitation = doc.data();

      // Check expiration
      const expiresAt = invitation.expiresAt instanceof Date
        ? invitation.expiresAt
        : invitation.expiresAt.toDate();

      if (expiresAt < now) {
        await doc.ref.update({ status: "expired" });
        logger.info(`Invitation ${doc.id} expired for ${email}`);
        continue;
      }

      // Add user to team
      const teamRef = db.collection(teamsCollectionPath).doc(invitation.teamId);
      const teamDoc = await teamRef.get();
      if (!teamDoc.exists) {
        logger.warn(`Team ${invitation.teamId} not found, skipping invitation ${doc.id}`);
        await doc.ref.update({ status: "expired" });
        continue;
      }

      await teamRef.update({
        members: FieldValue.arrayUnion(uid),
        updatedAt: FieldValue.serverTimestamp(),
      });

      // Mark invitation as accepted
      await doc.ref.update({
        status: "accepted",
        acceptedAt: FieldValue.serverTimestamp(),
        acceptedBy: uid,
      });

      logger.info(`User ${uid} (${email}) auto-joined team ${invitation.teamId} via invitation ${doc.id}`);
    }
  },
);

/**
 * Callable function to accept an invitation by token.
 * Used when an existing logged-in user clicks an invite link.
 */
export const acceptInvitation = onCall(
  { region: "asia-northeast1" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Unauthenticated");
    }

    const { token } = request.data as { token: string };
    if (!token) {
      throw new HttpsError("invalid-argument", "Missing token");
    }

    const uid = request.auth.uid;
    const userEmail = request.auth.token.email;

    // Find invitation by token
    const invitationQuery = await db
      .collection(invitationsCollectionPath)
      .where("token", "==", token)
      .where("status", "==", "pending")
      .limit(1)
      .get();

    if (invitationQuery.empty) {
      throw new HttpsError("not-found", "Invitation not found or already used");
    }

    const invitationDoc = invitationQuery.docs[0];
    const invitation = invitationDoc.data();

    // Verify email matches
    if (invitation.email !== userEmail) {
      throw new HttpsError(
        "permission-denied",
        "This invitation was sent to a different email address",
      );
    }

    // Check expiration
    const expiresAt = invitation.expiresAt instanceof Date
      ? invitation.expiresAt
      : invitation.expiresAt.toDate();

    if (expiresAt < new Date()) {
      await invitationDoc.ref.update({ status: "expired" });
      throw new HttpsError("deadline-exceeded", "This invitation has expired");
    }

    // Check team exists
    const teamRef = db.collection(teamsCollectionPath).doc(invitation.teamId);
    const teamDoc = await teamRef.get();
    if (!teamDoc.exists) {
      throw new HttpsError("not-found", "Team not found");
    }

    // Check if already a member
    const teamData = teamDoc.data()!;
    const members: string[] = teamData.members || [];
    if (members.includes(uid)) {
      // Already a member, just mark invitation as accepted
      await invitationDoc.ref.update({
        status: "accepted",
        acceptedAt: FieldValue.serverTimestamp(),
        acceptedBy: uid,
      });
      return { status: "already_member", teamId: invitation.teamId, teamName: invitation.teamName };
    }

    // Add user to team
    await teamRef.update({
      members: FieldValue.arrayUnion(uid),
      updatedAt: FieldValue.serverTimestamp(),
    });

    // Mark invitation as accepted
    await invitationDoc.ref.update({
      status: "accepted",
      acceptedAt: FieldValue.serverTimestamp(),
      acceptedBy: uid,
    });

    // Update user's selectedTeamId to the newly joined team
    await db.collection(usersCollectionPath).doc(uid).update({
      selectedTeamId: invitation.teamId,
      updatedAt: FieldValue.serverTimestamp(),
    });

    logger.info(`User ${uid} accepted invitation to team ${invitation.teamId}`);

    return { status: "accepted", teamId: invitation.teamId, teamName: invitation.teamName };
  },
);
