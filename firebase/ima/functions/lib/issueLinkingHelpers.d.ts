export declare const imaLinkedIssueBlockStart = "<!-- ima-linked-issue:start -->";
export declare const imaLinkedIssueBlockEnd = "<!-- ima-linked-issue:end -->";
export declare function normalizeIssueKeyPrefix(value: string): string;
export declare function issueKey(prefix: string, number: number): string;
export declare function extractIssueKey(...sources: Array<string | undefined | null>): string | null;
export declare function linkedIssueBlock(githubIssueNumber: number, imaIssueKey: string): string;
export declare function upsertLinkedIssueBlock(body: string | undefined | null, githubIssueNumber: number, imaIssueKey: string): string;
