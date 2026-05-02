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
interface CreateGitHubIssueResponse {
    issueId: string;
    number: number;
    url: string;
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
export declare const syncGitHubIssues: import("firebase-functions/v2/https").CallableFunction<WorkspaceRequest, Promise<SyncGitHubIssuesResponse>, unknown>;
export declare const autoSyncIssueToGitHub: import("firebase-functions/core").CloudFunction<import("firebase-functions/v2/firestore").FirestoreEvent<import("firebase-functions/v2").Change<import("firebase-functions/v2/firestore").DocumentSnapshot> | undefined, {
    issueId: string;
    workspaceId: string;
}>>;
export {};
