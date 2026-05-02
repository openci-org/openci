export declare const issueWeightPromptVersion = "issue-weight-v1";
export declare function truncateText(value: string, maxLength: number): string;
export declare function issueWeightInput(issue: Record<string, unknown>): Record<string, unknown>;
export declare function issueWeightInputHash(issue: Record<string, unknown>): string;
export declare function parseWeightEstimateResponse(responseText: string): {
    value: number;
    confidence: number;
    reason: string;
};
