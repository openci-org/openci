export interface WorkspaceRequest {
  workspaceId: string;
}

export interface StartGitHubDeviceFlowRequest extends WorkspaceRequest {
  clientId: string;
}

export interface StartGitHubDeviceFlowResponse {
  deviceCode: string;
  userCode: string;
  verificationUri: string;
  expiresIn: number;
  interval: number;
}

export interface CompleteGitHubDeviceFlowRequest extends WorkspaceRequest {
  clientId: string;
  deviceCode: string;
}

export interface CreateGitHubIssueRequest extends WorkspaceRequest {
  title: string;
  body?: string;
  repo: string;
  labels?: string[];
  statusId: string;
  priority: string;
  rank: number;
  dueDate?: string;
  issueId?: string;
}

export interface CreateGitHubSubIssueRequest extends WorkspaceRequest {
  parentIssueId: string;
  issueId?: string;
  title: string;
  body?: string;
}

export interface GitHubRepository {
  fullName: string;
  name: string;
  owner: string;
  private: boolean;
  defaultBranch: string;
}

export interface ListGitHubRepositoriesResponse {
  repositories: GitHubRepository[];
}

export interface ImportGitHubIssuesResponse {
  imported: number;
  repositories: number;
}

export interface SyncGitHubIssuesResponse {
  synced: number;
  failed: number;
}

export interface BackfillIssueKeysResponse {
  updated: number;
}

export interface BackfillCursorAgentPullRequestsResponse {
  inspected: number;
  linked: number;
}

export interface CreateGitHubIssueResponse {
  issueId: string;
  number: number;
  url: string;
}

export interface CreateGitHubSubIssueResponse extends CreateGitHubIssueResponse {
  parentIssueId: string;
}

export interface EstimateIssueWeightRequest extends WorkspaceRequest {
  issueId: string;
  force?: boolean;
}

export interface StartIssueCursorAgentRequest extends WorkspaceRequest {
  issueId: string;
}

export interface StartIssueCursorAgentResponse {
  issueId: string;
  agentId: string;
  runId: string;
  status: "running";
}

export interface IssueWeightEstimateResponse {
  value: number;
  confidence: number;
  reason: string;
  model: string;
  promptVersion: string;
  inputHash: string;
  source: "llm";
  status: "done";
}

export interface GitHubUserResponse {
  login?: unknown;
  avatar_url?: unknown;
}

export interface GitHubDeviceCodeResponse {
  device_code?: unknown;
  user_code?: unknown;
  verification_uri?: unknown;
  expires_in?: unknown;
  interval?: unknown;
  error?: unknown;
  error_description?: unknown;
}

export interface GitHubDeviceTokenResponse {
  access_token?: unknown;
  token_type?: unknown;
  scope?: unknown;
  error?: unknown;
  error_description?: unknown;
}

export interface GitHubRepositoriesResponseItem {
  full_name?: unknown;
  name?: unknown;
  owner?: { login?: unknown };
  private?: unknown;
  default_branch?: unknown;
}

export interface GitHubInstallationRepositoriesResponse {
  repositories?: GitHubRepositoriesResponseItem[];
}

export interface GitHubIssueResponseItem {
  id?: unknown;
  node_id?: unknown;
  number?: unknown;
  title?: unknown;
  body?: unknown;
  html_url?: unknown;
  state?: unknown;
  comments?: unknown;
  labels?: Array<string | { name?: unknown }>;
  updated_at?: unknown;
  created_at?: unknown;
  pull_request?: unknown;
  sub_issues_summary?: {
    total?: unknown;
    completed?: unknown;
    percent_completed?: unknown;
  };
  parent_issue_url?: unknown;
}

export interface GitHubPullRequestResponseItem {
  number?: unknown;
  title?: unknown;
  body?: unknown;
  html_url?: unknown;
  state?: unknown;
  merged?: unknown;
  created_at?: unknown;
  head?: {
    ref?: unknown;
  };
}

export interface GitHubPullRequestLinkedIssue {
  number: number;
  title: string;
  url: string;
  state: string;
}

export interface GitHubPullRequestLinkedIssuesGraphqlResponse {
  data?: {
    repository?: {
      pullRequest?: {
        closingIssuesReferences?: {
          nodes?: Array<{
            number?: unknown;
            title?: unknown;
            url?: unknown;
            state?: unknown;
          } | null>;
        };
      } | null;
    } | null;
  };
}

export interface GitHubPullRequestWebhookPayload {
  action?: unknown;
  changes?: {
    body?: {
      from?: unknown;
    };
    title?: {
      from?: unknown;
    };
  };
  repository?: {
    full_name?: unknown;
  };
  pull_request?: {
    number?: unknown;
    title?: unknown;
    body?: unknown;
    html_url?: unknown;
    state?: unknown;
    merged?: unknown;
    created_at?: unknown;
    head?: {
      ref?: unknown;
    };
  };
}

export interface GitHubPushWebhookPayload {
  ref?: unknown;
  repository?: {
    full_name?: unknown;
    default_branch?: unknown;
  };
  commits?: Array<{
    id?: unknown;
    timestamp?: unknown;
    added?: unknown[];
    modified?: unknown[];
  }>;
}

export interface BranchLogEntry {
  branch: string;
  at: string;
}

export interface GitHubContentFileResponse {
  content?: unknown;
  encoding?: unknown;
}

export interface GitHubIssueWebhookPayload {
  action?: unknown;
  repository?: {
    full_name?: unknown;
  };
  issue?: {
    node_id?: unknown;
    number?: unknown;
    title?: unknown;
    body?: unknown;
    html_url?: unknown;
    state?: unknown;
    state_reason?: unknown;
    comments?: unknown;
    labels?: Array<string | { name?: unknown }>;
    updated_at?: unknown;
    created_at?: unknown;
    pull_request?: unknown;
  };
}
