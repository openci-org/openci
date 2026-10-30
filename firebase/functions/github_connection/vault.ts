import { randomUUID } from "node:crypto";
import { SecretManagerServiceClient } from "@google-cloud/secret-manager";
import { credential } from "./github.js";

export interface CredentialVault {
  create(value: string): Promise<string>;
  read(path: string): Promise<string>;
  destroy(path: string): Promise<void>;
}

export class GitHubCredentialVault implements CredentialVault {
  constructor(
    readonly project: string,
    readonly client = new SecretManagerServiceClient(),
  ) {
    if (!/^[a-z0-9-]+$/.test(project)) throw new Error("Secret Manager project is missing");
  }
  private name(path: string): string {
    const match =
      /^projects\/([a-z0-9-]+)\/secrets\/(openci-github-[0-9a-f-]{36})\/versions\/([1-9][0-9]*)$/.exec(
        path,
      );
    if (!match || match[1] !== this.project) throw new Error("Invalid GitHub credential reference");
    return path.replace(/\/versions\/[0-9]+$/, "");
  }
  async create(value: string): Promise<string> {
    credential(value);
    const name = `projects/${this.project}/secrets/openci-github-${randomUUID()}`;
    await this.client.createSecret(
      {
        parent: `projects/${this.project}`,
        secretId: name.split("/").at(-1)!,
        secret: {
          replication: { automatic: {} },
          labels: { "openci-purpose": "github-oauth" },
          // Covers process death or a lost response between Secret Manager and FSC.
          // Each FSC request/session is valid for only ten minutes.
          ttl: { seconds: 1800 },
        },
      },
      { timeout: 10000 },
    );
    try {
      const [version] = await this.client.addSecretVersion(
        { parent: name, payload: { data: Buffer.from(value) } },
        { timeout: 10000 },
      );
      const path = version.name!.replace(/^projects\/[^/]+\//, `projects/${this.project}/`);
      if (this.name(path) !== name) throw new Error("Unexpected credential version");
      return path;
    } catch {
      // The secret has its own expiry even if cleanup also fails.
      await this.destroy(`${name}/versions/1`).catch(() => {});
      throw new Error("Could not store GitHub credential");
    }
  }
  async read(path: string): Promise<string> {
    this.name(path);
    const [version] = await this.client.accessSecretVersion({ name: path }, { timeout: 10000 });
    const data = version.payload?.data;
    if (!data) throw new Error("GitHub credential is unavailable");
    return credential(
      new TextDecoder("utf-8", { fatal: true, ignoreBOM: true }).decode(
        typeof data === "string" ? Buffer.from(data, "base64") : data,
      ),
    );
  }
  async destroy(path: string): Promise<void> {
    const name = this.name(path);
    try {
      const [secret] = await this.client.getSecret({ name }, { timeout: 10000 });
      if (secret.labels?.["openci-purpose"] !== "github-oauth")
        throw new Error("Credential is not owned by GitHub OAuth");
      await this.client.deleteSecret({ name }, { timeout: 10000 });
    } catch (error) {
      if ((error as { code?: number }).code !== 5) throw error;
    }
  }
}
