import { execFileSync, spawnSync } from "node:child_process";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

export function checkoutFixture(t) {
  const root = mkdtempSync(join(tmpdir(), "openci-checkout-"));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  const source = join(root, "source");
  const vmHome = join(root, "vm");
  const env = {
    PATH: process.env.PATH,
    LC_ALL: "C",
    GIT_CONFIG_GLOBAL: "/dev/null",
    GIT_CONFIG_NOSYSTEM: "1",
    CHECKOUT_TEST_HOME: vmHome,
  };
  mkdirSync(source);
  const git = (...args) => execFileSync("git", args, { cwd: source, env, encoding: "utf8" }).trim();
  git("init", "--quiet", "--initial-branch=main");
  git("config", "user.name", "CI test");
  git("config", "user.email", "ci@example.test");
  return {
    source,
    git,
    checkoutDir: join(vmHome, "openci-build"),
    commit(file, content) {
      writeFileSync(join(source, file), content);
      git("add", "--", file);
      git("commit", "--quiet", "-m", file);
      return git("rev-parse", "HEAD");
    },
    exec(script) {
      return spawnSync("/bin/bash", ["-s"], {
        input: script.replaceAll("/Users/admin", '"$CHECKOUT_TEST_HOME"'),
        env,
        encoding: "utf8",
      });
    },
  };
}
