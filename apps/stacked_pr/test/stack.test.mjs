import { test } from "node:test";
import assert from "node:assert/strict";
import { History } from "../lib/history.js";
import { Repository, RestackException } from "../lib/models.js";
import { ordered, planRestack } from "../lib/stack.js";
import { render } from "../lib/report.js";
import { chain, modify, raw, fakeApi } from "./support/fixtures.mjs";

async function discover(pulls) {
  const api = fakeApi({
    list: async (_installation, path) => {
      const branch = new URL(path, "https://example.com").searchParams
        .get("head")
        ?.split(":")
        .at(-1);
      return pulls.filter((p) => !p.isOpen && p.headRef === branch).map((p) => raw(p));
    },
  });
  return new History(api, 1, new Repository(20, "org/repo", "main")).discover(pulls);
}
test("opening child discovers chain and renders positions", async () => {
  const pulls = await discover(chain());
  assert.deepEqual(
    pulls.map((p) => p.parent),
    [undefined, 1, 2],
  );
  const view = render(pulls, pulls[1]);
  assert.match(view.body, /Stack · 2 \/ 3/);
  assert.match(view.body, /#1/);
  assert.match(view.body, /#3/);
  assert.equal(view.conclusion, "action_required");
  assert.equal(render(pulls, pulls[0]).conclusion, "success");
});
test("explicit unrelated retarget detaches edge", async () => {
  const now = chain();
  now[1].baseRef = "release";
  assert.equal((await discover(now))[1].parent, undefined);
});
test("closed unmerged parent is preserved and blocks restack", async () => {
  const now = chain();
  now[0] = modify(now[0], { state: "closed" });
  const graph = await discover(now);
  assert.equal(graph[1].parent, 1);
  await assert.rejects(planRestack(graph, {}), /mergeされず/);
});
test("forks cannot become writable layers", async () => {
  const now = chain();
  now[1] = modify(now[1], { sameRepo: false });
  assert.deepEqual(
    (await discover(now)).map((p) => p.parent),
    [undefined, undefined, undefined],
  );
});
test("branches are ordered while cycles are rejected", async () => {
  const branched = chain();
  branched[2].baseRef = "db";
  assert.deepEqual(
    (await discover(branched)).map((p) => p.parent),
    [undefined, 1, 1],
  );
  const cycle = chain();
  cycle[0].baseRef = "ui";
  const graph = await discover(cycle);
  assert.throws(() => ordered(graph), RestackException);
});
test("titles cannot break Markdown tables or mention users", () => {
  const pulls = chain();
  pulls[1].title = "@everyone | <script>\nhello *bold*";
  const body = render(pulls, pulls[1]).body;
  assert.doesNotMatch(body, /@everyone|<script>/);
  assert.match(body, /&#124;/);
  assert.ok(body.includes("\\*bold\\*"));
});
test("topological order does not depend on API order", () => {
  assert.deepEqual(
    ordered(chain().reverse()).map((p) => p.number),
    [1, 2, 3],
  );
});
