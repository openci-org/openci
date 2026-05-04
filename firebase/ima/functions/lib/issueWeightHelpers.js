"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.validWeights = exports.issueWeightPromptVersion = void 0;
exports.isValidWeight = isValidWeight;
exports.isAdjacentWeight = isAdjacentWeight;
exports.truncateText = truncateText;
exports.issueWeightInput = issueWeightInput;
exports.issueWeightInputHash = issueWeightInputHash;
exports.parseWeightEstimateResponse = parseWeightEstimateResponse;
const node_crypto_1 = require("node:crypto");
exports.issueWeightPromptVersion = "issue-weight-v2";
const maxIssueBodyCharsForWeight = 4000;
exports.validWeights = [1, 2, 4, 8, 16, 32];
function isValidWeight(value) {
    return exports.validWeights.includes(value);
}
function isAdjacentWeight(a, b) {
    const idxA = exports.validWeights.indexOf(a);
    const idxB = exports.validWeights.indexOf(b);
    if (idxA < 0 || idxB < 0)
        return false;
    return Math.abs(idxA - idxB) <= 1;
}
function asString(value, fallback = "") {
    return typeof value === "string" && value.length > 0 ? value : fallback;
}
function asNumber(value, fallback = 0) {
    return typeof value === "number" ? value : fallback;
}
function asStringList(value) {
    if (!Array.isArray(value)) {
        return [];
    }
    return value.filter((item) => typeof item === "string" && item.length > 0);
}
function truncateText(value, maxLength) {
    return value.length <= maxLength ? value : `${value.slice(0, maxLength)}\n[truncated]`;
}
function issueWeightInput(issue) {
    return {
        title: truncateText(asString(issue.title), 300),
        body: truncateText(asString(issue.body), maxIssueBodyCharsForWeight),
        repo: asString(issue.repo),
        labels: asStringList(issue.labels).slice(0, 30),
        comments: asNumber(issue.comments),
        priority: asString(issue.priority, "medium"),
    };
}
function issueWeightInputHash(issue) {
    return (0, node_crypto_1.createHash)("sha256")
        .update(JSON.stringify({ promptVersion: exports.issueWeightPromptVersion, issue: issueWeightInput(issue) }))
        .digest("hex");
}
function parseWeightEstimateResponse(responseText) {
    const start = responseText.indexOf("{");
    const end = responseText.lastIndexOf("}");
    if (start < 0 || end <= start) {
        throw new Error("LLM response did not include JSON");
    }
    const parsed = JSON.parse(responseText.slice(start, end + 1));
    const value = asNumber(parsed.value);
    const confidence = asNumber(parsed.confidence);
    const reason = truncateText(asString(parsed.reason), 240);
    if (!Number.isInteger(value) || !isValidWeight(value)) {
        throw new Error(`LLM response value must be one of ${exports.validWeights.join(", ")}`);
    }
    if (confidence < 0 || confidence > 1) {
        throw new Error("LLM response confidence must be between 0 and 1");
    }
    if (reason.length === 0) {
        throw new Error("LLM response reason is required");
    }
    return { value, confidence, reason };
}
//# sourceMappingURL=issueWeightHelpers.js.map