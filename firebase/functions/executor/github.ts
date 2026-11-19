import { PullRequestCheckoutError, type MergeReadinessDiagnostics } from "./checkout_error.js";
import {
  qrPublicationFailure,
  publishPullRequestQrCodes,
  type PullRequestQrCode,
  type WithQrCommentLease,
} from "./pull_request_qr.js";
import {
  queuedCheckExternalId,
  type Dispatch,
  type Job,
  type Outcome,
  type CheckoutPlan,
} from "./model.js";
import type { SkippedCheck } from "../skipped_checks.js";

const installationPermissions = {
  checkout: { contents: "read" },
  checks: { checks: "write" },
  pull_request: { pull_requests: "read", contents: "read" },
  pr_qr: { contents: "write", pull_requests: "write" },
} as const;

const checkoutVerificationTimeoutMs = 30_000;

export interface GitHubOptions {
  appId: string;
  privateKey: string;
  apiBaseUrl: string;
  baseUrl: string;
  billingOrigin?: string;
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
    job: Pick<Job, "githubBaseUrl" | "installationId" | "repo" | "repositoryId">,
    purpose: keyof typeof installationPermissions,
    signal?: AbortSignal,
  ): Promise<{ request: (typeof import("@octokit/request"))["request"]; token: string }> {
    if (
      (job.githubBaseUrl ?? "https://github.com") !== this.options.baseUrl ||
      !/^[1-9][0-9]*$/.test(job.installationId ?? "")
    )
      throw new Error("GitHub installation mismatch");
    if (
      job.repositoryId != null &&
      (!/^[1-9][0-9]*$/.test(job.repositoryId) || !Number.isSafeInteger(Number(job.repositoryId)))
    )
      throw new Error("Invalid GitHub repository ID");
    const [{ createAppAuth }, { request }] = await Promise.all([
      import("@octokit/auth-app"),
      import("@octokit/request"),
    ]);
    const transport = request.defaults({
      baseUrl: this.options.apiBaseUrl,
      // 2026-03-10 removes merge_commit_sha from PR responses.
      headers: { "x-github-api-version": "2022-11-28" },
      request: {
        fetch: (url: string | URL | Request, init?: RequestInit) =>
          fetch(url, {
            ...init,
            redirect: "error",
            signal: AbortSignal.any([
              AbortSignal.timeout(10000),
              ...(init?.signal ? [init.signal] : []),
              ...(signal ? [signal] : []),
            ]),
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
      ...(job.repositoryId != null
        ? { repositoryIds: [Number(job.repositoryId)] }
        : { repositoryNames: [job.repo] }),
      permissions: installationPermissions[purpose],
    });
    return {
      request: transport.defaults({ headers: { authorization: `token ${installation.token}` } }),
      token: installation.token,
    };
  }

  async postPullRequestQrCodes(
    job: Job,
    accountId: string,
    runNumber: number,
    codes: PullRequestQrCode[],
    signal: AbortSignal,
    withLease: WithQrCommentLease,
  ): Promise<void> {
    const client = await this.client(job, "pr_qr");
    try {
      await publishPullRequestQrCodes(
        client.request.defaults({ request: { signal } }),
        this.options.appId,
        job,
        accountId,
        runNumber,
        codes,
        withLease,
      );
    } finally {
      await client.request("DELETE /installation/token");
    }
  }

  /** Report a persisted path exclusion without manufacturing a job or run. */
  async skippedCheck(check: SkippedCheck): Promise<string> {
    const connection = check.connection;
    const leaseExpiresAt = Date.parse(check.leaseExpiresAt ?? "");
    if (
      connection.status !== "active" ||
      connection.githubApiBaseUrl !== this.options.apiBaseUrl ||
      String(connection.githubAppId) !== this.options.appId ||
      !/^[A-Za-z0-9_.-]+$/.test(check.owner) ||
      !/^[A-Za-z0-9_.-]+$/.test(check.repo) ||
      !/^[a-f0-9]{40}(?:[a-f0-9]{24})?$/.test(check.commitSha) ||
      !check.workflowName.trim() ||
      !Number.isFinite(leaseExpiresAt) ||
      leaseExpiresAt <= Date.now()
    )
      throw new Error("Invalid skipped Check context");
    const { request } = await this.client(
      {
        ...check,
        installationId: connection.installationId,
        repositoryId: connection.repositoryId,
      },
      "checks",
    );
    const { data: repo } = await request("GET /repos/{owner}/{repo}", {
      owner: check.owner,
      repo: check.repo,
    });
    if (
      String(repo.owner.id) !== String(connection.accountId) ||
      (connection.repositoryId != null && String(repo.id) !== connection.repositoryId)
    )
      throw new Error("Skipped Check repository owner changed");
    const externalId = `skipped-${check.id}`;
    let checkRunId: number | bigint | undefined = check.checkRunId
      ? BigInt(check.checkRunId)
      : undefined;
    if (!checkRunId) {
      for (let page = 1; ; page++) {
        const { data } = await request("GET /repos/{owner}/{repo}/commits/{ref}/check-runs", {
          owner: check.owner,
          repo: check.repo,
          ref: check.commitSha,
          check_name: check.workflowName,
          filter: "all",
          per_page: 100,
          page,
        });
        const existing = data.check_runs.find(
          (candidate) =>
            candidate.external_id === externalId &&
            String(candidate.app?.id) === this.options.appId,
        );
        if (existing) {
          checkRunId = existing.id;
          break;
        }
        if (page * 100 >= data.total_count) break;
        if (page >= 20) throw new Error("Skipped Check reconciliation limit exceeded");
      }
    }
    // Leave room for the bounded ten-second GitHub write and database ack.
    if (leaseExpiresAt - Date.now() < 15000)
      throw new Error("Skipped Check reporting lease expired");
    const result = {
      status: "completed" as const,
      conclusion: "skipped" as const,
      started_at: new Date(Number(check.createdAt) * 1000).toISOString(),
      completed_at: new Date(Number(check.createdAt) * 1000).toISOString(),
      output: {
        title: "No matching changed paths",
        summary: "The complete changed-file list did not match this workflow's paths conditions.",
      },
    };
    if (checkRunId) {
      await request("PATCH /repos/{owner}/{repo}/check-runs/{check_run_id}", {
        owner: check.owner,
        repo: check.repo,
        check_run_id: checkRunId,
        ...result,
      });
      return String(checkRunId);
    }
    const { data } = await request("POST /repos/{owner}/{repo}/check-runs", {
      owner: check.owner,
      repo: check.repo,
      name: check.workflowName,
      head_sha: check.commitSha,
      external_id: externalId,
      ...result,
    });
    return String(data.id);
  }

  async isCommitOnDevelop(job: Job, commitSha: string, signal: AbortSignal): Promise<boolean> {
    const { request } = await this.client(job, "checkout");
    const repository = { owner: job.owner, repo: job.repo, request: { signal } };
    try {
      const { data: branch } = await request("GET /repos/{owner}/{repo}/branches/{branch}", {
        ...repository,
        branch: "develop",
      });
      const developSha = branch.commit?.sha;
      if (branch.name !== "develop" || !/^[a-f0-9]{40}(?:[a-f0-9]{24})?$/.test(developSha ?? ""))
        throw new Error("Could not verify the develop branch");
      if (developSha === commitSha) return true;
      const { data } = await request("GET /repos/{owner}/{repo}/compare/{basehead}", {
        ...repository,
        basehead: `${commitSha}...${developSha}`,
        per_page: 1,
      });
      return data.status === "ahead" && data.merge_base_commit?.sha === commitSha;
    } finally {
      await request("DELETE /installation/token");
    }
  }

  /** Use a current GitHub merge, or immediately prepare a verified local merge. */
  async resolveCheckout(job: Job, accountId: string, signal?: AbortSignal): Promise<CheckoutPlan> {
    signal?.throwIfAborted();
    if (!/^[a-fA-F0-9]{40}(?:[a-fA-F0-9]{24})?$/.test(job.commitSha ?? ""))
      throw new Error("Invalid commit SHA");
    if (job.pullRequestNumber === null) {
      if (typeof job.branch !== "string" || !job.branch.trim())
        throw new Error("Missing push branch");
      return {
        event: "push",
        branch: job.branch,
        commitSha: job.commitSha!.toLowerCase(),
        checkoutSha: job.commitSha!.toLowerCase(),
      };
    }
    // Missing projections/invalid PR numbers must not silently become push jobs.
    const number = Number(job.pullRequestNumber);
    if (!/^[1-9][0-9]*$/.test(job.pullRequestNumber ?? "") || !Number.isSafeInteger(number))
      throw new Error("Invalid pull request metadata");
    const client = await this.client(job, "pull_request");
    const startedAt = Date.now();
    const deadline = startedAt + checkoutVerificationTimeoutMs;
    const readinessTimeout = AbortSignal.timeout(checkoutVerificationTimeoutMs);
    const readinessSignal = AbortSignal.any([readinessTimeout, ...(signal ? [signal] : [])]);
    let attempts = 0;
    const readiness = { reason: "not_ready" as "not_ready" | "stale_merge" };
    let observation: Omit<MergeReadinessDiagnostics, "attempts" | "elapsedMs"> = {};
    const diagnostics = () => ({ ...observation, attempts, elapsedMs: Date.now() - startedAt });
    const readinessError = () => new PullRequestCheckoutError(readiness.reason, diagnostics());
    const checkDeadline = () => {
      readinessSignal.throwIfAborted();
      if (Date.now() >= deadline) throw readinessError();
    };
    try {
      readinessSignal.throwIfAborted();
      const { data: repo } = await client
        .request("GET /repos/{owner}/{repo}", {
          owner: job.owner,
          repo: job.repo,
          request: { signal: readinessSignal },
        })
        .catch((error: unknown) => {
          signal?.throwIfAborted();
          if (readinessTimeout.aborted) throw readinessError();
          throw error;
        });
      if (
        !Number.isSafeInteger(repo.id) ||
        repo.id <= 0 ||
        String(repo.owner?.id) !== accountId ||
        (job.repositoryId != null && String(repo.id) !== job.repositoryId) ||
        repo.full_name?.toLowerCase() !== `${job.owner}/${job.repo}`.toLowerCase()
      )
        throw new Error("Untrusted pull request source");

      // Recheck the source, PR state and current base before selecting a local
      // merge. Its inputs never come from GitHub's delayed synthetic commit.
      const readCandidate = async (): Promise<CheckoutPlan> => {
        checkDeadline();
        attempts++;
        const { data: pr, headers } = await client.request(
          "GET /repos/{owner}/{repo}/pulls/{pull_number}",
          {
            owner: job.owner,
            repo: job.repo,
            pull_number: number,
            request: { signal: readinessSignal },
          },
        );
        if (
          pr.number !== number ||
          pr.base?.repo?.id !== repo.id ||
          pr.head?.repo?.id !== repo.id ||
          typeof pr.head?.ref !== "string" ||
          !pr.head.ref ||
          typeof pr.base?.ref !== "string" ||
          !pr.base.ref ||
          !/^[a-f0-9]{40}(?:[a-f0-9]{24})?$/.test(pr.base?.sha ?? "")
        )
          throw new Error("Untrusted pull request source");
        if (pr.head?.sha !== job.commitSha!.toLowerCase())
          throw new PullRequestCheckoutError("head_changed");
        if (pr.state !== "open" || pr.merged) throw new PullRequestCheckoutError("closed");
        if (pr.mergeable === false) throw new PullRequestCheckoutError("conflicts");
        readiness.reason = "not_ready";
        observation = { headSha: pr.head.sha };
        const requestId = headers["x-github-request-id"];
        if (requestId && /^[A-Za-z0-9:-]{1,128}$/.test(requestId))
          observation.requestId = requestId;
        checkDeadline();
        // PR metadata can retain an older base SHA. Pin the current branch
        // even when GitHub has not calculated mergeability or a merge SHA yet.
        const { data: base } = await client
          .request("GET /repos/{owner}/{repo}/git/ref/{ref}", {
            owner: job.owner,
            repo: job.repo,
            ref: `heads/${pr.base.ref}`,
            request: { signal: readinessSignal },
          })
          .catch(() => {
            readinessSignal.throwIfAborted();
            throw new PullRequestCheckoutError("unavailable");
          });
        if (
          base.ref !== `refs/heads/${pr.base.ref}` ||
          base.object?.type !== "commit" ||
          !/^[a-f0-9]{40}(?:[a-f0-9]{24})?$/.test(base.object?.sha ?? "")
        )
          throw new Error("Untrusted pull request base ref");
        observation.baseSha = base.object.sha;
        const candidate = {
          event: "pull_request" as const,
          number,
          headBranch: pr.head.ref,
          baseBranch: pr.base.ref,
          headSha: pr.head.sha,
          baseSha: base.object.sha,
        };
        checkDeadline();
        const mergeSha = pr.merge_commit_sha;
        if (pr.mergeable === true && mergeSha && /^[a-f0-9]{40}(?:[a-f0-9]{24})?$/.test(mergeSha)) {
          observation.mergeSha = mergeSha;
          const { data: commit } = await client
            .request("GET /repos/{owner}/{repo}/git/commits/{commit_sha}", {
              owner: job.owner,
              repo: job.repo,
              commit_sha: mergeSha,
              request: { signal: readinessSignal },
            })
            .catch((error: unknown) => {
              readinessSignal.throwIfAborted();
              // GitHub can advertise the merge SHA before the Git object is
              // readable. A missing synthetic object can use the local merge.
              if ((error as { status?: number })?.status === 404) return { data: null };
              throw new PullRequestCheckoutError("unavailable");
            });
          // A stale merge ref can survive a base/head update. Only use the
          // candidate whose parents match the PR revision we just observed.
          if (
            commit?.sha === mergeSha &&
            commit.parents?.length === 2 &&
            /^[a-f0-9]{40}(?:[a-f0-9]{24})?$/.test(commit.parents[0].sha) &&
            commit.parents[1].sha === pr.head.sha
          ) {
            observation.mergeBaseSha = commit.parents[0].sha;
            if (commit.parents[0].sha === base.object.sha)
              return { ...candidate, checkoutSha: mergeSha };
            readiness.reason = "stale_merge";
          }
        }
        return { ...candidate, checkoutSha: null, fallback: diagnostics() };
      };

      let candidate = await readCandidate();
      checkDeadline();
      if (candidate.checkoutSha === null) {
        // One immediate reread catches a changed/closed PR or a newly ready
        // GitHub merge. No polling delay reserves build capacity while idle.
        candidate = await readCandidate();
        checkDeadline();
        if (candidate.checkoutSha === null) {
          // Verify the actual head branch as well as the PR metadata. Git will
          // determine conflicts from these pinned refs inside the disposable VM;
          // the synthetic merge's availability or ancestry is irrelevant.
          const { data: head } = await client.request("GET /repos/{owner}/{repo}/git/ref/{ref}", {
            owner: job.owner,
            repo: job.repo,
            ref: `heads/${candidate.headBranch}`,
            request: { signal: readinessSignal },
          });
          if (head.ref !== `refs/heads/${candidate.headBranch}` || head.object?.type !== "commit")
            throw new Error("Untrusted pull request head ref");
          if (head.object.sha !== candidate.headSha)
            throw new PullRequestCheckoutError("head_changed");
          candidate.fallback.elapsedMs = Date.now() - startedAt;
        }
      }
      checkDeadline();
      return candidate;
    } catch (error) {
      signal?.throwIfAborted();
      if (readinessTimeout.aborted) throw readinessError();
      throw error;
    } finally {
      // Revoke independently of the execution signal, including cancellation.
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
      (job.repositoryId != null && String(repo.id) !== job.repositoryId) ||
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
    if (outcome === "card_required") {
      const url = new URL("/billing", this.options.billingOrigin ?? "https://dashboard.openci.org");
      url.searchParams.set("teamId", dispatch.teamId!);
      const externalId = queuedCheckExternalId(job);
      return this.writeCheck(request, job, externalId, dispatch.checkRunId, {
        status: "queued",
        output: {
          title: "Waiting for a billing card",
          summary: `[Register a billing card for this team](${url.href}). This job will resume automatically once the card is confirmed.`,
        },
      });
    }
    const output =
      outcome === "failure" && dispatch.failureSummary
        ? {
            title:
              dispatch.failureSummary === qrPublicationFailure
                ? "Pull request QR code publication failed"
                : "Pull request checkout failed",
            summary: dispatch.failureSummary,
          }
        : {
            title: job.workflowName!,
            summary: outcome
              ? `Build result: ${outcome.replaceAll("_", " ")}.`
              : "The build is running.",
          };
    return this.writeCheck(
      request,
      job,
      dispatch.runId!,
      dispatch.checkRunId,
      outcome
        ? {
            status: "completed",
            conclusion: outcome === "blocked" ? "neutral" : outcome,
            completed_at: new Date(dispatch.resultAt ?? dispatch.updatedAt).toISOString(),
            output,
          }
        : { status: "in_progress", output },
    );
  }

  /** Called under the persisted job lease, before any executor can claim it. */
  async queuedCheck(
    job: Job,
    externalId: string,
    savedId: string | null,
    accountId: string,
    signal: AbortSignal,
  ): Promise<string> {
    const { request } = await this.client(job, "checks", signal);
    const { data: repo } = await request("GET /repos/{owner}/{repo}", {
      owner: job.owner,
      repo: job.repo,
    });
    if (
      String(repo.owner.id) !== accountId ||
      (job.repositoryId != null && String(repo.id) !== job.repositoryId) ||
      repo.full_name.toLowerCase() !== `${job.owner}/${job.repo}`.toLowerCase()
    )
      throw new Error("Repository does not belong to the connected installation");
    return this.writeCheck(
      request,
      job,
      externalId,
      savedId,
      job.status === "CANCELLED"
        ? {
            status: "completed",
            conclusion: "cancelled",
            completed_at: new Date().toISOString(),
            output: { title: job.workflowName!, summary: "The build was cancelled." },
          }
        : {
            status: "queued",
            output: { title: job.workflowName!, summary: "Waiting for the build to start." },
          },
    );
  }

  private async writeCheck(
    request: (typeof import("@octokit/request"))["request"],
    job: Job,
    externalId: string,
    savedId: string | null | undefined,
    state: {
      status: "queued" | "in_progress" | "completed";
      conclusion?: "success" | "failure" | "cancelled" | "timed_out" | "neutral";
      completed_at?: string;
      output?: { title: string; summary: string };
    },
  ): Promise<string> {
    let checkRunId: number | bigint | undefined = savedId ? BigInt(savedId) : undefined;
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
            check.external_id === externalId && String(check.app?.id) === this.options.appId,
        );
        if (existing) {
          checkRunId = existing.id;
          break;
        }
        if (page * 100 >= data.total_count) break;
        if (page >= 20) throw new Error("Check reconciliation limit exceeded");
      }
    }
    if (checkRunId) {
      await request("PATCH /repos/{owner}/{repo}/check-runs/{check_run_id}", {
        owner: job.owner,
        repo: job.repo,
        check_run_id: checkRunId,
        ...state,
      });
      return String(checkRunId);
    }
    const created = await request("POST /repos/{owner}/{repo}/check-runs", {
      owner: job.owner,
      repo: job.repo,
      name: job.workflowName,
      head_sha: job.commitSha!,
      external_id: externalId,
      ...state,
    });
    return String(created.data.id);
  }
}
