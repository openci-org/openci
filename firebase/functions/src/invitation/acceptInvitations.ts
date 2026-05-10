import { logger } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import {
  acceptInvitationAndJoinTeam,
  expireInvitation,
  listMyPendingInvitations,
} from "../firestoreData.js";

export interface AcceptedInvitationTeam {
  teamId: string;
  teamName: string;
}

export interface AcceptInvitationsResponse {
  joinedTeams: AcceptedInvitationTeam[];
  message: string;
}

export const acceptInvitations = onCall<unknown, Promise<AcceptInvitationsResponse>>(
  async (request) => {
    const auth = request.auth;
    if (!auth) {
      throw new HttpsError("unauthenticated", "Sign in required");
    }

    const authClaims = auth.token;
    const email = typeof authClaims.email === "string" ? authClaims.email.trim() : "";
    if (email.length === 0) {
      return {
        joinedTeams: [],
        message: "No email found",
      };
    }

    if (authClaims.email_verified !== true) {
      throw new HttpsError(
        "failed-precondition",
        "A verified email is required to accept invitations",
      );
    }

    const impersonate = { authClaims } as const;
    const invitationsResult = await listMyPendingInvitations({ impersonate });
    const invitations = invitationsResult.data.invitations;

    if (invitations.length === 0) {
      logger.info("No pending invitations found", { uid: auth.uid, email });
      return {
        joinedTeams: [],
        message: "No pending invitations",
      };
    }

    const joinedTeams: AcceptedInvitationTeam[] = [];
    const now = Date.now();

    for (const invitation of invitations) {
      const expiresAt = new Date(invitation.expiresAt);
      if (Number.isNaN(expiresAt.getTime()) || expiresAt.getTime() <= now) {
        await expireInvitation({ id: invitation.id }, { impersonate });
        logger.info("Invitation expired", {
          invitationId: invitation.id,
          uid: auth.uid,
          email,
        });
        continue;
      }

      await acceptInvitationAndJoinTeam(
        { id: invitation.id, teamId: invitation.team.id },
        { impersonate },
      );

      joinedTeams.push({
        teamId: invitation.team.id,
        teamName: invitation.team.name || invitation.teamNameSnapshot,
      });

      logger.info("Invitation accepted during sign-up", {
        invitationId: invitation.id,
        teamId: invitation.team.id,
        uid: auth.uid,
      });
    }

    return {
      joinedTeams,
      message:
        joinedTeams.length === 0 ? "No valid invitations" : `Joined ${joinedTeams.length} team(s)`,
    };
  },
);
