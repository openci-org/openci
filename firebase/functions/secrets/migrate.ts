// One-off operator tool. Dry run is the default; never prints decrypted values.
import { createDecipheriv } from "node:crypto";
import { initializeApp, deleteApp, getApps } from "firebase-admin/app";
import { Client, type QueryResult } from "pg";
import * as sdk from "@openci/secrets-admin";
import { isolatedConnector } from "../executor/store.js";
import { ManagedSecretVault } from "./vault.js";
import { validSecretName, validSecretValue } from "./validation.js";

export function decryptLegacySecret(ciphertext: string, key: Buffer): string {
  const bytes = Buffer.from(ciphertext, "base64");
  if (key.length !== 32 || bytes.length < 28) throw new Error("Invalid encrypted secret");
  const decipher = createDecipheriv("aes-256-gcm", key, bytes.subarray(0, 12));
  decipher.setAuthTag(bytes.subarray(-16));
  return new TextDecoder("utf8", { fatal: true, ignoreBOM: true }).decode(
    Buffer.concat([decipher.update(bytes.subarray(12, -16)), decipher.final()]),
  );
}

type ScanSecrets = (
  visit: (row: { team_id: string; name: string }, value: string) => Promise<void>,
) => Promise<void>;
interface Destination {
  vault: {
    create(teamId: string, value: string): Promise<string>;
    read(path: string): Promise<string>;
  };
  get(teamId: string, name: string): Promise<string | undefined>;
  queue(path: string): Promise<void>;
  insert(teamId: string, name: string, path: string): Promise<void>;
}

export async function migrateSecrets(scan: ScanSecrets, destination?: () => Destination) {
  const budgets = new Map<string, { count: number; bytes: number }>();
  let validated = 0;
  // Validate the entire stable snapshot before making any destination writes.
  await scan(async (row, value) => {
    if (!row.team_id || !validSecretName(row.name) || !validSecretValue(value))
      throw new Error("A legacy secret cannot be used by the executor");
    const budget = budgets.get(row.team_id) ?? { count: 0, bytes: 0 };
    budget.count++;
    budget.bytes += Buffer.byteLength(value);
    if (budget.count > 100 || budget.bytes > 512 * 1024)
      throw new Error("A team exceeds the executor secret limits");
    budgets.set(row.team_id, budget);
    validated++;
  });
  if (!destination) return { dryRun: true, validated, teams: budgets.size };
  const target = destination();
  let imported = 0,
    unchanged = 0;
  await scan(async (row, value) => {
    const current = await target.get(row.team_id, row.name);
    if (current) {
      if ((await target.vault.read(current)) !== value)
        throw new Error("Destination contains a different value; resolve before retrying");
      unchanged++;
      return;
    }
    const path = await target.vault.create(row.team_id, value);
    await target.queue(path);
    await target.insert(row.team_id, row.name, path);
    if (
      (await target.get(row.team_id, row.name)) !== path ||
      (await target.vault.read(path)) !== value
    )
      throw new Error("Verification failed");
    imported++;
  });
  return { dryRun: false, validated, imported, unchanged };
}

async function main() {
  const apply = process.argv.includes("--apply");
  const project = process.env.SECRET_MANAGER_PROJECT;
  const databaseUrl = process.env.LEGACY_DATABASE_URL;
  const key = Buffer.from(process.env.LEGACY_SECRET_ENCRYPTION_KEY ?? "", "base64");
  if (!project || !databaseUrl || key.length !== 32)
    throw new Error("Missing migration configuration");
  const db = new Client({ connectionString: databaseUrl });
  let vault: ManagedSecretVault | undefined;
  await db.connect();
  try {
    await db.query("BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY");
    const scan = async (
      visit: (row: { team_id: string; name: string }, value: string) => Promise<void>,
    ) => {
      let team: string | null = null,
        name: string | null = null;
      for (;;) {
        const page: QueryResult<{ team_id: string; name: string; encrypted_value: string }> =
          await db.query<{ team_id: string; name: string; encrypted_value: string }>(
            "SELECT team_id, name, encrypted_value FROM secrets WHERE ($1::text IS NULL OR (team_id, name) > ($1, $2)) ORDER BY team_id, name LIMIT 100",
            [team, name],
          );
        if (!page.rows.length) break;
        for (const row of page.rows) {
          await visit(row, decryptLegacySecret(row.encrypted_value, key));
          team = row.team_id;
          name = row.name;
        }
      }
    };
    const result = await migrateSecrets(
      scan,
      apply
        ? () => {
            initializeApp({ projectId: project });
            const dc = isolatedConnector(sdk.connectorConfig);
            vault = new ManagedSecretVault(project);
            return {
              vault,
              get: async (teamId, name) =>
                (await sdk.getSecretReference(dc, { teamId, name })).data.secretReference
                  ?.secretVersionPath,
              queue: async (path) => {
                await sdk.queueSecretVersionCleanup(dc, { path });
              },
              insert: async (teamId, name, path) => {
                await sdk.createSecretReference(dc, { teamId, name, secretVersionPath: path });
              },
            };
          }
        : undefined,
    );
    process.stdout.write(JSON.stringify(result) + "\n");
  } finally {
    key.fill(0);
    await Promise.all([db.end(), vault?.close(), ...getApps().map((app) => deleteApp(app))]);
  }
}

// Importing the decryption helper in tests must never connect to a database.
if (process.argv[1]?.replaceAll("\\", "/").endsWith("/secrets/migrate.js")) {
  main().catch(() => {
    process.stderr.write(
      "Secret migration stopped. No existing destination values were overwritten. Check configuration and retry the dry run.\n",
    );
    process.exitCode = 1;
  });
}
