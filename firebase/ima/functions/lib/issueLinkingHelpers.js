"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.imaLinkedIssueBlockEnd = exports.imaLinkedIssueBlockStart = void 0;
exports.normalizeIssueKeyPrefix = normalizeIssueKeyPrefix;
exports.issueKey = issueKey;
exports.extractIssueKey = extractIssueKey;
exports.linkedIssueBlock = linkedIssueBlock;
exports.upsertLinkedIssueBlock = upsertLinkedIssueBlock;
exports.issueStatusForPullRequest = issueStatusForPullRequest;
exports.imaLinkedIssueBlockStart = "<!-- ima-linked-issue:start -->";
exports.imaLinkedIssueBlockEnd = "<!-- ima-linked-issue:end -->";
const issueKeyPattern = /(?:^|[^A-Z0-9])([A-Z]{2}[A-Z0-9]*-\d+)(?=$|[^A-Z0-9])/iu;
const managedBlockPattern = /<!-- ima-linked-issue:start -->[\s\S]*?<!-- ima-linked-issue:end -->\n*/u;
function normalizeIssueKeyPrefix(value) {
    const normalized = value.trim().toUpperCase().replace(/[^A-Z0-9]/gu, "");
    return normalized.length === 0 ? "IMA" : normalized;
}
function issueKey(prefix, number) {
    return `${normalizeIssueKeyPrefix(prefix)}-${number}`;
}
function extractIssueKey(...sources) {
    for (const source of sources) {
        const match = source?.match(issueKeyPattern);
        const key = match?.[1];
        if (key !== undefined) {
            return key.toUpperCase();
        }
    }
    return null;
}
function linkedIssueBlock(githubIssueNumber, imaIssueKey) {
    return [
        exports.imaLinkedIssueBlockStart,
        `Fixes #${githubIssueNumber}`,
        `Ima: ${imaIssueKey}`,
        exports.imaLinkedIssueBlockEnd,
    ].join("\n");
}
function upsertLinkedIssueBlock(body, githubIssueNumber, imaIssueKey) {
    const trimmedBody = (body ?? "").replace(managedBlockPattern, "").trim();
    const block = linkedIssueBlock(githubIssueNumber, imaIssueKey);
    return trimmedBody.length === 0 ? block : `${trimmedBody}\n\n${block}`;
}
function issueStatusForPullRequest({ action, merged, currentStatusId, reviewStatusId = "review", doneStatusId = "done", }) {
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
//# sourceMappingURL=issueLinkingHelpers.js.map