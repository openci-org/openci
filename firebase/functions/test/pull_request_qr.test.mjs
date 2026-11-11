import assert from "node:assert/strict";
import { test } from "node:test";
import { mkdir, mkdtemp, rm, writeFile } from "node:fs/promises";
import { spawnSync } from "node:child_process";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
  prQrOutputDirectory,
  prQrOutputReady,
  workflowScript,
} from "../../lib/functions/executor/model.js";
import {
  publishPullRequestQrCodes,
  readPullRequestQrCodes,
} from "../../lib/functions/executor/pull_request_qr.js";

const job = {
  id: "job",
  teamId: "team",
  owner: "org",
  repo: "app",
  pullRequestNumber: "3",
  commitSha: "a".repeat(40),
  workflowFileName: "cd.dart",
  workflowName: "IOS CD",
};
const dispatch = {
  id: "test",
  runId: "run-test",
  teamId: "team",
  createdAt: "2026-01-01T00:00:00Z",
};
const link = "https://preview.example.org/build(17)?platform=ios&lang=ja#install";
const signal = new AbortController().signal;

test("only a successful PR workflow with output requests publication", async (t) => {
  const dir = await mkdtemp(join(tmpdir(), "openci-pr-qr-script-"));
  t.after(() => rm(dir, { recursive: true, force: true }));
  const script = workflowScript(job, dispatch, 1, {}).replaceAll(
    prQrOutputDirectory,
    join(dir, "output"),
  );
  for (const [write, status, expected] of [
    [false, 0, 0],
    [true, 0, prQrOutputReady],
    [true, prQrOutputReady, 1],
    [true, 3, 1],
  ]) {
    const stub = `cd() { :; }\nflutter() { if [ "$2" = run ]; then ${write ? 'mkdir -p "$OPENCI_PR_QR_OUTPUT/qr-test"; echo test > "$OPENCI_PR_QR_OUTPUT/qr-test/url";' : ""} return ${status}; fi; }\n`;
    const result = spawnSync("/bin/bash", ["-s"], { input: stub + script, encoding: "utf8" });
    assert.equal(result.status, expected, result.stderr);
  }
  assert.match(
    workflowScript({ ...job, pullRequestNumber: null }, dispatch, 1, {}),
    /OPENCI_PR_QR_OUTPUT=''/,
  );
});

test("collects completed request files and the preview SDK output from the runner", async (t) => {
  const dir = await mkdtemp(join(tmpdir(), "openci-qr-output-"));
  t.after(() => rm(dir, { recursive: true, force: true }));
  await mkdir(join(dir, "qr-1"));
  await mkdir(join(dir, "qr-2"));
  await writeFile(join(dir, "qr-1", "url"), "ja\t120x120\t" + link + "\n");
  await writeFile(
    join(dir, "qr-1", "metadata.json"),
    JSON.stringify({ version: "1.16.2", buildNumber: "3" }),
  );
  await writeFile(join(dir, "qr-2", "pending"), "unfinished");
  await writeFile(join(dir, "legacy"), "https://example.org/previous\n");
  const codes = await readPullRequestQrCodes(
    {
      async exec(_vm, script, output) {
        const result = spawnSync("/bin/bash", ["-s"], {
          input: script.replaceAll(prQrOutputDirectory, dir),
        });
        await output("stdout", result.stdout);
        return result.status;
      },
    },
    "vm",
    signal,
  );
  assert.deepEqual(codes, [
    { url: link, lang: "ja", width: 120, height: 120, version: "1.16.2", buildNumber: "3" },
    { url: "https://example.org/previous", lang: "en", width: 180, height: 180 },
  ]);
});

