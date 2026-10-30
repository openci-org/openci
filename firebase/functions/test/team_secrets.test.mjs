import assert from "node:assert/strict";
import { test } from "node:test";
import { createCipheriv, randomBytes } from "node:crypto";
import { TeamSecrets } from "../../lib/functions/secrets/service.js";
import { validSecretName } from "../../lib/functions/secrets/validation.js";
import { decryptLegacySecret } from "../../lib/functions/secrets/migrate.js";

function fixture() {
  const refs = new Map(),
    values = new Map(),
    queued = [];
  let count = 0,
    conflict = false,
    lostAck = false;
  const store = {
    context: async (_, uid) => {
      if (uid !== "member") throw Error("denied");
      return [...refs.values()];
    },
    commit: async (_, __, name, expected, path) => {
      if (conflict || (refs.get(name)?.secretVersionPath ?? null) !== expected)
        throw Error("changed");
      refs.set(name, { name, secretVersionPath: path, createdAt: "1", updatedAt: "2" });
      if (lostAck) throw Error("lost acknowledgement");
    },
    rename: async (_, __, name, next, expected, path) => {
      if (refs.has(next) || refs.get(name)?.secretVersionPath !== expected) throw Error("changed");
      const old = refs.get(name);
      refs.delete(name);
      refs.set(next, { ...old, name: next, secretVersionPath: path ?? expected });
    },
    remove: async (_, __, name, expected) => {
      assert.equal(refs.get(name).secretVersionPath, expected);
      refs.delete(name);
    },
    queue: async (path) => queued.push(path),
  };
  const vault = {
    create: async (_, value) => {
      const path = `version-${++count}`;
      values.set(path, value);
      return path;
    },
    read: async (path) => values.get(path),
  };
  const service = new TeamSecrets(store, vault);
  return {
    refs,
    values,
    queued,
    service,
    conflict: () => (conflict = true),
    lostAck: () => (lostAck = true),
    call: (data) => service.execute("member", { teamId: "team", ...data }),
  };
}

test("values preserve whitespace and metadata never returns paths or values", async () => {
  const f = fixture();
  const value = "  PRIVATE\r\n日本語\n";
  await f.call({ action: "save", name: "TOKEN", value });
  assert.equal((await f.call({ action: "read", name: "TOKEN" })).value, value);
  const listed = JSON.stringify(await f.call({ action: "list" }));
  assert(!listed.includes("version-"));
  assert(!listed.includes("PRIVATE"));
  await f.call({ action: "save", name: "TOKEN", value });
  assert.equal(f.values.size, 1);
});
test("membership rejection happens before accessing Secret Manager", async () => {
  const f = fixture();
  await assert.rejects(
    f.service.execute("outsider", {
      action: "save",
      teamId: "team",
      name: "TOKEN",
      value: "value",
    }),
  );
  assert.equal(f.values.size, 0);
});
test("lost commit acknowledgement is reconciled without overwriting a conflict", async () => {
  const f = fixture();
  f.lostAck();
  await f.call({ action: "save", name: "TOKEN", value: "original" });
  f.conflict();
  await assert.rejects(f.call({ action: "save", name: "TOKEN", value: "conflicting" }), /reload/);
  assert.equal((await f.call({ action: "read", name: "TOKEN" })).value, "original");
  assert(f.queued.includes("version-2"));
});
test("rename with a new value is atomic and conflicts preserve the original", async () => {
  const f = fixture();
  await f.call({ action: "save", name: "FIRST", value: "one" });
  await f.call({ action: "save", name: "SECOND", value: "two" });
  await assert.rejects(
    f.call({ action: "rename", name: "FIRST", newName: "SECOND", value: "new" }),
  );
  assert.equal((await f.call({ action: "read", name: "FIRST" })).value, "one");
  await f.call({ action: "rename", name: "FIRST", newName: "THIRD", value: "three" });
  assert.equal((await f.call({ action: "read", name: "THIRD" })).value, "three");
  assert(!f.refs.has("FIRST"));
});
test("deletion detaches the reference and queues the old version", async () => {
  const f = fixture();
  await f.call({ action: "save", name: "TOKEN", value: "one" });
  await f.call({ action: "delete", name: "TOKEN" });
  await f.call({ action: "delete", name: "TOKEN" });
  assert.equal(f.refs.size, 0);
  assert(f.queued.includes("version-1"));
});
test("certificate creation reuses the existing key and generated names are allowed", async () => {
  const f = fixture();
  await f.call({ action: "generateCertificateKey" });
  await f.call({ action: "generateCertificateKey" });
  assert.equal(f.values.size, 1);
  assert.match([...f.values.values()][0], /^-----BEGIN PRIVATE KEY-----/);
  assert(validSecretName("OPENCI_GENERATED_ASC_KEY_ID"));
  for (const name of ["OPENCI_RUN_ID", "HOME", "PATH", "BASH_ENV", "LOKI_URL"])
    assert(!validSecretName(name));
});
test("legacy AES-GCM migration decrypts exact UTF-8 bytes and rejects wrong keys", () => {
  const key = randomBytes(32),
    iv = randomBytes(12),
    value = "  日本語\r\n\n";
  const cipher = createCipheriv("aes-256-gcm", key, iv);
  const bytes = Buffer.concat([iv, cipher.update(value), cipher.final(), cipher.getAuthTag()]);
  assert.equal(decryptLegacySecret(bytes.toString("base64"), key), value);
  assert.throws(() => decryptLegacySecret(bytes.toString("base64"), randomBytes(32)));
});

