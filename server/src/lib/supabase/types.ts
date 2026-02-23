// Supabase database types for OpenCI
// These match the schema defined in supabase/migrations/

export type OrgRole = "owner" | "admin" | "member";
export type ProjectRole = "admin" | "write" | "read";
export type InvitationStatus = "pending" | "accepted" | "expired" | "cancelled";
export type BuildStatus =
  | "queued"
  | "in_progress"
  | "success"
  | "failure"
  | "cancelled";
export type LogLevel = "info" | "warning" | "error";
export type TriggerType = "push" | "pull_request" | "tag" | "release";

export interface Profile {
  id: string;
  full_name: string | null;
  avatar_url: string | null;
  fcm_tokens: string[];
  notification_preference: string;
  created_at: string;
  updated_at: string;
}

export interface Organization {
  id: string;
  name: string;
  slug: string;
  stripe_customer_id: string | null;
  stripe_subscription_id: string | null;
  billing_enabled: boolean;
  created_at: string;
  updated_at: string;
}

export interface OrgMember {
  id: string;
  org_id: string;
  user_id: string;
  role: OrgRole;
  created_at: string;
  updated_at: string;
}

export interface OrgInvitation {
  id: string;
  org_id: string;
  invited_by: string;
  email: string;
  role: OrgRole;
  token: string;
  status: InvitationStatus;
  expires_at: string;
  created_at: string;
  updated_at: string;
}

export interface Project {
  id: string;
  org_id: string;
  name: string;
  slug: string;
  description: string | null;
  framework: string | null;
  platforms: string[];
  created_at: string;
  updated_at: string;
}

export interface ProjectMember {
  id: string;
  project_id: string;
  user_id: string;
  role: ProjectRole;
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

export interface WorkflowTrigger {
  id: string;
  workflow_id: string;
  trigger_type: TriggerType;
  branch_pattern: string | null;
  github_repo: string;
  created_at: string;
  updated_at: string;
}

export interface Build {
  id: string;
  project_id: string;
  workflow_id: string | null;
  status: BuildStatus;
  github_owner: string;
  github_repo: string;
  commit_sha: string | null;
  branch: string | null;
  tag_name: string | null;
  pull_request_number: number | null;
  github_event: string | null;
  github_action: string | null;
  github_sender: string | null;
  installation_id: number | null;
  installation_token: string | null;
  token_expires_at: string | null;
  check_run_id: number | null;
  retried_from_build_id: string | null;
  run_count: number;
  latest_run_id: string | null;
  log_archive_path: string | null;
  created_at: string;
  updated_at: string;
}

export interface BuildRun {
  id: string;
  build_id: string;
  status: "in_progress" | "completed";
  conclusion: "success" | "failure" | "cancelled" | null;
  created_at: string;
  updated_at: string;
}

export interface BuildLog {
  id: number;
  build_run_id: string;
  build_id: string;
  message: string;
  level: LogLevel;
  stack_trace: string | null;
  step_index: number | null;
  step_name: string | null;
  created_at: string;
}

export interface EnvironmentVariable {
  id: string;
  project_id: string;
  key: string;
  value: string | null;
  is_secret: boolean;
  vault_secret_id: string | null;
  auto_increment: boolean;
  created_at: string;
  updated_at: string;
}

export interface Integration {
  id: string;
  org_id: string;
  provider: string;
  installation_id: number;
  github_account: string | null;
  created_at: string;
  updated_at: string;
}

export interface WorkerConfig {
  key: string;
  value: string;
  updated_at: string;
}

// Joined types for common UI queries

export interface OrganizationWithRole extends Organization {
  role: OrgRole;
}

export interface ProjectWithLastBuild extends Project {
  last_build: Pick<Build, "id" | "status" | "branch" | "created_at"> | null;
  build_count: number;
  workflow_count: number;
}

export interface WorkflowWithTriggers extends Workflow {
  workflow_triggers: WorkflowTrigger[];
  last_build: Pick<Build, "id" | "status" | "created_at"> | null;
}
