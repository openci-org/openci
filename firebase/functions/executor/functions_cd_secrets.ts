import type { Job, ResolvedCheckout } from "./model.js";

export const functionsCdCredential = "FIREBASE_FUNCTIONS_CD_SERVICE_ACCOUNT_JSON_BASE64";
export const functionsCdEnvironment = "FIREBASE_FUNCTIONS_CD_ENV_BASE64";

type SecretReference = { name: string; secretVersionPath: string };

/** These credentials are infrastructure-owned, never ordinary team secrets. */
export async function functionsCdSecretReferences(
  references: SecretReference[],
  job: Job,
  checkout: ResolvedCheckout,
  environment: NodeJS.ProcessEnv,
  project: string,
  selfHosted: boolean,
  isCommitOnDevelop: (commitSha: string) => Promise<boolean>,
): Promise<SecretReference[]> {
  const ordinary = references.filter(
    ({ name }) => name !== functionsCdCredential && name !== functionsCdEnvironment,
  );
  if (
    selfHosted ||
    project !== "openci-b1b91" ||
    (environment.GITHUB_API_BASE_URL ?? "https://api.github.com") !== "https://api.github.com" ||
    (job.githubBaseUrl ?? "https://github.com") !== "https://github.com" ||
    job.owner !== "openci-org" ||
    job.repo !== "openci" ||
    !environment.OPENCI_FUNCTIONS_CD_TEAM_ID ||
    job.teamId !== environment.OPENCI_FUNCTIONS_CD_TEAM_ID ||
    !environment.OPENCI_FUNCTIONS_CD_REPOSITORY_ID ||
    job.repositoryId !== environment.OPENCI_FUNCTIONS_CD_REPOSITORY_ID ||
    job.workflowFileName !== "firebase_functions_cd.dart" ||
    job.pullRequestNumber != null ||
    !job.tagName ||
    job.branch !== `refs/tags/${job.tagName}` ||
    checkout.event !== "push" ||
    checkout.branch !== job.branch ||
    checkout.commitSha !== job.commitSha ||
    checkout.checkoutSha !== job.commitSha
  ) {
    return ordinary;
  }
  if (!(await isCommitOnDevelop(checkout.commitSha))) {
    throw new Error("Functions CD release commit must be in the develop branch history");
  }

  const protectedReferences = [
    { name: functionsCdCredential, secretVersionPath: environment.OPENCI_FUNCTIONS_CD_SA_VERSION },
    {
      name: functionsCdEnvironment,
      secretVersionPath: environment.OPENCI_FUNCTIONS_CD_ENV_VERSION,
    },
  ];
  for (const reference of protectedReferences) {
    if (
      !reference.secretVersionPath ||
      !/^projects\/openci-b1b91\/secrets\/[A-Za-z0-9_-]+\/versions\/[1-9][0-9]*$/.test(
        reference.secretVersionPath,
      )
    ) {
      throw new Error("Functions CD requires pinned infrastructure secret versions");
    }
  }
  return [...ordinary, ...(protectedReferences as SecretReference[])];
}
