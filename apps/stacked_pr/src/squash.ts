import type { GitHubApi } from "./github.js";
import {
  object,
  jsonObject,
  jsonObjects,
  type Json,
  type PullRequest,
  type Repository,
  RestackException,
  RetryException,
} from "./models.js";

export interface StackMember {
  number: number;
  ref: string;
  head: string;
  base: string;
}

// GraphQL exposes legacy statuses with the installed App's existing permissions;
// the REST statuses endpoint would require an additional App permission.
async function legacyStatuses(
  api: GitHubApi,
  installation: number,
  repo: Repository,
  head: string,
): Promise<Json[]> {
  const [owner, name] = repo.fullName.split("/");
  const statuses: Json[] = [];
  let cursor: string | null = null;
  for (;;) {
    const response = jsonObject(
      await api.request(installation, "POST", "/graphql", {
        query: `query StackSquashStatuses($owner: String!, $name: String!, $head: String!, $cursor: String) {
  repository(owner: $owner, name: $name) { object(expression: $head) { ... on Commit {
    oid statusCheckRollup { contexts(first: 100, after: $cursor) {
      nodes { __typename ... on StatusContext { context state createdAt } }
      pageInfo { hasNextPage endCursor }
    } }
  } } }
}`,
        variables: { owner, name, head, cursor },
      }),
    );
    if (response.errors != null) throw new RetryException("Legacy CI status unavailable");
    const commit = jsonObject(jsonObject(jsonObject(response.data).repository).object);
    if (commit.oid !== head) throw new RetryException("CI status head changed");
    const contexts = jsonObject(jsonObject(commit.statusCheckRollup).contexts);
    for (const status of jsonObjects(contexts.nodes))
      if (status.__typename === "StatusContext")
        statuses.push({ ...status, state: String(status.state).toLowerCase() });
    const page = jsonObject(contexts.pageInfo);
    if (page.hasNextPage === false) break;
    if (
      page.hasNextPage !== true ||
      typeof page.endCursor !== "string" ||
      page.endCursor === cursor
    )
      throw new RetryException("Incomplete CI status page");
    cursor = page.endCursor;
  }
  return statuses.sort((a, b) =>
    String(b.createdAt ?? "").localeCompare(String(a.createdAt ?? "")),
  );
}
export interface PreparedSquash {
  head: string;
  base: string;
  tree: string;
}

/** Closing included parents is safe only for a complete, unbranched stack. */
export function assertCompleteStack(open: PullRequest[], members: StackMember[]) {
  const numbers = new Set(members.map((p) => p.number));
  const refs = new Set(members.map((p) => p.ref));
  if (open.some((p) => p.isOpen && !numbers.has(p.number) && refs.has(p.baseRef)))
    throw new RestackException(
      "後続または分岐したPRがあります。Squash stackは分岐のないスタックの末尾で選んでください。",
    );
}

/** The dependency Check is intentionally action_required on children; CI and reviews still gate every layer. */
export async function squashReadiness(
  api: GitHubApi,
  installation: number,
  repo: Repository,
  pr: PullRequest,
  app: Json,
): Promise<string | undefined> {
  const [checks, statuses, reviews] = await Promise.all([
    api.list(
      installation,
      `${repo.apiPath}/commits/${pr.head}/check-runs?filter=latest`,
      "check_runs",
    ),
    legacyStatuses(api, installation, repo, pr.head),
    api.list(installation, `${repo.apiPath}/pulls/${pr.number}/reviews`),
  ]);
  const ci = checks.filter((check) => {
    const dependency =
      object(check.app).id === app.id && check.external_id === `stacked-pr:${repo.id}:${pr.number}`;
    if (dependency && check.conclusion === "failure")
      throw new RestackException(`#${pr.number} のStacked PRチェックが失敗しています。`);
    return !dependency;
  });
  const contexts = new Map<string, Json>();
  for (const status of statuses)
    if (typeof status.context === "string" && !contexts.has(status.context))
      contexts.set(status.context, status);
  if (
    (!ci.length && !contexts.size) ||
    ci.some(
      (c) =>
        c.status !== "completed" ||
        !["success", "neutral", "skipped"].includes(String(c.conclusion)),
    ) ||
    [...contexts.values()].some((c) => c.state !== "success")
  )
    return `#${pr.number} の最新headのCI待ち`;
  const decisions = new Map<string, Json>();
  for (const review of reviews) {
    const login = object(review.user).login;
    if (
      typeof login === "string" &&
      ["APPROVED", "CHANGES_REQUESTED", "DISMISSED"].includes(String(review.state))
    )
      decisions.set(login.toLowerCase(), review);
  }
  if (
    [...decisions.values()].some((r) => r.state === "CHANGES_REQUESTED") ||
    ![...decisions.values()].some((r) => r.state === "APPROVED" && r.commit_id === pr.head)
  )
    return `#${pr.number} の最新headへの承認待ち`;
}
