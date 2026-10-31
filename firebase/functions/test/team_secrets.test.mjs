import assert from "node:assert/strict";
import { test } from "node:test";
import { TeamSecrets } from "../../lib/functions/secrets/service.js";
import { validSecretName } from "../../lib/functions/secrets/validation.js";

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
