export type BuildStatus = "queued" | "in_progress" | "success" | "failure" | "cancelled";
export type RunnerOS = "macos" | "linux";

export interface Build {
  id: string;
  project_id: string;
  status: BuildStatus;
  yaml_definition: string | null;
  runner_os: RunnerOS;
  github_owner: string;
  github_repo: string;
  commit_sha: string | null;
  branch: string | null;
  tag_name: string | null;
  pull_request_number: number | null;
  github_event: string | null;
  github_sender: string | null;
  installation_token: string | null;
  created_at: string;
  updated_at: string;
}

export interface Workflow {
  id: string;
  project_id: string;
  name: string;
  yaml_definition: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}
