import assert from "node:assert/strict";
import { generateKeyPairSync } from "node:crypto";
import { test } from "node:test";
import {
  functionsCdCredential,
  functionsCdEnvironment,
  functionsCdSecretReferences,
} from "../../lib/functions/executor/functions_cd_secrets.js";
import { ExecutionGitHub } from "../../lib/functions/executor/github.js";

const job = {
  teamId: "trusted-team",
  installationId: "456",
  repositoryId: "123",
  owner: "openci-org",
  repo: "openci",
  tagName: "v2.6.0",
  branch: "refs/tags/v2.6.0",
  workflowFileName: "firebase_functions_cd.dart",
  commitSha: "a".repeat(40),
  pullRequestNumber: null,
};
const checkout = {
  event: "push",
  branch: job.branch,
  commitSha: job.commitSha,
  checkoutSha: job.commitSha,
};
const environment = {
  OPENCI_FUNCTIONS_CD_TEAM_ID: "trusted-team",
  OPENCI_FUNCTIONS_CD_REPOSITORY_ID: "123",
  OPENCI_FUNCTIONS_CD_SA_VERSION: "projects/openci-b1b91/secrets/functions-cd-sa/versions/1",
  OPENCI_FUNCTIONS_CD_ENV_VERSION: "projects/openci-b1b91/secrets/functions-cd-env/versions/2",
};
const ordinary = { name: "NORMAL_SECRET", secretVersionPath: "ordinary" };
const references = [
  ordinary,
  { name: functionsCdCredential, secretVersionPath: "untrusted-team-reference" },
  { name: functionsCdEnvironment, secretVersionPath: "untrusted-team-reference" },
];

test("only the verified production release receives infrastructure-owned pinned secrets", async () => {
  assert.deepEqual(
    await functionsCdSecretReferences(
      references,
      job,
      checkout,
      environment,
      "openci-b1b91",
      false,
      async (sha) => {
        assert.equal(sha, job.commitSha);
        return true;
      },
    ),
    [
      ordinary,
      {
        name: functionsCdCredential,
        secretVersionPath: environment.OPENCI_FUNCTIONS_CD_SA_VERSION,
      },
      {
        name: functionsCdEnvironment,
        secretVersionPath: environment.OPENCI_FUNCTIONS_CD_ENV_VERSION,
      },
    ],
  );
});

test("pushes, PRs, other workflows, repositories, hosts and teams cannot read CD secrets", async () => {
  const cases = [
    { job: { pullRequestNumber: 1 } },
    { job: { workflowFileName: "firebase_functions_ci.dart" } },
    { job: { workflowFileName: "ci/firebase_functions_cd.dart" } },
    { job: { branch: "feature/cd" } },
    { job: { tagName: null, branch: "develop" }, checkout: { branch: "develop" } },
    { job: { tagName: null } },
    { job: { tagName: "v2.5.1" } },
    { job: { teamId: "another-team" } },
    { job: { repositoryId: "456" } },
    { job: { repositoryId: null } },
    { job: { owner: "another-owner" } },
    { job: { repo: "another-repo" } },
    { job: { githubBaseUrl: "https://github.example" } },
    { checkout: { event: "pull_request" } },
    { checkout: { branch: "feature/cd" } },
    { checkout: { commitSha: "b".repeat(40) } },
    { checkout: { checkoutSha: "b".repeat(40) } },
    { environment: { GITHUB_API_BASE_URL: "https://github.example/api/v3" } },
    { environment: { OPENCI_FUNCTIONS_CD_TEAM_ID: "" } },
    { environment: { OPENCI_FUNCTIONS_CD_REPOSITORY_ID: "" } },
    { project: "another-project" },
    { selfHosted: true },
  ];
  for (const value of cases) {
    assert.deepEqual(
      await functionsCdSecretReferences(
        references,
        { ...job, ...value.job },
        { ...checkout, ...value.checkout },
        { ...environment, ...value.environment },
        value.project ?? "openci-b1b91",
        value.selfHosted ?? false,
        async () => assert.fail("Unexpected release commit verification"),
      ),
      [ordinary],
      JSON.stringify(value),
    );
  }
});

test("a release commit outside develop cannot receive infrastructure secrets", async () => {
  await assert.rejects(
    functionsCdSecretReferences(
      references,
      job,
      checkout,
      environment,
      "openci-b1b91",
      false,
      async () => false,
    ),
    /must be in the develop branch history/,
  );
});

test("release ancestry is checked against the live develop SHA with a scoped token", async (t) => {
  const { privateKey } = generateKeyPairSync("rsa", {
    modulusLength: 2048,
    privateKeyEncoding: { type: "pkcs8", format: "pem" },
  });
  let developSha = job.commitSha;
  let status = "ahead";
  let revocations = 0;
  t.mock.method(globalThis, "fetch", async (url, init) => {
    const { pathname, searchParams } = new URL(url);
    if (pathname === `/app/installations/${job.installationId}/access_tokens`) {
      assert.deepEqual(JSON.parse(init.body), {
        permissions: { contents: "read" },
        repository_ids: [Number(job.repositoryId)],
      });
      return Response.json({
        token: "contents-token",
        expires_at: new Date(Date.now() + 3600000).toISOString(),
      });
    }
    if (pathname === "/installation/token") {
      assert.equal(init.method, "DELETE");
      revocations++;
      return new Response(null, { status: 204 });
    }
    if (pathname === "/repos/openci-org/openci/branches/develop") {
      return Response.json({ name: "develop", commit: { sha: developSha } });
    }
    assert.equal(
      decodeURIComponent(pathname),
      `/repos/openci-org/openci/compare/${job.commitSha}...${developSha}`,
    );
    assert.equal(searchParams.get("per_page"), "1");
    return Response.json({ status, merge_base_commit: { sha: job.commitSha } });
  });
  const github = new ExecutionGitHub({
    appId: "1",
    privateKey,
    apiBaseUrl: "https://api.github.com",
    baseUrl: "https://github.com",
  });
  const verify = () => github.isCommitOnDevelop(job, job.commitSha, AbortSignal.timeout(10000));
  assert.equal(await verify(), true);
  developSha = "b".repeat(40);
  assert.equal(await verify(), true);
  status = "diverged";
  assert.equal(await verify(), false);
  assert.equal(revocations, 3);
});

test("production credentials require numeric versions in the production project", async () => {
  for (const value of [
    undefined,
    "",
    "projects/openci-b1b91/secrets/cd/versions/latest",
    "projects/other/secrets/cd/versions/1",
  ]) {
    await assert.rejects(
      functionsCdSecretReferences(
        references,
        job,
        checkout,
        { ...environment, OPENCI_FUNCTIONS_CD_SA_VERSION: value },
        "openci-b1b91",
        false,
        async () => true,
      ),
      /pinned infrastructure secret versions/,
    );
  }
});