test("reads per-link language, dimensions and complete web URLs across frames and handles earlier SDK outputs", async () => {
  const read = (data, code = 0) =>
    readPullRequestQrCodes(
      {
        async exec(_vm, _script, output) {
          await output("stderr", Buffer.from("diagnostic"));
          for (const chunk of data) await output("stdout", Buffer.from(chunk));
          return code;
        },
      },
      "vm",
      signal,
    );
  const other = "http://docs.example.com/a%20b";
  assert.deepEqual(
    await read([
      "ja\t120x120\t" + link.slice(0, 4),
      link.slice(4) + "\n",
      "ja\t120x120\t" + link + "\n",
      "ja\t" + link + "\n",
      other + "\n",
      "en\t" + other + "\n",
      "en\t200x150\t" + other + "\n",
    ]),
    [
      { lang: "ja", width: 120, height: 120, url: link },
      { lang: "ja", width: 180, height: 180, url: link },
      { lang: "en", width: 180, height: 180, url: other },
      { lang: "en", width: 200, height: 150, url: other },
    ],
  );
  const full = "https://example.com/".padEnd(2331, "x");
  assert.deepEqual(await read([("en\t1000x1000\t" + full + "\n").repeat(8)]), [
    { lang: "en", width: 1000, height: 1000, url: full },
  ]);
  for (const data of [
    link,
    "fr\t" + link + "\n",
    "ja\ts\t" + link + "\n",
    "ja\t0x180\t" + link + "\n",
    "ja\t180x0\t" + link + "\n",
    "ja\t0180x180\t" + link + "\n",
    "ja\t1001x180\t" + link + "\n",
    "ja\t180x1001\t" + link + "\n",
    "ja\t-10x180\t" + link + "\n",
    "ja\t\t" + link + "\n",
    "ja\tjavascript:alert(1)\n",
    "ja\t120x120\tjavascript:alert(1)\n",
    "ja\thttps://u:secret@example.org/\n",
    "en\thttps://example.org/bad>markup\n",
    "en\thttp:example.org/no-authority\n",
    "en\thttps://example.org\\@other.example/\n",
    "en\thttps://example.org/\ttab\n",
    "en\t180x180\thttps://example.org/\ttab\n",
    "en\t180x180\t" + full + "x\n",
    "x".repeat(25000),
    ("ja\t120x120\t" + link + "\n").repeat(9),
  ]) {
    await assert.rejects(read([data]));
  }
  await assert.rejects(read([link + "\n"], 1));
});

test("bounds and validates release metadata while keeping it paired with its URL", async () => {
  const frame = (urls, metadata) =>
    `openci-qr\t${Buffer.from(urls).toString("base64")}\t${metadata === undefined ? "" : Buffer.from(JSON.stringify(metadata)).toString("base64")}\n`;
  const read = (output) =>
    readPullRequestQrCodes(
      {
        async exec(_vm, _script, receive) {
          for (let i = 0; i < output.length; i += 7)
            await receive("stdout", Buffer.from(output.slice(i, i + 7)));
          return 0;
        },
      },
      "vm",
      signal,
    );
  const url = `ja\t180x180\t${link}\n`;
  assert.deepEqual(await read(frame(url, { version: "1.16.2-日本語", buildNumber: "3.1" })), [
    {
      url: link,
      lang: "ja",
      width: 180,
      height: 180,
      version: "1.16.2-日本語",
      buildNumber: "3.1",
    },
  ]);
  assert.deepEqual(await read(frame(url, { buildNumber: "3" })), [
    { url: link, lang: "ja", width: 180, height: 180, buildNumber: "3" },
  ]);
  for (const metadata of [
    null,
    [],
    "version",
    { version: 123 },
    { buildNumber: null },
    { version: "" },
    { version: " 1.16.2" },
    { buildNumber: "3\n#71" },
    { version: "x".repeat(257) },
    { version: "あ".repeat(86) },
    { ignored: "x".repeat(2048) },
  ])
    await assert.rejects(read(frame(url, metadata)));
  await assert.rejects(read(frame(url + url, { version: "1.16.2" })));
  await assert.rejects(read(frame(url.repeat(9))));
  await assert.rejects(read(frame(url.slice(0, -1), {})));
  await assert.rejects(read("openci-qr\t!!!\t\n"));
  await assert.rejects(read(`openci-qr\t${Buffer.from(url).toString("base64")}\t/w==\n`));
});

