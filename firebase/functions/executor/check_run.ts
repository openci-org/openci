import { hasStatus, type GitHubRequest } from "./pull_request_comment.js";

export type CheckTarget = {
  sha: string;
  pullRequest?: { number: number; headSha: string; baseSha: string; pullsUrl: string };
};

type Repository = { owner: string; repo: string };

// GitHub checks belong to a SHA. If even the synthetic merge is shared,
// only a conversation comment can safely carry the result of a single PR.
async function testMergeScope(
  request: GitHubRequest,
  repo: Repository,
  target: CheckTarget,
): Promise<"unique" | "shared" | "pending"> {
  const pr = target.pullRequest!;
  let associated = true;
  let includesSource = false;
  let pending = false;
  for (let page = 1; ; page++) {
    const pagination = { ...repo, per_page: 100, page };
    const { data: pulls } = associated
      ? await request("GET /repos/{owner}/{repo}/commits/{commit_sha}/pulls", {
          ...pagination,
          commit_sha: pr.headSha,
        })
      : await request("GET /repos/{owner}/{repo}/pulls", { ...pagination, state: "open" });
    for (const other of pulls) {
      if (other.state !== "open" || other.head.sha !== pr.headSha) continue;
      if (other.number === pr.number) {
        includesSource = true;
        continue;
      }
      if (other.merge_commit_sha === target.sha) return "shared";
      if (other.base.sha !== pr.baseSha || other.merge_commit_sha) continue;
      const { data } = await request("GET /repos/{owner}/{repo}/pulls/{pull_number}", {
        ...repo,
        pull_number: other.number,
      });
      if (data.state !== "open" || data.head.sha !== pr.headSha || data.base.sha !== pr.baseSha)
        continue;
      if (data.merge_commit_sha === target.sha) return "shared";
      if (data.mergeable !== false && !data.merge_commit_sha) pending = true;
    }
    if (pulls.length < 100) {
      if (!associated || includesSource) return pending ? "pending" : "unique";
      // On the default branch the commit endpoint can return only the merged
      // PR that introduced the commit. Inspect open PRs in that case.
      associated = false;
      page = 0;
    }
  }
}

export async function retirePullRequestCheck(
  request: GitHubRequest,
  repo: Repository,
  appId: string,
  number: number,
  headSha: string,
  savedId: string,
  expectedSha?: string,
  reason = "This pull request's test merge is no longer current.",
) {
  const { data: check } = await request("GET /repos/{owner}/{repo}/check-runs/{check_run_id}", {
    ...repo,
    check_run_id: BigInt(savedId),
  }).catch((error: unknown) => {
    if (hasStatus(error, 404)) return { data: null };
    throw error;
  });
  if (
    !check ||
    String(check.app?.id) !== appId ||
    !check.external_id?.startsWith(`pr:${number}:`) ||
    check.head_sha === headSha ||
    check.head_sha === expectedSha ||
    check.status === "completed"
  )
    return;
  await request("PATCH /repos/{owner}/{repo}/check-runs/{check_run_id}", {
    ...repo,
    check_run_id: BigInt(savedId),
    status: "completed",
    conclusion: "cancelled",
    output: { title: check.name, summary: reason },
  });
}

export type CheckUpdate = {
  status: "queued" | "in_progress" | "completed";
  conclusion?: "success" | "failure" | "cancelled" | "timed_out" | "neutral" | "skipped";
  started_at?: string;
  completed_at?: string;
  details_url?: string;
  output: { title: string; summary: string };
};

export async function writeCheckRun(
  request: GitHubRequest,
  appId: string,
  repo: Repository,
  target: CheckTarget,
  name: string,
  externalId: string,
  savedId: string | null | undefined,
  update: CheckUpdate,
  {
    beforeWrite,
    retryPending,
    existingOnly,
  }: {
    beforeWrite?: () => void | Promise<void>;
    retryPending?: boolean;
    existingOnly?: boolean;
  } = {},
): Promise<string | null> {
  // A stored PR check can predate this reporting scheme or belong to a previous
  // test merge. GitHub cannot change its head_sha with PATCH.
  const scope = target.pullRequest ? `pr:${target.pullRequest.number}:` : "";
  const qualifiedId = scope + externalId;
  const sharedId = `shared-pr-merge:${target.sha}`;
  let mergeScope = target.pullRequest ? await testMergeScope(request, repo, target) : "unique";
  const prior: { id: number | bigint; conclusion?: string | null }[] = [];
  let id: number | bigint | undefined =
    !target.pullRequest && savedId ? BigInt(savedId) : undefined;
  if (!id) {
    for (let page = 1; ; page++) {
      const { data } = await request("GET /repos/{owner}/{repo}/commits/{ref}/check-runs", {
        ...repo,
        ref: target.sha,
        check_name: name,
        filter: "all",
        per_page: 100,
        page,
      });
      for (const check of data.check_runs) {
        if (String(check.app?.id) !== appId || (scope && check.head_sha !== target.sha)) continue;
        if (
          scope &&
          (check.external_id === sharedId || /^pr:[1-9][0-9]*:/u.test(check.external_id ?? ""))
        ) {
          prior.push(check);
          if (!check.external_id?.startsWith(scope)) mergeScope = "shared";
        }
        if (
          check.external_id === qualifiedId ||
          (String(check.id) === savedId && (!scope || check.external_id?.startsWith(scope)))
        )
          id ??= check.id;
      }
      if (!scope && id) break;
      if (page * 100 >= data.total_count) break;
      if (page >= 20) throw new Error("Check reconciliation limit exceeded");
    }
  }
  if (mergeScope === "pending") {
    if (retryPending) throw new Error("Pull request test merge is pending");
    return null;
  }
  if (mergeScope === "shared") {
    // Keep GitHub evaluating the test merge even if the head has a green push
    // Check. A second PR can also open after the first Check already passed.
    const sharedUpdate = {
      status: "completed" as const,
      conclusion: "action_required" as const,
      external_id: sharedId,
      details_url: target.pullRequest!.pullsUrl,
      output: {
        title: name,
        summary:
          "Multiple pull requests share this test merge. See the individual OpenCI results. Update the branch and rerun to obtain a separate required check.",
      },
    };
    if (!prior.length) {
      await beforeWrite?.();
      await request("POST /repos/{owner}/{repo}/check-runs", {
        ...repo,
        name,
        head_sha: target.sha,
        ...sharedUpdate,
      });
    }
    for (const check of prior) {
      if (check.conclusion === "action_required") continue;
      await beforeWrite?.();
      await request("PATCH /repos/{owner}/{repo}/check-runs/{check_run_id}", {
        ...repo,
        check_run_id: check.id,
        ...sharedUpdate,
      });
    }
    return null;
  }
  await beforeWrite?.();
  if (id) {
    await request("PATCH /repos/{owner}/{repo}/check-runs/{check_run_id}", {
      ...repo,
      check_run_id: id,
      ...update,
    });
    return String(id);
  }
  if (existingOnly) return null;
  if (savedId && target.pullRequest) {
    await retirePullRequestCheck(
      request,
      repo,
      appId,
      target.pullRequest.number,
      target.pullRequest.headSha,
      savedId,
      target.sha,
    );
    await beforeWrite?.();
  }
  const { data } = await request("POST /repos/{owner}/{repo}/check-runs", {
    ...repo,
    name,
    head_sha: target.sha,
    external_id: qualifiedId,
    ...update,
  });
  return String(data.id);
}
