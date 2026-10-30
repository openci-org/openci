import * as sdk from "@openci/secrets-admin";
import type { DataConnect } from "firebase-admin/data-connect";
import { SecretError, type SecretStore } from "./service.js";

export class ManagedSecretStore implements SecretStore {
  constructor(readonly dc: DataConnect) {}
  async context(teamId: string, actorUid: string) {
    try {
      return (await sdk.getManagedSecretContext(this.dc, { teamId, actorUid })).data.secrets;
    } catch (error) {
      if (error instanceof Error && error.message.includes("Team access denied"))
        throw new SecretError("permission-denied", "Team access denied");
      throw new Error("Could not read team secrets");
    }
  }
  async commit(
    teamId: string,
    actorUid: string,
    name: string,
    expectedPath: string | null,
    path: string,
  ) {
    await sdk.commitManagedSecret(this.dc, { teamId, actorUid, name, expectedPath, path });
  }
  async rename(
    teamId: string,
    actorUid: string,
    name: string,
    newName: string,
    expectedPath: string,
    path?: string,
  ) {
    await sdk.renameManagedSecret(this.dc, { teamId, actorUid, name, newName, expectedPath, path });
  }
  async remove(teamId: string, actorUid: string, name: string, expectedPath: string) {
    await sdk.deleteManagedSecret(this.dc, { teamId, actorUid, name, expectedPath });
  }
  async queue(path: string) {
    await sdk.queueSecretVersionCleanup(this.dc, { path });
  }
}