test("migration dry run validates every row; apply is repeatable and never replaces a conflict", async () => {
  const { migrateSecrets } = await import("../../lib/functions/secrets/migrate.js");
  const rows = [
    ["team", "TOKEN", "\uFEFF  value\r\n"],
    ["team", "OPENCI_GENERATED_ASC_KEY_ID", "key"],
  ];
  const scan = async (visit) => {
    for (const [team_id, name, value] of rows) await visit({ team_id, name }, value);
  };
  const values = new Map(),
    refs = new Map(),
    queued = [];
  const target = {
    vault: {
      create: async (_, value) => {
        const path = `version-${values.size + 1}`;
        values.set(path, value);
        return path;
      },
      read: async (path) => values.get(path),
    },
    get: async (team, name) => refs.get(`${team}/${name}`),
    queue: async (path) => queued.push(path),
    insert: async (team, name, path) => {
      assert(!refs.has(`${team}/${name}`));
      refs.set(`${team}/${name}`, path);
    },
  };
  assert.deepEqual(await migrateSecrets(scan), { dryRun: true, validated: 2, teams: 1 });
  assert.equal(values.size, 0);
  rows.push(["team", "PATH", "invalid"]);
  await assert.rejects(migrateSecrets(scan, () => target));
  assert.equal(values.size, 0);
  rows.pop();
  assert.equal((await migrateSecrets(scan, () => target)).imported, 2);
  assert.equal((await migrateSecrets(scan, () => target)).unchanged, 2);
  assert.equal(values.size, 2);
  assert.equal(queued.length, 2);
  rows[0][2] = "different";
  await assert.rejects(
    migrateSecrets(scan, () => target),
    /different value/,
  );
  assert.equal(values.get(refs.get("team/TOKEN")), "\uFEFF  value\r\n");
});

test("vault preserves UTF-8 BOM and only destroys owned, unscheduled versions", async () => {
  const { ManagedSecretVault } = await import("../../lib/functions/secrets/vault.js");
  let managed = false,
    state = "ENABLED",
    scheduledDestroyTime,
    destroyed = 0;
  const client = {
    accessSecretVersion: async () => [{ payload: { data: Buffer.from("\uFEFF  value\n") } }],
    getSecret: async () => [{ labels: { "openci-managed": managed ? "true" : "false" } }],
    getSecretVersion: async () => [{ state, scheduledDestroyTime }],
    destroySecretVersion: async () => {
      destroyed++;
    },
  };
  const vault = new ManagedSecretVault("project", client);
  const path = "projects/project/secrets/owned/versions/1";
  assert.equal(await vault.read(path), "\uFEFF  value\n");
  await vault.destroy(path);
  assert.equal(destroyed, 0);
  managed = true;
  await vault.destroy(path);
  assert.equal(destroyed, 1);
  state = "DESTROYED";
  await vault.destroy(path);
  state = "DISABLED";
  scheduledDestroyTime = { seconds: 100 };
  await vault.destroy(path);
  assert.equal(destroyed, 1);
  await assert.rejects(vault.destroy("projects/other/secrets/owned/versions/1"));
});
