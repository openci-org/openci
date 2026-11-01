import { test } from "node:test";
import assert from "node:assert/strict";
import { verify } from "node:crypto";
import { readFileSync } from "node:fs";
import { GitHubApi, ApiException } from "../lib/github.js";
import { Repository, RetryException } from "../lib/models.js";
import { configFromEnvironment } from "../lib/config.js";
import { config, testKey } from "./support/fixtures.mjs";

const response = (body, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { "content-type": "application/json" } });
const token = (value) => ({
  token: value,
  expires_at: new Date(Date.now() + 3600_000).toISOString(),
  permissions: {},
  repository_selection: "all",
});
test("Octokit App JWT has a verifiable RSA signature and bounded lifetime", async () => {
  const api = new GitHubApi(config(), {
    fetch: async (_url, options) => {
      const jwt = options.headers.authorization.replace(/^bearer /i, ""),
        [header, payload, signature] = jwt.split(".");
      assert.equal(JSON.parse(Buffer.from(header, "base64url")).alg, "RS256");
      const key = readFileSync(new URL("./fixtures/test_public_key.txt", import.meta.url));
      assert.equal(
        verify(
          "RSA-SHA256",
          Buffer.from(`${header}.${payload}`),
          key,
          Buffer.from(signature, "base64url"),
        ),
        true,
      );
      const claims = JSON.parse(Buffer.from(payload, "base64url"));
      assert.equal(String(claims.iss), "7");
      assert.ok(claims.exp > Date.now() / 1000 && claims.exp - claims.iat <= 600);
      return response({ id: 7 });
    },
  });
  assert.equal((await api.identity()).id, 7);
});
test("GHES pagination stays on configured origin with redirects disabled and token caching", async () => {
  const urls = [];
  const api = new GitHubApi(config(), {
    fetch: async (input, options) => {
      const url = new URL(input);
      urls.push(url);
      assert.equal(options.redirect, "error");
      if (url.pathname.endsWith("/access_tokens")) return response(token("fake-token"));
      assert.equal(options.headers.authorization, "Bearer fake-token");
      return response(
        url.searchParams.get("page") === "1"
          ? Array.from({ length: 100 }, (_, id) => ({ id }))
          : [{ id: 100 }],
      );
    },
  });
  assert.equal((await api.list(1, "/repos/org/repo/pulls?state=open")).length, 101);
  assert.ok(urls.every((u) => u.toString().startsWith("https://git.example.com/api/v3/")));
  assert.equal(urls.filter((u) => u.pathname.endsWith("/access_tokens")).length, 1);
});
test("401 refreshes installation token once; errors never retain credential-bearing SDK responses", async () => {
  let tokens = 0,
    requests = 0,
    fail = false;
  const api = new GitHubApi(config(), {
    fetch: async (url) => {
      if (fail) return response("sensitive credentials", 403);
      if (String(url).endsWith("/access_tokens")) return response(token(`token-${++tokens}`));
      return ++requests === 1 ? response("sensitive body", 401) : response({ ok: true });
    },
  });
  assert.deepEqual(await api.request(1, "GET", "/test"), { ok: true });
  assert.equal(tokens, 2);
  assert.equal(requests, 2);
  fail = true;
  await assert.rejects(api.raw("token", "GET", "/forbidden"), (error) => {
    assert.ok(error instanceof ApiException);
    assert.doesNotMatch(String(error), /sensitive/);
    assert.equal(error.request, undefined);
    assert.equal(error.response, undefined);
    return true;
  });
});
test("GHES GraphQL follows cursors and rejects partial results", async () => {
  const seen = [];
  let fail = false;
  const api = new GitHubApi(config(), {
    fetch: async (url, options) => {
      if (String(url).endsWith("/access_tokens")) return response(token("test"));
      assert.equal(String(url), "https://git.example.com/api/graphql");
      const { query, variables } = JSON.parse(options.body);
      assert.match(query, /AUTOMATIC_BASE_CHANGE_SUCCEEDED_EVENT/);
      assert.match(
        query,
        /\.\.\. on AutomaticBaseChangeSucceededEvent \{ createdAt oldBase newBase \}/,
      );
      seen.push(variables.cursor);
      return response(
        fail
          ? { errors: [{ message: "unavailable" }], data: {} }
          : {
              data: {
                repository: {
                  pullRequest: {
                    timelineItems: {
                      nodes: [
                        {
                          __typename: "HeadRefForcePushedEvent",
                          beforeCommit: { oid: "a".repeat(40) },
                          afterCommit: { oid: "b".repeat(40) },
                        },
                      ],
                      pageInfo: { hasNextPage: variables.cursor === null, endCursor: "cursor-1" },
                    },
                  },
                },
              },
            },
      );
    },
  });
  const repo = new Repository(20, "org/repo");
  assert.equal((await api.timeline(1, repo, 2)).length, 2);
  assert.deepEqual(seen, [null, "cursor-1"]);
  fail = true;
  await assert.rejects(api.timeline(1, repo, 2), RetryException);
});
test("batched histories include every PR and every page and reject partial results", async () => {
  let batches = 0,
    fail = false;
  const items = (n, more = false, second = false) => ({
    timelineItems: {
      nodes: [{ __typename: "BaseRefChangedEvent", previousRefName: `${n}-${second ? 2 : 1}` }],
      pageInfo: { hasNextPage: more, endCursor: more ? "next" : null },
    },
  });
  const api = new GitHubApi(config(), {
    fetch: async (url, options) => {
      if (String(url).endsWith("/access_tokens")) return response(token("test"));
      const { query, variables } = JSON.parse(options.body);
      if (query.includes("query StackHistories")) {
        assert.match(query, /AUTOMATIC_BASE_CHANGE_SUCCEEDED_EVENT/);
        assert.match(
          query,
          /\.\.\. on AutomaticBaseChangeSucceededEvent \{ createdAt oldBase newBase \}/,
        );
        batches++;
        const numbers = [...query.matchAll(/pr(\d+): pullRequest/g)].map((m) => Number(m[1]));
        return response({
          ...(fail ? { errors: [{ message: "incomplete" }] } : {}),
          data: {
            repository: Object.fromEntries(numbers.map((n) => [`pr${n}`, items(n, n === 2)])),
          },
        });
      }
      assert.equal(variables.number, 2);
      return response({
        data: {
          repository: {
            pullRequest: items(2, variables.cursor === null, variables.cursor !== null),
          },
        },
      });
    },
  });
  const repo = new Repository(20, "org/repo"),
    numbers = Array.from({ length: 21 }, (_, i) => i + 1),
    histories = await api.timelines(1, repo, numbers);
  assert.deepEqual([...histories.keys()], numbers);
  assert.deepEqual(
    histories.get(2).map((e) => e.previousRefName),
    ["2-1", "2-2"],
  );
  assert.equal(histories.get(21)[0].previousRefName, "21-1");
  assert.equal(batches, 2);
  fail = true;
  await assert.rejects(api.timelines(1, repo, [1]), RetryException);
});
test("configuration validates GitHub origins, keys and options", () => {
  const env = {
    GITHUB_URL: "https://git.example.com/",
    GITHUB_APP_ID: "7",
    GITHUB_APP_PRIVATE_KEY: testKey,
  };
  assert.equal(configFromEnvironment(env, ".").apiUrl, "https://git.example.com/api/v3");
  assert.equal(
    configFromEnvironment({ ...env, GITHUB_URL: "https://github.com" }, ".").apiUrl,
    "https://api.github.com",
  );
  for (const invalid of [
    "http://git.example.com",
    "https://user:pass@git.example.com",
    "https://git.example.com/path",
  ])
    assert.throws(() => configFromEnvironment({ ...env, GITHUB_URL: invalid }, "."));
  assert.throws(() => configFromEnvironment({ ...env, AUTO_RESTACK: "yes" }, "."));
});
