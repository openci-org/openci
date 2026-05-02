export const imaLinkedIssueBlockStart = "<!-- ima-linked-issue:start -->";
export const imaLinkedIssueBlockEnd = "<!-- ima-linked-issue:end -->";

const issueKeyPattern = /(?:^|[^A-Z0-9])([A-Z][A-Z0-9]+-\d+)(?=$|[^A-Z0-9])/iu;
const managedBlockPattern =
  /<!-- ima-linked-issue:start -->[\s\S]*?<!-- ima-linked-issue:end -->\n*/u;

export function normalizeIssueKeyPrefix(value: string): string {
  const normalized = value.trim().toUpperCase().replace(/[^A-Z0-9]/gu, "");
  return normalized.length === 0 ? "IMA" : normalized;
}

export function issueKey(prefix: string, number: number): string {
  return `${normalizeIssueKeyPrefix(prefix)}-${number}`;
}

export function extractIssueKey(...sources: Array<string | undefined | null>): string | null {
  for (const source of sources) {
    const match = source?.match(issueKeyPattern);
    const key = match?.[1];
    if (key !== undefined) {
      return key.toUpperCase();
    }
  }
  return null;
}

export function linkedIssueBlock(githubIssueNumber: number, imaIssueKey: string): string {
  return [
    imaLinkedIssueBlockStart,
    `Refs #${githubIssueNumber}`,
    `Ima: ${imaIssueKey}`,
    imaLinkedIssueBlockEnd,
  ].join("\n");
}

export function upsertLinkedIssueBlock(
  body: string | undefined | null,
  githubIssueNumber: number,
  imaIssueKey: string,
): string {
  const trimmedBody = (body ?? "").replace(managedBlockPattern, "").trim();
  const block = linkedIssueBlock(githubIssueNumber, imaIssueKey);
  return trimmedBody.length === 0 ? block : `${trimmedBody}\n\n${block}`;
}
