const messages = {
  conflicts:
    "This pull request has merge conflicts with its base branch. Resolve the conflicts and push the updated branch to run CI.",
  not_ready:
    "GitHub's test merge commit is not ready. Wait a moment and rerun this job. If it is still unavailable, check the pull request's merge status on GitHub.",
  stale_merge:
    "GitHub's test merge commit still does not match the current base branch after repeated requests. The workflow was not started. Rerun this job after GitHub refreshes the pull request's merge information.",
  closed:
    "This pull request is closed or already merged. Reopen it or run CI on an open pull request.",
  head_changed:
    "The pull request changed after this job was queued. Run CI for the latest pull request commit.",
  unavailable:
    "GitHub's test merge commit could not be read. Rerun this job. If it still fails, check the GitHub App's repository access and read permissions.",
} as const;

/** Validated identifiers only; never include response bodies or authentication. */
export interface MergeReadinessDiagnostics {
  attempts: number;
  elapsedMs: number;
  requestId?: string;
  headSha?: string;
  baseSha?: string;
  mergeSha?: string;
  mergeBaseSha?: string;
}

/** Only these fixed messages may be published; API errors can contain secrets. */
export class PullRequestCheckoutError extends Error {
  constructor(
    readonly reason: keyof typeof messages,
    readonly diagnostics?: MergeReadinessDiagnostics,
  ) {
    super(messages[reason]);
  }
}
