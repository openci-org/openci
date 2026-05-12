export const imaLinkedIssueBlockStart = "<!-- ima-linked-issue:start -->";
export const imaLinkedIssueBlockEnd = "<!-- ima-linked-issue:end -->";

const issueKeyPattern = /(?:^|[^A-Z0-9])([A-Z]{2}[A-Z0-9]*-\d+)(?=$|[^A-Z0-9])/iu;
const managedBlockPattern =
  /<!-- ima-linked-issue:start -->[\s\S]*?<!-- ima-linked-issue:end -->\n*/u;

export function normalizeIssueKeyPrefix(value: string): string {
  const normalized = value
    .trim()
    .toUpperCase()
    .replace(/[^A-Z0-9]/gu, "");
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
    `Fixes #${githubIssueNumber}`,
    `Ima: ${imaIssueKey}`,
    imaLinkedIssueBlockEnd,
  ].join("\n");
}

export interface LinkedIssueBlockEntry {
  githubIssueNumber: number;
  imaIssueKey: string;
}

function linkedIssueEntriesFromBlock(block: string): Map<number, string> {
  const entries = new Map<number, string>();
  for (const match of block.matchAll(/Fixes #(\d+)\s*\nIma: ([^\n]+)/gu)) {
    const number = Number(match[1]);
    const key = match[2]?.trim();
    if (Number.isInteger(number) && number > 0 && key !== undefined && key.length > 0) {
      entries.set(number, key);
    }
  }
  return entries;
}

function linkedIssueBlockFromEntries(entries: Map<number, string>): string {
  return [
    imaLinkedIssueBlockStart,
    ...Array.from(entries.entries()).flatMap(([number, key]) => [
      `Fixes #${number}`,
      `Ima: ${key}`,
    ]),
    imaLinkedIssueBlockEnd,
  ].join("\n");
}

export function upsertLinkedIssueBlocks(
  body: string | undefined | null,
  linkedIssues: LinkedIssueBlockEntry[],
): string {
  const currentBody = body ?? "";
  const existingBlock = currentBody.match(managedBlockPattern)?.[0] ?? "";
  const entries = linkedIssueEntriesFromBlock(existingBlock);
  for (const linkedIssue of linkedIssues) {
    entries.set(linkedIssue.githubIssueNumber, linkedIssue.imaIssueKey);
  }

  const trimmedBody = currentBody.replace(managedBlockPattern, "").trim();
  const block = linkedIssueBlockFromEntries(entries);
  return trimmedBody.length === 0 ? block : `${trimmedBody}\n\n${block}`;
}

export function upsertLinkedIssueBlock(
  body: string | undefined | null,
  githubIssueNumber: number,
  imaIssueKey: string,
): string {
  return upsertLinkedIssueBlocks(body, [{ githubIssueNumber, imaIssueKey }]);
}

export function removeLinkedIssueBlocks(
  body: string | undefined | null,
  githubIssueNumbers: number[],
): string {
  const currentBody = body ?? "";
  const existingBlock = currentBody.match(managedBlockPattern)?.[0];
  if (existingBlock === undefined) {
    return currentBody;
  }

  const entries = linkedIssueEntriesFromBlock(existingBlock);
  for (const number of githubIssueNumbers) {
    entries.delete(number);
  }

  const trimmedBody = currentBody.replace(managedBlockPattern, "").trim();
  if (entries.size === 0) {
    return trimmedBody;
  }

  const block = linkedIssueBlockFromEntries(entries);
  return trimmedBody.length === 0 ? block : `${trimmedBody}\n\n${block}`;
}

export function replaceLinkedIssueBlocks(
  body: string | undefined | null,
  linkedIssues: LinkedIssueBlockEntry[],
): string {
  const currentBody = body ?? "";
  const trimmedBody = currentBody.replace(managedBlockPattern, "").trim();
  if (linkedIssues.length === 0) {
    return trimmedBody;
  }

  const entries = new Map<number, string>();
  for (const linkedIssue of linkedIssues) {
    entries.set(linkedIssue.githubIssueNumber, linkedIssue.imaIssueKey);
  }

  const block = linkedIssueBlockFromEntries(entries);
  return trimmedBody.length === 0 ? block : `${trimmedBody}\n\n${block}`;
}

export function bodyWithoutLinkedIssueBlock(body: string | undefined | null): string {
  return (body ?? "").replace(managedBlockPattern, "").trim();
}

export function isOnlyLinkedIssueBlockChange(
  before: string | undefined | null,
  after: string | undefined | null,
): boolean {
  return bodyWithoutLinkedIssueBlock(before) === bodyWithoutLinkedIssueBlock(after);
}

export function issueStatusForPullRequest({
  action,
  merged,
  currentStatusId,
  reviewStatusId = "review",
  doneStatusId = "done",
}: {
  action: string;
  merged: boolean;
  currentStatusId: string;
  reviewStatusId?: string;
  doneStatusId?: string;
}): string | null {
  if (action === "closed") {
    return merged ? doneStatusId : null;
  }

  if (action === "reopened") {
    return reviewStatusId;
  }

  if (currentStatusId === doneStatusId) {
    return null;
  }

  return currentStatusId === reviewStatusId ? null : reviewStatusId;
}
