import { setTimeout as delay } from "node:timers/promises";
import { PullRequestCheckoutError } from "./checkout_error.js";
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

const mergeReadinessTimeoutMs = 600_000;
const mergeReadinessMaxDelayMs = 30_000;

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

  /** Pin checkout metadata and select a verified merge or a local merge plan. */
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
    const deadline = Date.now() + mergeReadinessTimeoutMs;
    const readinessTimeout = AbortSignal.timeout(mergeReadinessTimeoutMs);
    const readinessSignal = AbortSignal.any([readinessTimeout, ...(signal ? [signal] : [])]);
    try {
      readinessSignal.throwIfAborted();
      const { data: repo } = await client.request("GET /repos/{owner}/{repo}", {
        owner: job.owner,
        repo: job.repo,
        request: { signal: readinessSignal },
      });
      if (
        !Number.isSafeInteger(repo.id) ||
        repo.id <= 0 ||
        String(repo.owner?.id) !== accountId ||
        (job.repositoryId != null && String(repo.id) !== job.repositoryId) ||
        repo.full_name?.toLowerCase() !== `${job.owner}/${job.repo}`.toLowerCase()
      )
        throw new Error("Untrusted pull request source");

      // GET /pulls starts GitHub's asynchronous merge calculation. Reobserve
      // the PR on each retry because its head or base may advance meanwhile.
      // The deadline includes API time, and its signal also bounds in-flight
      // requests. Back off to avoid polling every second for all parallel jobs.
      for (let attempt = 0; Date.now() < deadline; attempt++) {
        if (attempt > 0) {
          await delay(
            Math.min(1000 * 2 ** (attempt - 1), mergeReadinessMaxDelayMs, deadline - Date.now()),
            undefined,
            { signal: readinessSignal },
          );
        }
        readinessSignal.throwIfAborted();
        if (Date.now() >= deadline) break;
        const { data: pr } = await client.request("GET /repos/{owner}/{repo}/pulls/{pull_number}", {
          owner: job.owner,
          repo: job.repo,
          pull_number: number,
          request: { signal: readinessSignal },
        });
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
        const mergeSha = pr.merge_commit_sha;
        if (pr.mergeable === true && mergeSha && /^[a-f0-9]{40}(?:[a-f0-9]{24})?$/.test(mergeSha)) {
          // PR metadata can retain an older base SHA even after GitHub has
          // regenerated the test merge commit. Read the actual branch ref
          // from the verified repository on every attempt instead.
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
              // readable. Reobserve the PR instead of using the stale candidate.
              if ((error as { status?: number })?.status === 404) return { data: null };
              throw new PullRequestCheckoutError("unavailable");
            });
          // GitHub can retain a merge against an old base indefinitely. Once
          // the saved head is verified, merge the pinned current base locally
          // instead of waiting for that candidate to change or testing it.
          if (
            commit?.sha === mergeSha &&
            commit.parents?.length === 2 &&
            /^[a-f0-9]{40}(?:[a-f0-9]{24})?$/.test(commit.parents[0].sha) &&
            commit.parents[1].sha === pr.head.sha
          ) {
            readinessSignal.throwIfAborted();
            if (Date.now() >= deadline) throw new PullRequestCheckoutError("not_ready");
            return {
              event: "pull_request",
              number,
              headBranch: pr.head.ref,
              baseBranch: pr.base.ref,
              headSha: pr.head.sha,
              baseSha: base.object.sha,
              checkoutSha: commit.parents[0].sha === base.object.sha ? mergeSha : null,
            };
          }
        }
      }
      throw new PullRequestCheckoutError("not_ready");
    } catch (error) {
      // Preserve execution cancellation/deadline errors ahead of readiness.
      signal?.throwIfAborted();
      if (readinessTimeout.aborted) throw new PullRequestCheckoutError("not_ready");
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