function githubFixture() {
  const pr = {
    number: 3,
    state: "open",
    base: { repo: { id: 10 } },
    head: { repo: { id: 10 }, sha: job.commitSha },
  };
  const comments = [];
  const treeInputs = [];
  let tip = null;
  const trees = new Map();
  let counter = 0;
  const otherError = (status) => Object.assign(new Error("GitHub error"), { status });
  const state = {
    conflict: false,
    lostResponse: false,
    deleteBeforeEdit: false,
    pr,
    comments,
    treeInputs,
    writes: [],
  };
  const leases = new Map();
  const withLease = (key, write) => {
    state.onClaim?.(key);
    const done = (leases.get(key) ?? Promise.resolve()).then(() => write(async () => {}));
    leases.set(
      key,
      done.catch(() => {}),
    );
    return done;
  };
  const request = async (route, args) => {
    assert.equal(args.owner, job.owner);
    assert.equal(args.repo, job.repo);
    let data;
    if (route === "GET /repos/{owner}/{repo}")
      data = { id: 10, full_name: "org/app", owner: { id: 4 } };
    else if (route.includes("/pulls/")) data = pr;
    else if (route.startsWith("GET") && route.endsWith("/comments")) {
      assert.equal(args.since, undefined);
      data = comments.slice((args.page - 1) * args.per_page, args.page * args.per_page);
    } else if (route.includes("git/ref/")) {
      assert.equal(args.ref, "heads/genuineci/pr-qr");
      if (!tip) throw otherError(404);
      data = { object: { sha: tip } };
    } else if (route.startsWith("GET") && route.includes("git/commits/"))
      data = { tree: { sha: trees.get(tip) } };
    else if (route.endsWith("/git/trees")) {
      treeInputs.push(args);
      data = { sha: "qr-tree" };
    } else if (route.endsWith("/git/commits")) {
      assert.deepEqual(args.parents, tip ? [tip] : []);
      const sha = (++counter).toString(16).padStart(40, "0");
      trees.set(sha, args.tree);
      data = { sha };
    } else if (route.includes("/git/refs")) {
      if (state.conflict) {
        state.conflict = false;
        tip = "b".repeat(40);
        trees.set(tip, "concurrent-tree");
        throw otherError(422);
      }
      if (tip) assert.equal(args.force, false);
      tip = args.sha;
      data = {};
    } else if (route.startsWith("POST") && route.endsWith("/comments")) {
      assert.equal(args.issue_number, 3);
      await state.beforePost?.();
      state.writes.push("create");
      comments.push({
        id: ++counter,
        user: { type: "Bot" },
        performed_via_github_app: { id: 7 },
        body: args.body,
      });
      if (state.lostResponse) throw otherError(500);
      data = {};
    } else if (route.startsWith("PATCH") && route.includes("/issues/comments/")) {
      const index = comments.findIndex((comment) => comment.id === args.comment_id);
      assert.notEqual(index, -1);
      if (state.deleteBeforeEdit) {
        state.deleteBeforeEdit = false;
        comments.splice(index, 1);
        throw otherError(404);
      }
      state.writes.push("edit");
      comments[index].body = args.body;
      if (state.lostResponse) throw otherError(500);
      data = {};
    } else assert.fail(route);
    return { data };
  };
  return {
    ...state,
    state,
    publish: (
      account = "4",
      codes = [{ url: link, lang: "en", width: 180, height: 180 }],
      run = 17,
      source = job,
    ) => publishPullRequestQrCodes(request, "7", source, account, run, codes, withLease),
  };
}

