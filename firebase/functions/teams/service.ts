import type { Auth, DecodedIdToken } from "firebase-admin/auth";
import type { GetMyTeamsData } from "@openci/teams-admin";

export class TeamError extends Error {
  constructor(
    readonly code:
      | "invalid-argument"
      | "permission-denied"
      | "not-found"
      | "already-exists"
      | "failed-precondition",
    message: string,
  ) {
    super(message);
  }
}

export interface TeamStore {
  list(claims: DecodedIdToken): Promise<GetMyTeamsData["teams"]>;
  members(teamId: string, claims: DecodedIdToken): Promise<string[]>;
  add(teamId: string, claims: DecodedIdToken, userId: string): Promise<void>;
}

export class TeamManagement {
  constructor(
    readonly store: TeamStore,
    readonly auth: Pick<Auth, "getUsers" | "getUserByEmail">,
  ) {}

  async execute(claims: DecodedIdToken, input: unknown) {
    if (!input || typeof input !== "object" || Array.isArray(input))
      throw new TeamError("invalid-argument", "Invalid team request");
    const data = input as Record<string, unknown>;
    if (data.action === "list") {
      const teams = await this.store.list(claims);
      return {
        success: true,
        teams: teams.map((team) => ({
          id: team.id,
          name: team.name,
          members: team.members.map((member) => member.userId),
          runNumber: Number(team.runNumber),
          createdAt: new Date(Number(team.createdAt) * 1000).toISOString(),
          updatedAt: new Date(Number(team.updatedAt) * 1000).toISOString(),
        })),
      };
    }
    if (data.action !== "members" && data.action !== "add")
      throw new TeamError("invalid-argument", "Unknown team action");
    const teamId = data.teamId;
    if (typeof teamId !== "string" || !teamId.trim() || teamId.length > 255)
      throw new TeamError("invalid-argument", "Invalid team ID");

    // Authorize before looking up any account in Firebase Auth.
    const memberIds = await this.store.members(teamId, claims);
    if (data.action === "add") {
      if (typeof data.email !== "string" || data.email.length > 320)
        throw new TeamError("invalid-argument", "Enter a valid email address");
      const email = data.email.trim().toLowerCase();
      if (!/^[^\s@]+@[^\s@]+$/.test(email))
        throw new TeamError("invalid-argument", "Enter a valid email address");
      const user = await this.auth.getUserByEmail(email).catch((error: unknown) => {
        if ((error as { code?: string })?.code === "auth/user-not-found")
          throw new TeamError("not-found", "The member must first register on the dashboard");
        throw new Error("Could not look up team member");
      });
      if (user.disabled) throw new TeamError("failed-precondition", "This account is disabled");
      // The mutation locks the team and rechecks actor membership and duplicates.
      await this.store.add(teamId, claims, user.uid);
      return { success: true };
    }

    const profiles = new Map<
      string,
      { uid: string; email?: string; displayName?: string; photoURL?: string }
    >();
    // Firebase Auth accepts at most 100 identifiers per request; order is not guaranteed.
    for (let offset = 0; offset < memberIds.length; offset += 100) {
      const result = await this.auth.getUsers(
        memberIds.slice(offset, offset + 100).map((uid) => ({ uid })),
      );
      for (const user of result.users) {
        profiles.set(user.uid, {
          uid: user.uid,
          ...(user.email === undefined ? {} : { email: user.email }),
          ...(user.displayName === undefined ? {} : { displayName: user.displayName }),
          ...(user.photoURL === undefined ? {} : { photoURL: user.photoURL }),
        });
      }
    }
    // Reject a removed caller and omit members removed during the Auth lookup.
    // Deleted Auth accounts still have a removable membership represented by UID.
    const currentIds = await this.store.members(teamId, claims);
    return { success: true, members: currentIds.map((uid) => profiles.get(uid) ?? { uid }) };
  }
}
