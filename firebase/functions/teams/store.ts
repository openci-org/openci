import type { DecodedIdToken } from "firebase-admin/auth";
import type { DataConnect } from "firebase-admin/data-connect";
import * as sdk from "@openci/teams-admin";
import { TeamError, type TeamStore } from "./service.js";

export class ManagedTeamStore implements TeamStore {
  constructor(readonly dc: DataConnect) {}

  async list(claims: DecodedIdToken) {
    return (await sdk.getMyTeams(this.dc, { impersonate: { authClaims: claims } })).data.teams;
  }

  async members(teamId: string, claims: DecodedIdToken) {
    const { data } = await sdk.getTeamMembers(
      this.dc,
      { teamId },
      { impersonate: { authClaims: claims } },
    );
    if (!data.team) throw new TeamError("permission-denied", "Team access denied");
    return data.team.members.map((member) => member.userId);
  }

  async add(teamId: string, claims: DecodedIdToken, userId: string) {
    try {
      await sdk.addTeamMember(this.dc, { teamId, actorUid: claims.uid, userId });
    } catch {
      // SDK messages include operation source with unrelated @check messages.
      // Read the current authorized state instead of parsing those messages.
      const members = await this.members(teamId, claims);
      if (members.includes(userId))
        throw new TeamError("already-exists", "User is already a team member");
      throw new Error("Could not add team member");
    }
  }
}
