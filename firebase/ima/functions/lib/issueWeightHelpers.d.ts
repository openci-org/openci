export declare const issueWeightPromptVersion = "issue-weight-v2";
export declare const validWeights: readonly [1, 2, 4, 8, 16, 32];
export type IssueWeight = (typeof validWeights)[number];
export declare function isValidWeight(value: number): value is IssueWeight;
export declare function isAdjacentWeight(a: number, b: number): boolean;
export declare function truncateText(value: string, maxLength: number): string;
export declare function issueWeightInput(issue: Record<string, unknown>): Record<string, unknown>;
export declare function issueWeightInputHash(issue: Record<string, unknown>): string;
export declare function parseWeightEstimateResponse(responseText: string): {
    value: number;
    confidence: number;
    reason: string;
};
