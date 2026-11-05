import { test } from "node:test";
import assert from "node:assert/strict";
import { squashReadiness } from "../lib/squash.js";
import { Repository } from "../lib/models.js";
import { chain, fakeApi } from "./support/fixtures.mjs";

const repo = new Repository(20, "org/repo", "main"),
  app = { id: 7 };
function fixture() {
  const pr = chain()[1];
  const state = {
    checks: [
      { app, external_id: "stacked-pr:20:2", status: "completed", conclusion: "action_required" },
      { app: { id: 42 }, status: "completed", conclusion: "success" },
    ],
    statuses: [],
    reviews: [{ user: { login: "reviewer" }, state: "APPROVED", commit_id: pr.head }],
  };
  const api = fakeApi({
    request: async (_i, _method, _path, body) => ({
      ...(state.errors ? { errors: state.errors } : {}),
      data: {
        repository: {
          object: {
            oid: body.variables.head,
            statusCheckRollup: {
              contexts: state.pages
                ? state.pages[body.variables.cursor === null ? 0 : 1]
                : {
                    nodes: state.statuses.map((s) => ({ __typename: "StatusContext", ...s })),
                    pageInfo: { hasNextPage: false },
                  },
            },
          },
        },
      },
    }),
    list: async (_i, path) =>
      path.includes("check-runs")
        ? state.checks
        : path.endsWith("reviews")
          ? state.reviews
          : state.statuses,
  });
  state.ready = () => squashReadiness(api, 10, repo, pr, app);
  return state;
}
test("dependency waiting does not mask successful CI and approval on a child", async () => {
  assert.equal(await fixture().ready(), undefined);
});

test("a failing legacy status on a later GraphQL page is not skipped", async () => {
  const f = fixture();
  f.pages = [
    { nodes: [{ __typename: "CheckRun" }], pageInfo: { hasNextPage: true, endCursor: "next" } },
    {
      nodes: [{ __typename: "StatusContext", context: "legacy", state: "FAILURE" }],
      pageInfo: { hasNextPage: false },
    },
  ];
  assert.match(await f.ready(), /CI待ち/);
});

test("GraphQL permission errors and incomplete pages cannot authorize a squash", async () => {
  const f = fixture();
  f.errors = [{ type: "FORBIDDEN" }];
  await assert.rejects(f.ready(), /status unavailable/);
  f.errors = undefined;
  f.pages = [{ nodes: [], pageInfo: { hasNextPage: true } }];
  await assert.rejects(f.ready(), /Incomplete CI status page/);
});
for (const conclusion of ["failure", "cancelled", "timed_out", "action_required"])
  test(`CI ${conclusion} prevents stack preparation`, async () => {
    const f = fixture();
    f.checks[1].conclusion = conclusion;
    assert.match(await f.ready(), /CI待ち/);
  });
test("the dependency Check itself must not have failed", async () => {
  const f = fixture();
  f.checks[0].conclusion = "failure";
  await assert.rejects(f.ready(), /Stacked PR/);
});
test("missing or queued CI and approval on an older commit do not authorize preparation", async () => {
  const f = fixture();
  f.checks.length = 1;
  assert.match(await f.ready(), /CI待ち/);
  f.statuses = [{ context: "legacy", state: "success" }];
  f.reviews[0].commit_id = "f".repeat(40);
  assert.match(await f.ready(), /承認待ち/);
});
test("the latest status and review per context or person override older decisions", async () => {
  const f = fixture();
  f.statuses = [
    { context: "legacy", state: "failure" },
    { context: "legacy", state: "success" },
  ];
  assert.match(await f.ready(), /CI待ち/);
  f.statuses.reverse();
  f.reviews.push({ ...f.reviews[0], state: "CHANGES_REQUESTED" });
  assert.match(await f.ready(), /承認待ち/);
  f.reviews.push({ ...f.reviews[0] });
  assert.equal(await f.ready(), undefined);
});
