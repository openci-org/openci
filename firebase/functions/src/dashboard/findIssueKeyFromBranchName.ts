const issueKeyPattern = /(?:^|[^A-Z0-9])([A-Z]{2}[A-Z0-9]*)[-_](\d+)(?=$|[^A-Z0-9])/iu;

export function findIssueKeyFromBranchName(branch: string): string | null {
  const match = branch.match(issueKeyPattern);
  const prefix = match?.[1];
  const number = match?.[2];
  return prefix === undefined || number === undefined ? null : `${prefix}-${number}`.toUpperCase();
}
