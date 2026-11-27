import { PullRequestCheckoutError, type MergeReadinessDiagnostics } from "./checkout_error.js";
import { retirePullRequestCheck, writeCheckRun, type CheckTarget } from "./check_run.js";
import {
  qrPublicationFailure,
  publishPullRequestQrCodes,
  type PullRequestQrCode,
} from "./pull_request_qr.js";
import {
  hasStatus,
  pullRequestCommentTarget,
  updatePullRequestComment,
  type WithCommentLease,
} from "./pull_request_comment.js";
import {
  queuedCheckExternalId,
  type Dispatch,
  type Job,
  type Outcome,
  type CheckoutPlan,
} from "./model.js";
import type { SkippedCheck } from "../skipped_checks.js";
import { dashboardOrigin, dashboardRunUrl } from "../links.js";

const installationPermissions = {
  checkout: { contents: "read" },
  checks: { checks: "write" },
  pr_checks: { checks: "write", pull_requests: "read" },
  pull_request: { pull_requests: "read", contents: "read" },
  pr_comment: { contents: "read", pull_requests: "write" },
  pr_qr: { contents: "write", pull_requests: "write" },
} as const;

const checkoutVerificationTimeoutMs = 30_000;

type CheckoutJob = Pick<
  Job,
  | "githubBaseUrl"
  | "installationId"
  | "repositoryId"
  | "owner"
  | "repo"
  | "pullRequestNumber"
  | "commitSha"
  | "branch"
>;
type PullRequestBase = { baseSha: string; baseBranch: string };
type CheckDispatch = Pick<
  Dispatch,
  | "checkRunId"
  | "runId"
  | "teamId"
  | "resultAt"
  | "updatedAt"
  | "failureSummary"
  | "pullRequestBaseSha"
  | "pullRequestBaseBranch"
  | "pullRequestMergeSha"
>;
type ResolvedCheckTarget = CheckTarget | { sha: null; pending: boolean };

