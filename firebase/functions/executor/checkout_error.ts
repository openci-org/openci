const messages = {
  conflicts:
    "This pull request has merge conflicts with its base branch. Resolve the conflicts and push the updated branch to run CI.",
  not_ready:
    "GitHub's test merge commit is not ready. Wait a moment and rerun this job. If it is still unavailable, check the pull request's merge status on GitHub.",
  closed:
    "This pull request is closed or already merged. Reopen it or run CI on an open pull request.",
  head_changed:
    "The pull request changed after this job was queued. Run CI for the latest pull request commit.",
  unavailable:
    "GitHub's test merge commit could not be read. Rerun this job. If it still fails, check the GitHub App's repository access and read permissions.",
} as const;

/** Only these fixed messages may be published; API errors can contain secrets. */
export class PullRequestCheckoutError extends Error {
  constructor(reason: keyof typeof messages) {
    super(messages[reason]);
  }
}
