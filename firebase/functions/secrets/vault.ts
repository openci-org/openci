import { createHash, randomUUID } from "node:crypto";
import { SecretManagerServiceClient } from "@google-cloud/secret-manager";
import { secretUrl } from "../executor/google.js";
import type { SecretVault } from "./service.js";

export class ManagedSecretVault implements SecretVault {
  constructor(
    readonly project: string,
    readonly client = new SecretManagerServiceClient(),
  ) {
    if (!/^[a-z0-9-]+$/.test(project)) throw new Error("Secret Manager project is missing");
  }
  async create(teamId: string, value: string): Promise<string> {
    const team = createHash("sha256").update(teamId).digest("hex").slice(0, 16);
    const [secret] = await this.client.createSecret(
      {
        parent: `projects/${this.project}`,
        secretId: `openci-${team}-${randomUUID()}`,
        secret: {
          replication: { automatic: {} },
          labels: { "openci-managed": "true", team },
          versionDestroyTtl: { seconds: 604800 },
        },
      },
      { timeout: 10000 },
    );
    const [version] = await this.client.addSecretVersion(
      {
        parent: secret.name!,
        payload: { data: Buffer.from(value, "utf8") },
      },
      { timeout: 10000 },
    );
    const path = version.name!.replace(/^projects\/[^/]+\//, `projects/${this.project}/`);
    this.validate(path);
    return path;
  }
  private readonly regional = new Map<string, SecretManagerServiceClient>();
  private clientFor(path: string): SecretManagerServiceClient {
    this.validate(path);
    const region = /^projects\/[^/]+\/locations\/([^/]+)\//.exec(path)?.[1];
    if (!region) return this.client;
    if (!this.regional.has(region))
      this.regional.set(
        region,
        new SecretManagerServiceClient({
          apiEndpoint: `secretmanager.${region}.rep.googleapis.com`,
        }),
      );
    return this.regional.get(region)!;
  }
  validate(path: string) {
    secretUrl(path, this.project);
  }
  async read(path: string): Promise<string> {
    this.validate(path);
    const [version] = await this.clientFor(path).accessSecretVersion(
      { name: path },
      { timeout: 10000 },
    );
    const bytes = version.payload?.data;
    if (!bytes) throw new Error("Secret value is unavailable");
    return new TextDecoder("utf-8", { fatal: true, ignoreBOM: true }).decode(
      typeof bytes === "string" ? Buffer.from(bytes, "base64") : bytes,
    );
  }
  async close(): Promise<void> {
    await Promise.all([
      this.client.close(),
      ...[...this.regional.values()].map((client) => client.close()),
    ]);
  }
  async destroy(path: string): Promise<void> {
    this.validate(path);
    try {
      const client = this.clientFor(path);
      const [secret] = await client.getSecret(
        { name: path.replace(/\/versions\/[0-9]+$/, "") },
        { timeout: 10000 },
      );
      // References imported by other integrations are not ours to destroy.
      if (secret.labels?.["openci-managed"] !== "true") return;
      const [version] = await client.getSecretVersion({ name: path }, { timeout: 10000 });
      if (version.state === "DESTROYED" || version.state === 3 || version.scheduledDestroyTime)
        return;
      await client.destroySecretVersion({ name: path }, { timeout: 10000 });
    } catch (error) {
      if ((error as { code?: number }).code !== 5) throw error;
    }
  }
}