export interface GitHubOptions {
  appId: string;
  privateKey: string;
  apiBaseUrl: string;
  baseUrl: string;
  billingOrigin?: string;
  dashboardOrigin?: string;
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

export function buildGitHub(environment: NodeJS.ProcessEnv = process.env): ExecutionGitHub {
  return new ExecutionGitHub({
    appId: environment.GITHUB_APP_ID ?? "",
    privateKey: environment.GITHUB_APP_PRIVATE_KEY ?? "",
    apiBaseUrl: environment.GITHUB_API_BASE_URL ?? "https://api.github.com",
    baseUrl: environment.GITHUB_BASE_URL ?? "https://github.com",
    dashboardOrigin: dashboardOrigin(environment),
  });
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
    withLease: WithCommentLease,
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

  async postPullRequestResult(
    job: Job,
    accountId: string,
    order: bigint,
    signal: AbortSignal,
    withLease: WithCommentLease,
    render: (
      previous: string | null,
      files: (paths: string[]) => Promise<Map<string, string>>,
    ) => Promise<string | null>,
    variant: readonly string[],
  ): Promise<void> {
    const client = await this.client(job, "pr_comment");
    try {
      const request = client.request.defaults({ request: { signal } });
      const target = await pullRequestCommentTarget(request, job, accountId);
      if (target) {
        // Analyzer paths can be relative to a package inside a monorepo. Link
        // only unambiguous files that exist at the PR head, including on retries.
        const files = async (paths: string[]) => {
          const matches = new Map<string, string>();
          if (!paths.length) return matches;
          const { data } = await request("GET /repos/{owner}/{repo}/git/trees/{tree_sha}", {
            ...target.repo,
            tree_sha: job.commitSha!,
            recursive: "1",
          }).catch((failure: unknown) => {
            if (hasStatus(failure, 404, 409, 422)) return { data: null };
            throw failure;
          });
          if (!data || data.truncated) return matches;
          for (const path of paths) {
            const found = data.tree.filter(
              (entry) =>
                entry.type === "blob" && (entry.path === path || entry.path?.endsWith("/" + path)),
            );
            if (found.length === 1 && found[0].path) matches.set(path, found[0].path);
          }
          return matches;
        };
        await updatePullRequestComment(
          request,
          this.options.appId,
          job,
          target,
          "result",
          order,
          withLease,
          (previous) => render(previous, files),
          variant,
        );
      }
    } finally {
      await client.request("DELETE /installation/token").catch((failure: unknown) => {
        if (!hasStatus(failure, 401, 404)) throw failure;
      });
    }
  }

  /** Report a persisted path exclusion without manufacturing a job or run. */
  async skippedCheck(check: SkippedCheck): Promise<string | null> {
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
      check.webhookTask.eventType === "pull_request" ? "pr_checks" : "checks",
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
    const event = check.webhookTask;
    let target: ResolvedCheckTarget = { sha: check.commitSha };
    if (event.eventType === "pull_request") {
      const payload = JSON.parse(event.payload);
      const number = payload.number;
      const baseBranch = payload.pull_request?.base?.ref;
      if (
        !Number.isSafeInteger(number) ||
        number < 1 ||
        typeof baseBranch !== "string" ||
        !baseBranch
      )
        throw new Error("Invalid skipped pull request");
      target = await this.checkTarget(
        {
          ...check,
          installationId: connection.installationId,
          repositoryId: connection.repositoryId,
          pullRequestNumber: String(number),
        },
        connection.accountId,
        { expectedBase: { baseSha: check.comparisonBaseSha, baseBranch } },
      );
      if (target.sha === null) {
        if (target.pending) throw new Error("Pull request test merge is pending");
        return null;
      }
    } else if (event.eventType !== "push" && event.eventType !== "release") {
      throw new Error("Unknown skipped Check event");
    }
    const at = new Date(Number(check.createdAt) * 1000).toISOString();
    return writeCheckRun(
      request,
      this.options.appId,
      { owner: check.owner, repo: check.repo },
      target,
      check.workflowName,
      `skipped-${check.id}`,
      check.checkRunId,
      {
        status: "completed",
        conclusion: "skipped",
        started_at: at,
        completed_at: at,
        output: {
          title: "No matching changed paths",
          summary: "The complete changed-file list did not match this workflow's paths conditions.",
        },
      },
      {
        retryPending: true,
        beforeWrite: () => {
          if (leaseExpiresAt - Date.now() < 15000)
            throw new Error("Skipped Check reporting lease expired");
        },
      },
    );
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
  async resolveCheckout(
    job: CheckoutJob,
    accountId: string,
    signal?: AbortSignal,
  ): Promise<CheckoutPlan> {
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

  private async checkTarget(
    job: CheckoutJob,
    accountId: string | undefined,
    options: {
      checkout?: CheckoutPlan;
      expectedBase?: PullRequestBase;
      mergeSha?: string | null;
      signal?: AbortSignal;
    } = {},
  ): Promise<ResolvedCheckTarget> {
    if (job.pullRequestNumber === null) return { sha: job.commitSha! };
    const headSha = job.commitSha!.toLowerCase();
    const number = Number(job.pullRequestNumber);
    if (!Number.isSafeInteger(number) || number < 1) throw new Error("Invalid pull request number");
    const pullRequest = {
      number,
      headSha,
      pullsUrl: `${this.options.baseUrl}/${encodeURIComponent(job.owner)}/${encodeURIComponent(job.repo)}/pulls`,
    };
    if (options.mergeSha && options.expectedBase) {
      if (
        !/^[a-f0-9]{40}(?:[a-f0-9]{24})?$/.test(options.mergeSha) ||
        options.mergeSha === headSha ||
        options.mergeSha === options.expectedBase.baseSha
      )
        throw new Error("Invalid stored pull request test merge");
      return {
        sha: options.mergeSha,
        pullRequest: { ...pullRequest, baseSha: options.expectedBase.baseSha },
      };
    }
    if (!accountId) return { sha: null, pending: false };
    let checkout: CheckoutPlan;
    try {
      checkout = options.checkout ?? (await this.resolveCheckout(job, accountId, options.signal));
    } catch (error) {
      if (!(error instanceof PullRequestCheckoutError)) throw error;
      return {
        sha: null,
        pending: ["not_ready", "stale_merge", "unavailable"].includes(error.reason),
      };
    }
    if (
      checkout.event !== "pull_request" ||
      checkout.number !== Number(job.pullRequestNumber) ||
      checkout.headSha !== job.commitSha?.toLowerCase()
    )
      throw new Error("Unverified pull request check");
    const { expectedBase } = options;
    if (
      expectedBase &&
      (checkout.baseSha !== expectedBase.baseSha || checkout.baseBranch !== expectedBase.baseBranch)
    )
      return { sha: null, pending: false };
    if (checkout.checkoutSha === null) return { sha: null, pending: true };
    if (checkout.checkoutSha === checkout.headSha || checkout.checkoutSha === checkout.baseSha)
      throw new Error("Invalid pull request test merge");
    return {
      sha: checkout.checkoutSha,
      pullRequest: { ...pullRequest, baseSha: checkout.baseSha },
    };
  }

  async check(
    job: Job,
    dispatch: CheckDispatch,
    outcome?: Outcome,
    context?: {
      accountId: string;
      checkout?: CheckoutPlan;
      retryPending?: boolean;
      beforeWrite?: () => Promise<void>;
      signal?: AbortSignal;
    },
  ): Promise<string | null> {
    const expectedBase =
      dispatch.pullRequestBaseSha && dispatch.pullRequestBaseBranch
        ? { baseSha: dispatch.pullRequestBaseSha, baseBranch: dispatch.pullRequestBaseBranch }
        : undefined;
    // An unconfigured or historical attempt has no verified base to attest to.
    // The completion reporter can still deliver its diagnostic directly to the PR.
    const target =
      job.pullRequestNumber !== null &&
      !context?.checkout &&
      !expectedBase &&
      outcome !== "card_required"
        ? ({ sha: null, pending: false } as const)
        : await this.checkTarget(job, context?.accountId, {
            ...context,
            expectedBase,
            mergeSha: dispatch.pullRequestMergeSha,
          });
    const repo = { owner: job.owner, repo: job.repo };
    if (target.sha === null) {
      if (dispatch.checkRunId && job.pullRequestNumber) {
        const { request } = await this.client(job, "checks", context?.signal);
        await retirePullRequestCheck(
          request,
          repo,
          this.options.appId,
          Number(job.pullRequestNumber),
          job.commitSha!,
          dispatch.checkRunId,
        );
      }
      if (target.pending && context?.retryPending)
        throw new Error("Pull request test merge is pending");
      return null;
    }
    const { request } = await this.client(
      job,
      target.pullRequest ? "pr_checks" : "checks",
      context?.signal,
    );
    const details_url = dashboardRunUrl(this.options.dashboardOrigin, job.id);
    if (outcome === "card_required") {
      const url = new URL("/billing", this.options.billingOrigin ?? "https://dashboard.openci.org");
      url.searchParams.set("teamId", dispatch.teamId!);
      return writeCheckRun(
        request,
        this.options.appId,
        repo,
        target,
        job.workflowName!,
        queuedCheckExternalId(job),
        dispatch.checkRunId,
        {
          status: "queued",
          details_url,
          output: {
            title: "Waiting for a billing card",
            summary: `[Register a billing card for this team](${url.href}). This job will resume automatically once the card is confirmed.`,
          },
        },
      );
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
    return writeCheckRun(
      request,
      this.options.appId,
      repo,
      target,
      job.workflowName!,
      dispatch.runId!,
      dispatch.checkRunId,
      outcome
        ? {
            status: "completed",
            conclusion: outcome === "blocked" ? "neutral" : outcome,
            completed_at: new Date(dispatch.resultAt ?? dispatch.updatedAt).toISOString(),
            details_url,
            output,
          }
        : { status: "in_progress", details_url, output },
      { retryPending: context?.retryPending, beforeWrite: context?.beforeWrite },
    );
  }

  /** Called under the persisted job lease, before any executor can claim it. */
  async queuedCheck(
    job: Job,
    externalId: string,
    savedId: string | null,
    accountId: string,
    signal: AbortSignal,
  ): Promise<string | null> {
    const { request } = await this.client(
      job,
      job.pullRequestNumber === null ? "checks" : "pr_checks",
      signal,
    );
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
    const cancellingPullRequest = job.status === "CANCELLED" && !!job.pullRequestNumber;
    if (cancellingPullRequest && savedId) {
      await retirePullRequestCheck(
        request,
        { owner: job.owner, repo: job.repo },
        this.options.appId,
        Number(job.pullRequestNumber),
        job.commitSha!,
        savedId,
        undefined,
        "The build was cancelled.",
      );
      return null;
    }
    const target = await this.checkTarget(job, accountId, { signal });
    if (target.sha === null) {
      if (savedId && job.pullRequestNumber)
        await retirePullRequestCheck(
          request,
          { owner: job.owner, repo: job.repo },
          this.options.appId,
          Number(job.pullRequestNumber),
          job.commitSha!,
          savedId,
        );
      return null;
    }
    const details_url = dashboardRunUrl(this.options.dashboardOrigin, job.id);
    return writeCheckRun(
      request,
      this.options.appId,
      { owner: job.owner, repo: job.repo },
      target,
      job.workflowName!,
      externalId,
      savedId,
      job.status === "CANCELLED"
        ? {
            status: "completed",
            conclusion: "cancelled",
            completed_at: new Date().toISOString(),
            details_url,
            output: { title: job.workflowName!, summary: "The build was cancelled." },
          }
        : {
            status: "queued",
            details_url,
            output: { title: job.workflowName!, summary: "Waiting for the build to start." },
          },
      { existingOnly: cancellingPullRequest },
    );
  }
}
