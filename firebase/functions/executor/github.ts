import type { Dispatch, Job, Outcome } from "./model.js";

export interface GitHubOptions {
  appId: string;
  privateKey: string;
  apiBaseUrl: string;
  baseUrl: string;
}

export function githubOptions(options: GitHubOptions): GitHubOptions {
  for (const value of [options.apiBaseUrl, options.baseUrl]) {
    const url = new URL(value);
    if (
      url.protocol !== "https:" ||
      url.username ||
      url.password ||
      url.search ||
      url.hash ||
      value.endsWith("/")
    )
      throw new Error("Invalid GitHub configuration");
  }
  if (!/^[1-9][0-9]*$/.test(options.appId) || !options.privateKey)
    throw new Error("GitHub App credentials missing");
  return options;
}

export class ExecutionGitHub {
  constructor(readonly options: GitHubOptions) {
    githubOptions(options);
  }

  private async client(
    job: Job,
    purpose: "checkout" | "checks" | "pull_request",
  ): Promise<{ request: (typeof import("@octokit/request"))["request"]; token: string }> {
    if (
      (job.githubBaseUrl ?? "https://github.com") !== this.options.baseUrl ||
      !/^[1-9][0-9]*$/.test(job.installationId ?? "")
    )
      throw new Error("GitHub installation mismatch");
    const [{ createAppAuth }, { request }] = await Promise.all([
      import("@octokit/auth-app"),
      import("@octokit/request"),
    ]);
    const transport = request.defaults({
      baseUrl: this.options.apiBaseUrl,
      request: {
        fetch: (url: string | URL | Request, init?: RequestInit) =>
          fetch(url, {
            ...init,
            redirect: "error",
            signal: init?.signal
              ? AbortSignal.any([init.signal, AbortSignal.timeout(10000)])
              : AbortSignal.timeout(10000),
          }),
      },
    });
    const auth = createAppAuth({
      appId: this.options.appId,
      privateKey: this.options.privateKey,
      request: transport,
    });
    const installation = await auth({
      type: "installation",
      installationId: Number(job.installationId),
      repositoryNames: [job.repo],
      permissions:
        purpose === "checks"
          ? { checks: "write" }
          : purpose === "pull_request"
            ? { pull_requests: "read" }
            : { contents: "read" },
    });
    return {
      request: transport.defaults({ headers: { authorization: `token ${installation.token}` } }),
      token: installation.token,
    };
  }

  /** Recheck persisted PR jobs, including jobs planned before the fork policy. */
  async verifyPullRequest(job: Job, accountId: string): Promise<void> {
    if (job.pullRequestNumber === null) return;
    // Missing projections/invalid PR numbers must not silently become push jobs.
    const number = Number(job.pullRequestNumber);
    if (!/^[1-9][0-9]*$/.test(job.pullRequestNumber ?? "") || !Number.isSafeInteger(number))
      throw new Error("Invalid pull request metadata");
    const client = await this.client(job, "pull_request");
    try {
      const { data: repo } = await client.request("GET /repos/{owner}/{repo}", {
        owner: job.owner,
        repo: job.repo,
      });
      const { data: pr } = await client.request("GET /repos/{owner}/{repo}/pulls/{pull_number}", {
        owner: job.owner,
        repo: job.repo,
        pull_number: number,
      });
      if (
        !Number.isSafeInteger(repo.id) ||
        repo.id <= 0 ||
        String(repo.owner?.id) !== accountId ||
        repo.full_name?.toLowerCase() !== `${job.owner}/${job.repo}`.toLowerCase() ||
        pr.number !== number ||
        pr.base?.repo?.id !== repo.id ||
        pr.head?.repo?.id !== repo.id ||
        pr.head?.sha !== job.commitSha?.toLowerCase()
      )
        throw new Error("Untrusted pull request source");
    } finally {
      // This PR-read token stays in Cloud Run, including on rejection/API errors.
      await client.request("DELETE /installation/token");
    }
  }

  async checkout(
    job: Job,
    accountId: string,
  ): Promise<{ token: string; cloneUrl: string; revoke: () => Promise<void> }> {
    const client = await this.client(job, "checkout");
    const { data: repo } = await client.request("GET /repos/{owner}/{repo}", {
      owner: job.owner,
      repo: job.repo,
    });
    if (
      String(repo.owner.id) !== accountId ||
      repo.full_name.toLowerCase() !== `${job.owner}/${job.repo}`.toLowerCase()
    )
      throw new Error("Repository does not belong to the connected installation");
    const cloneUrl = `${this.options.baseUrl}/${encodeURIComponent(job.owner)}/${encodeURIComponent(job.repo)}.git`;
    return {
      token: client.token,
      cloneUrl,
      revoke: async () => {
        await client.request("DELETE /installation/token");
      },
    };
  }

  async check(job: Job, dispatch: Dispatch, outcome?: Outcome): Promise<string> {
    const { request } = await this.client(job, "checks");
    let checkRunId: number | bigint | undefined = dispatch.checkRunId
      ? BigInt(dispatch.checkRunId)
      : undefined;
    if (!checkRunId) {
      // GitHub create-check-run has no idempotency key. Reconcile external_id
      // after a lost response before attempting another create.
      for (let page = 1; ; page++) {
        const { data } = await request("GET /repos/{owner}/{repo}/commits/{ref}/check-runs", {
          owner: job.owner,
          repo: job.repo,
          ref: job.commitSha!,
          check_name: job.workflowName,
          filter: "all",
          per_page: 100,
          page,
        });
        const existing = data.check_runs.find(
          (check) =>
            check.external_id === dispatch.runId && String(check.app?.id) === this.options.appId,
        );
        if (existing) {
          checkRunId = existing.id;
          break;
        }
        if (page * 100 >= data.total_count) break;
        if (page >= 20) throw new Error("Check reconciliation limit exceeded");
      }
    }
    const completion = outcome
      ? {
          status: "completed" as const,
          conclusion: outcome === "blocked" ? ("neutral" as const) : outcome,
          completed_at: new Date(dispatch.resultAt ?? dispatch.updatedAt).toISOString(),
        }
      : { status: "in_progress" as const };
    if (checkRunId) {
      await request("PATCH /repos/{owner}/{repo}/check-runs/{check_run_id}", {
        owner: job.owner,
        repo: job.repo,
        check_run_id: checkRunId,
        ...completion,
      });
      return String(checkRunId);
    }
    const created = await request("POST /repos/{owner}/{repo}/check-runs", {
      owner: job.owner,
      repo: job.repo,
      name: job.workflowName,
      head_sha: job.commitSha!,
      external_id: dispatch.runId!,
      ...completion,
    });
    return String(created.data.id);
  }
}