test("publishes a pinned, repository-local QR and reconciles a raced branch or lost comment response", async () => {
  const f = githubFixture();
  f.state.conflict = true;
  f.state.lostResponse = true;
  f.comments.push({ performed_via_github_app: { id: 9 }, body: "<!-- openci-pr-qr:run-test -->" });
  await f.publish();
  assert.equal(f.treeInputs.length, 2);
  assert.equal(f.treeInputs[1].base_tree, "concurrent-tree");
  const [file] = f.treeInputs[1].tree;
  assert.match(file.content, /^<svg /);
  assert.match(file.content, /fill="white"/);
  assert.equal(f.comments.length, 2);
  assert.ok(f.comments[1].body.includes(`<${link.replaceAll("&", "&amp;")}>`));
  assert.ok(
    f.comments[1].body.includes(
      `<img src="../blob/${"2".padStart(40, "0")}/${file.path}?raw=true" alt="QR code for this link" width="180" height="180">`,
    ),
  );
  assert.match(f.comments[1].body, /Workflow name: `IOS CD`/);
  assert.doesNotMatch(f.comments[1].body, /Run #|Version:|Build number:/);
  assert.match(f.comments[1].body, /:17 -->$/);
  await f.publish();
  assert.equal(f.comments.length, 2);
  assert.deepEqual(f.state.writes, ["create"]);
});

test("later commits edit the same bot comment across pages and replace its URL, image, size and language", async () => {
  const f = githubFixture();
  await f.publish();
  const original = f.comments[0];
  const oldBody = original.body;
  // A copied marker in a human comment or a different app's comment never grants ownership.
  const human = { ...original, id: 90, user: { type: "User" } };
  const otherBot = { ...original, id: 91, performed_via_github_app: { id: 99 } };
  f.comments.unshift(
    human,
    otherBot,
    ...Array.from({ length: 100 }, () => ({ body: "discussion" })),
  );
  f.pr.head.sha = "b".repeat(40);
  const newUrl = "https://example.org/?build=18";
  const source = { ...job, commitSha: f.pr.head.sha };
  f.state.lostResponse = true;
  await f.publish("4", [{ url: newUrl, lang: "ja", width: 120, height: 120 }], 18, source);
  assert.equal(f.comments.length, 103);
  assert.equal(f.comments.at(-1).id, original.id);
  assert.equal(human.body, oldBody);
  assert.equal(otherBot.body, oldBody);
  assert.match(original.body, /ワークフロー名: `IOS CD`/);
  assert.match(original.body, /:18 -->$/);
  assert.ok(original.body.includes(newUrl));
  assert.match(original.body, /width="120" height="120"/);
  assert.ok(!original.body.includes('width="180"'));
  assert.ok(!original.body.includes("build(17)"));
  assert.ok(!original.body.includes("QR code for this link"));
  await f.publish("4", [{ url: newUrl, lang: "ja", width: 120, height: 120 }], 18, source);
  await f.publish("4", [{ url: link, lang: "en", width: 180, height: 180 }], 17, source);
  f.pr.head.sha = job.commitSha;
  await f.publish("4", [{ url: link, lang: "en", width: 180, height: 180 }], 17, job);
  assert.deepEqual(f.state.writes, ["create", "edit"]);
});

test("simultaneous first publications converge on one comment, independently per workflow", async () => {
  const f = githubFixture();
  let unblock, started;
  const firstPost = new Promise((resolve) => {
    started = resolve;
  });
  const gate = new Promise((resolve) => {
    unblock = resolve;
  });
  f.state.beforePost = async () => {
    started();
    await gate;
  };
  const first = f.publish();
  await firstPost;
  const queued = new Promise((resolve) => {
    f.state.onClaim = resolve;
  });
  const second = f.publish(
    "4",
    [{ url: "https://example.org/latest", lang: "ja", width: 180, height: 180 }],
    18,
  );
  await queued;
  assert.deepEqual(f.state.writes, []);
  unblock();
  await Promise.all([first, second]);
  assert.deepEqual(f.state.writes, ["create", "edit"]);
  assert.equal(f.comments.length, 1);
  assert.match(f.comments[0].body, /:18 -->$/);
  await f.publish("4", [{ url: link, lang: "en", width: 180, height: 180 }], 19, {
    ...job,
    workflowFileName: "other.dart",
  });
  assert.equal(f.comments.length, 2);
  assert.match(f.comments[0].body, /:18 -->$/);
  assert.match(f.comments[1].body, /:19 -->$/);
});

test("recreates the comment if it was deleted during the edit", async () => {
  const f = githubFixture();
  await f.publish();
  const deleted = f.comments[0].id;
  f.state.deleteBeforeEdit = true;
  await f.publish("4", [{ url: link, lang: "ja", width: 180, height: 180 }], 18);
  assert.equal(f.comments.length, 1);
  assert.notEqual(f.comments[0].id, deleted);
  assert.match(f.comments[0].body, /ワークフロー名: `IOS CD`/);
  assert.match(f.comments[0].body, /:18 -->$/);
});

test("localizes each language and custom dimensions in a single comment and reuses the image for the same URL", async () => {
  const f = githubFixture();
  const other = "https://download.example.org/a)?stage=dev&copy;=plain#test";
  await f.publish("4", [
    { url: link, lang: "ja", width: 120, height: 120, version: "1.16.2", buildNumber: "3" },
    { url: other, lang: "ja", width: 200, height: 150, version: "1.17.0", buildNumber: "4" },
    { url: link, lang: "en", width: 240, height: 240, version: "1.16.2", buildNumber: "3" },
  ]);
  assert.equal(f.comments.length, 1);
  assert.equal(f.treeInputs[0].tree.length, 2);
  const { body } = f.comments[0];
  assert.ok(body.includes("ワークフロー名: `IOS CD`  \nバージョン: `1.16.2`  \nビルド番号: `3`"));
  assert.ok(body.includes("ワークフロー名: `IOS CD`  \nバージョン: `1.17.0`  \nビルド番号: `4`"));
  assert.ok(body.includes("Workflow name: `IOS CD`  \nVersion: `1.16.2`  \nBuild number: `3`"));
  assert.doesNotMatch(body, /実行 #|Run #|aaaaaaa/);
  assert.ok(
    body.includes(
      '<https://download.example.org/a)?stage=dev&amp;copy;=plain#test>\n\n<img src="../blob/',
    ),
  );
  assert.match(body, /alt="このリンクのQRコード" width="120" height="120">/);
  assert.match(body, /alt="このリンクのQRコード" width="200" height="150">/);
  assert.ok(
    body.includes(
      `<${link.replaceAll("&", "&amp;")}>\n\n<img src="../blob/${"1".padStart(40, "0")}/`,
    ),
  );
  assert.match(body, /alt="QR code for this link" width="240" height="240">/);
});

test("rejects another owner, invalid dimensions, or a non-web URL and skips changed, closed, or fork PRs", async () => {
  const f = githubFixture();
  await assert.rejects(f.publish("999"));
  await assert.rejects(f.publish("4", [{ url: link, lang: "en", width: 0, height: 180 }]));
  await assert.rejects(f.publish("4", [{ url: link, lang: "en", width: 180, height: 1001 }]));
  await assert.rejects(f.publish("4", [{ url: link, lang: "en", width: 180.5, height: 180 }]));
  await assert.rejects(
    f.publish("4", [{ url: "file:///private/path", lang: "en", width: 180, height: 180 }]),
  );
  f.pr.head.sha = "new";
  await f.publish();
  f.pr.head.sha = job.commitSha;
  f.pr.state = "closed";
  await f.publish();
  f.pr.state = "open";
  f.pr.head.repo.id = 11;
  await f.publish();
  assert.equal(f.treeInputs.length, 0);
  assert.equal(f.comments.length, 0);
});

test("refreshes app details on the same comment without displaying the CI sequence", async () => {
  const f = githubFixture();
  const code = {
    url: link,
    lang: "ja",
    width: 180,
    height: 180,
    version: "1.16.2",
    buildNumber: "3",
  };
  await f.publish("4", [code], 71);
  const id = f.comments[0].id;
  assert.match(f.comments[0].body, /ビルド番号: `3`/);
  assert.doesNotMatch(f.comments[0].body.split("<!--")[0], /71|aaaaaaa/);
  await f.publish("4", [{ ...code, version: "1.17.0", buildNumber: "4" }], 72);
  assert.equal(f.comments.length, 1);
  assert.equal(f.comments[0].id, id);
  assert.match(f.comments[0].body, /バージョン: `1\.17\.0`/);
  assert.match(f.comments[0].body, /ビルド番号: `4`/);
  await f.publish("4", [code], 71);
  assert.match(f.comments[0].body, /ビルド番号: `4`/);
  assert.deepEqual(f.state.writes, ["create", "edit"]);
});

test("renders metadata as inline code, with no markup, mentions or PR references", async () => {
  const f = githubFixture();
  const source = { ...job, workflowName: "IOS CD #71 @someone `debug`\nnext" };
  await f.publish(
    "4",
    [{ url: link, lang: "en", width: 180, height: 180, version: "`#72`", buildNumber: "3" }],
    17,
    source,
  );
  assert.ok(f.comments[0].body.includes("Workflow name: ``IOS CD #71 @someone `debug` next``"));
  assert.ok(f.comments[0].body.includes("Version: `` `#72` ``"));
  await assert.rejects(
    f.publish("4", [{ url: link, lang: "en", width: 180, height: 180, buildNumber: "3\n#71" }], 18),
  );
});
