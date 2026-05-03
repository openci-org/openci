interface WorkspaceRequest {
    workspaceId: string;
}
interface ConnectGitHubRequest extends WorkspaceRequest {
    accessToken: string;
}
interface StartGitHubDeviceFlowRequest extends WorkspaceRequest {
    clientId: string;
}
interface StartGitHubDeviceFlowResponse {
    deviceCode: string;
    userCode: string;
    verificationUri: string;
    expiresIn: number;
    interval: number;
}
interface CompleteGitHubDeviceFlowRequest extends WorkspaceRequest {
    clientId: string;
    deviceCode: string;
}
interface CreateGitHubIssueRequest extends WorkspaceRequest {
    title: string;
    body?: string;
    repo: string;
    assignee?: string;
    labels?: string[];
    statusId: string;
    priority: string;
    rank: number;
    dueDate?: string;
}
interface GitHubRepository {
    fullName: string;
    name: string;
    owner: string;
    private: boolean;
    defaultBranch: string;
}
interface ListGitHubRepositoriesResponse {
    repositories: GitHubRepository[];
}
interface ImportGitHubIssuesResponse {
    imported: number;
    repositories: number;
}
interface SyncGitHubIssuesResponse {
    synced: number;
    failed: number;
}
interface BackfillIssueKeysResponse {
    updated: number;
}
interface BackfillCursorAgentPullRequestsResponse {
    inspected: number;
    linked: number;
}
interface CreateGitHubIssueResponse {
    issueId: string;
    number: number;
    url: string;
}
interface EstimateIssueWeightRequest extends WorkspaceRequest {
    issueId: string;
    force?: boolean;
}
interface StartIssueCursorAgentRequest extends WorkspaceRequest {
    issueId: string;
}
interface StartIssueCursorAgentResponse {
    issueId: string;
    agentId: string;
    runId: string;
    status: "running";
}
interface IssueWeightEstimateResponse {
    value: number;
    confidence: number;
    reason: string;
    model: string;
    promptVersion: string;
    inputHash: string;
    source: "llm";
    status: "done";
}
interface ListIssueCommentsRequest extends WorkspaceRequest {
    issueId: string;
}
interface AddIssueCommentRequest extends WorkspaceRequest {
    issueId: string;
    body: string;
}
interface IssueCommentItem {
    id: number;
    body: string;
    user: string;
    avatarUrl: string;
    createdAt: string;
    updatedAt: string;
}
interface ListIssueCommentsResponse {
    comments: IssueCommentItem[];
}
interface AddIssueCommentResponse {
    comment: IssueCommentItem;
}
export declare const connectGitHub: import("firebase-functions/v2/https").CallableFunction<ConnectGitHubRequest, Promise<{
    login: string;
}>, unknown>;
export declare const startGitHubDeviceFlow: import("firebase-functions/v2/https").CallableFunction<StartGitHubDeviceFlowRequest, Promise<StartGitHubDeviceFlowResponse>, unknown>;
export declare const completeGitHubDeviceFlow: import("firebase-functions/v2/https").CallableFunction<CompleteGitHubDeviceFlowRequest, Promise<{
    login: string;
}>, unknown>;
export declare const listGitHubRepositories: import("firebase-functions/v2/https").CallableFunction<WorkspaceRequest, Promise<ListGitHubRepositoriesResponse>, unknown>;
export declare const importGitHubIssues: import("firebase-functions/v2/https").CallableFunction<WorkspaceRequest, Promise<ImportGitHubIssuesResponse>, unknown>;
export declare const createGitHubIssue: import("firebase-functions/v2/https").CallableFunction<CreateGitHubIssueRequest, Promise<CreateGitHubIssueResponse>, unknown>;
export declare const startIssueCursorAgent: import("firebase-functions/v2/https").CallableFunction<StartIssueCursorAgentRequest, Promise<StartIssueCursorAgentResponse>, unknown>;
export declare const backfillIssueKeys: import("firebase-functions/v2/https").CallableFunction<WorkspaceRequest, Promise<BackfillIssueKeysResponse>, unknown>;
export declare const backfillCursorAgentPullRequests: import("firebase-functions/v2/https").CallableFunction<WorkspaceRequest, Promise<BackfillCursorAgentPullRequestsResponse>, unknown>;
export declare const githubPullRequestWebhook: import("firebase-functions/v2/https").HttpsFunction;
export declare const syncGitHubIssues: import("firebase-functions/v2/https").CallableFunction<WorkspaceRequest, Promise<SyncGitHubIssuesResponse>, unknown>;
export declare const listIssueComments: import("firebase-functions/v2/https").CallableFunction<ListIssueCommentsRequest, Promise<ListIssueCommentsResponse>, unknown>;
export declare const addIssueComment: import("firebase-functions/v2/https").CallableFunction<AddIssueCommentRequest, Promise<AddIssueCommentResponse>, unknown>;
export declare const estimateIssueWeight: import("firebase-functions/v2/https").CallableFunction<EstimateIssueWeightRequest, Promise<{
    issueId: string;
    weightEstimate: IssueWeightEstimateResponse;
}>, unknown>;
export declare const issueLifecycleEventLogger: import("firebase-functions/core").CloudFunction<import("firebase-functions/v2/firestore").FirestoreEvent<import("firebase-functions/v2").Change<import("firebase-functions/v2/firestore").DocumentSnapshot> | undefined, {
    workspaceId: string;
    issueId: string;
}>>;
export declare const autoEstimateIssueWeightOnIssueWrite: import("firebase-functions/core").CloudFunction<import("firebase-functions/v2/firestore").FirestoreEvent<import("firebase-functions/v2").Change<import("firebase-functions/v2/firestore").DocumentSnapshot> | undefined, {
    workspaceId: string;
    issueId: string;
}>>;
export declare const autoSyncIssueToGitHubOnIssueWrite: import("firebase-functions/core").CloudFunction<import("firebase-functions/v2/firestore").FirestoreEvent<import("firebase-functions/v2").Change<import("firebase-functions/v2/firestore").DocumentSnapshot> | undefined, {
    workspaceId: string;
    issueId: string;
}>>;
export {};
