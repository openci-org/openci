import { test } from "node:test";
import assert from "node:assert/strict";
import { setImmediate } from "node:timers/promises";
import { History } from "../lib/history.js";
import { PullRequest, Repository } from "../lib/models.js";
import { chain, fakeApi, modify, raw } from "./support/fixtures.mjs";

test("independent root lookups overlap without duplicating shared parents or unbounding requests", async () => {
  const template = chain()[0];
  const current = Array.from({ length: 10 }, (_, index) =>
    modify(template, {
      number: index + 1,
      headRef: `child-${index}`,
      baseRef: `release-${index % 9}`,
    }),
  );
  const parent = new PullRequest({
    ...template,
    number: 100,
    headRef: "release-0",
    state: "closed",
    merged: true,
  });
  const requests = [];
  let active = 0,
    peak = 0;
  const api = fakeApi({
    list: async (_installation, path) => {
      const branch = new URL(path, "https://git.example.com").searchParams
        .get("head")
        .split(":")[1];
      requests.push(branch);
      peak = Math.max(peak, ++active);
      await setImmediate();
      active--;
      return branch === parent.headRef ? [raw(parent)] : [];
    },
  });

  const discovered = await new History(api, 1, new Repository(20, "org/repo", "main")).discover(
    current,
  );

  assert.ok(peak > 1 && peak <= 4);
  assert.equal(requests.length, 9);
  assert.equal(new Set(requests).size, 9);
  assert.equal(discovered.length, 11);
  assert.equal(discovered.find((pr) => pr.number === 1).parent, 100);
  assert.equal(discovered.find((pr) => pr.number === 10).parent, 100);
  assert.ok(discovered.filter((pr) => pr.number > 1 && pr.number < 10).every((pr) => !pr.parent));
});
