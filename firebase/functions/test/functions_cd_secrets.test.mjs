import assert from "node:assert/strict";
import { test } from "node:test";
import {
  functionsCdCredential,
  functionsCdEnvironment,
  functionsCdSecretReferences,
} from "../../lib/functions/executor/functions_cd_secrets.js";

const job = {
  teamId: "trusted-team",
  repositoryId: "123",
  owner: "openci-org",
  repo: "openci",
  branch: "develop",
  workflowFileName: "firebase_functions_cd.dart",
  commitSha: "a".repeat(40),
  pullRequestNumber: null,
};
const checkout = {
  event: "push",
  branch: "develop",
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

test("only the verified production CD receives infrastructure-owned pinned secrets", () => {
  assert.deepEqual(
    functionsCdSecretReferences(references, job, checkout, environment, "openci-b1b91", false),
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

test("PRs, other workflows, repositories, hosts, teams and unverified commits cannot read CD secrets", () => {
  const cases = [
    { job: { pullRequestNumber: 1 } },
    { job: { workflowFileName: "firebase_functions_ci.dart" } },
    { job: { workflowFileName: "ci/firebase_functions_cd.dart" } },
    { job: { branch: "feature/cd" } },
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
      functionsCdSecretReferences(
        references,
        { ...job, ...value.job },
        { ...checkout, ...value.checkout },
        { ...environment, ...value.environment },
        value.project ?? "openci-b1b91",
        value.selfHosted ?? false,
      ),
      [ordinary],
      JSON.stringify(value),
    );
  }
});

test("production credentials require numeric versions in the production project", () => {
  for (const value of [
    undefined,
    "",
    "projects/openci-b1b91/secrets/cd/versions/latest",
    "projects/other/secrets/cd/versions/1",
  ]) {
    assert.throws(
      () =>
        functionsCdSecretReferences(
          references,
          job,
          checkout,
          { ...environment, OPENCI_FUNCTIONS_CD_SA_VERSION: value },
          "openci-b1b91",
          false,
        ),
      /pinned infrastructure secret versions/,
    );
  }
});
