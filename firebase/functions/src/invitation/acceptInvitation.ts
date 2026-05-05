import { logger } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import {
  acceptInvitationAndJoinTeam,
  expireInvitation,
  getInvitationByToken,
  type InvitationStatus,
} from "../firestoreData";

interface AcceptInvitationRequest {
  token: string;
}

export interface AcceptInvitationResponse {
  status: "accepted";
  teamId: string;
  teamName: string;
}

export const acceptInvitation = onCall<AcceptInvitationRequest, Promise<AcceptInvitationResponse>>(
  async (request) => {
    const auth = request.auth;
    if (!auth) {
      throw new HttpsError("unauthenticated", "Sign in required");
    }
    const authClaims = auth.token;
    if (authClaims.email_verified !== true) {
      throw new HttpsError(
        "failed-precondition",
        "A verified email is required to accept invitations",
      );
    }

    const email = authClaims.email;
    if (!email) {
      throw new HttpsError("failed-precondition", "Account has no email address");
    }

    const token = request.data?.token;
    if (typeof token !== "string" || token.length === 0) {
      throw new HttpsError("invalid-argument", "token is required");
    }

    const impersonate = { authClaims } as const;

    const inviteResult = await getInvitationByToken({ token }, { impersonate });

    const invitation = inviteResult.data.invitations[0];
    if (!invitation) {
      throw new HttpsError("not-found", "Invitation not found or already used");
    }

    if (invitation.email.trim().toLowerCase() !== email.trim().toLowerCase()) {
      throw new HttpsError(
        "permission-denied",
        "This invitation was sent to a different email address",
      );
    }

    const status = invitation.status as InvitationStatus;
    switch (status) {
      case "PENDING":
        break;
      case "ACCEPTED":
        throw new HttpsError("failed-precondition", "Invitation has already been accepted");
      case "EXPIRED":
        throw new HttpsError("deadline-exceeded", "Invitation has expired");
      default: {
        const _exhaustive: never = status;
        throw new HttpsError("internal", `Unhandled invitation status: ${String(_exhaustive)}`);
      }
    }

    const expiresAt = new Date(invitation.expiresAt);
    if (Number.isNaN(expiresAt.getTime()) || expiresAt.getTime() <= Date.now()) {
      await expireInvitation({ id: invitation.id }, { impersonate });

      throw new HttpsError("deadline-exceeded", "Invitation has expired");
    }

    await acceptInvitationAndJoinTeam(
      { id: invitation.id, teamId: invitation.team.id },
      { impersonate },
    );

    logger.info("Invitation accepted", {
      invitationId: invitation.id,
      teamId: invitation.team.id,
      uid: auth.uid,
    });

    return {
      status: "accepted",
      teamId: invitation.team.id,
      teamName: invitation.team.name,
    };
  },
);
