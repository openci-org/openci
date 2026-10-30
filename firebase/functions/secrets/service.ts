import { generateKeyPairSync } from "node:crypto";
import { certificateSecretName, validSecretName, validSecretValue } from "./validation.js";

export class SecretError extends Error {
  constructor(
    readonly code: "invalid-argument" | "permission-denied" | "not-found" | "aborted",
    message: string,
  ) {
    super(message);
  }
}
export interface SecretReference {
  name: string;
  secretVersionPath: string;
  createdAt: string;
  updatedAt: string;
}
export interface SecretStore {
  context(teamId: string, uid: string): Promise<SecretReference[]>;
  commit(
    teamId: string,
    uid: string,
    name: string,
    expected: string | null,
    path: string,
  ): Promise<void>;
  rename(
    teamId: string,
    uid: string,
    name: string,
    newName: string,
    expected: string,
    path?: string,
  ): Promise<void>;
  remove(teamId: string, uid: string, name: string, expected: string): Promise<void>;
  queue(path: string): Promise<void>;
}
export interface SecretVault {
  create(teamId: string, value: string): Promise<string>;
  read(path: string): Promise<string>;
}

export class TeamSecrets {
  constructor(
    readonly store: SecretStore,
    readonly vault: SecretVault,
  ) {}

  async execute(uid: string, input: unknown): Promise<Record<string, unknown>> {
    if (!input || typeof input !== "object" || Array.isArray(input))
      throw new SecretError("invalid-argument", "Invalid request");
    const data = input as Record<string, unknown>;
    const teamId = data.teamId;
    if (typeof teamId !== "string" || !teamId || teamId.length > 255)
      throw new SecretError("invalid-argument", "Invalid team");
    const refs = await this.store.context(teamId, uid);
    if (data.action === "list")
      return { success: true, secrets: refs.map(({ secretVersionPath: _, ...meta }) => meta) };
    const name = data.action === "generateCertificateKey" ? certificateSecretName : data.name;
    if (typeof name !== "string" || !validSecretName(name))
      throw new SecretError("invalid-argument", "Invalid or reserved secret name");
    const previous = refs.find((ref) => ref.name === name);
    if (data.action === "read") {
      if (!previous) throw new SecretError("not-found", "Secret not found");
      return { value: await this.vault.read(previous.secretVersionPath) };
    }
    if (data.action === "delete") {
      if (!previous) return { success: true };
      await this.store.queue(previous.secretVersionPath);
      await this.store.remove(teamId, uid, name, previous.secretVersionPath);
      return { success: true };
    }
    if (data.action === "rename") {
      if (!previous) throw new SecretError("not-found", "Secret not found");
      if (typeof data.newName !== "string" || !validSecretName(data.newName))
        throw new SecretError("invalid-argument", "Invalid or reserved secret name");
      if (data.newName === name)
        throw new SecretError("invalid-argument", "Use save to update the existing name");
      let path: string | undefined;
      if (data.value !== undefined) {
        if (typeof data.value !== "string" || !validSecretValue(data.value))
          throw new SecretError("invalid-argument", "Invalid secret value");
        path = await this.vault.create(teamId, data.value);
        await this.store.queue(path);
        await this.store.queue(previous.secretVersionPath);
      }
      await this.store.rename(teamId, uid, name, data.newName, previous.secretVersionPath, path);
      return { success: true };
    }
    if (data.action !== "save" && data.action !== "generateCertificateKey")
      throw new SecretError("invalid-argument", "Unknown action");
    if (data.action === "generateCertificateKey" && previous) return { success: true };
    if (!previous && refs.length >= 100)
      throw new SecretError("invalid-argument", "Too many team secrets");
    const value =
      data.action === "generateCertificateKey"
        ? generateKeyPairSync("rsa", {
            modulusLength: 2048,
            publicKeyEncoding: { type: "spki", format: "pem" },
            privateKeyEncoding: { type: "pkcs8", format: "pem" },
          }).privateKey
        : data.value;
    if (typeof value !== "string" || !validSecretValue(value))
      throw new SecretError("invalid-argument", "Invalid secret value");
    if (previous && (await this.vault.read(previous.secretVersionPath)) === value)
      return { success: true };
    const path = await this.vault.create(teamId, value);
    // Track both candidates before committing. Cleanup checks live references
    // again and waits a day, so ambiguous writes and active builds stay safe.
    await this.store.queue(path);
    if (previous) await this.store.queue(previous.secretVersionPath);
    try {
      await this.store.commit(teamId, uid, name, previous?.secretVersionPath ?? null, path);
    } catch {
      const current = (await this.store.context(teamId, uid)).find((ref) => ref.name === name);
      if (
        current?.secretVersionPath !== path &&
        !(data.action === "generateCertificateKey" && current)
      ) {
        throw new SecretError("aborted", "Secret changed or could not be saved; reload and retry");
      }
    }
    return { success: true };
  }
}
