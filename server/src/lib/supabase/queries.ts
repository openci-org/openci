// Server-side Supabase query helpers for OpenCI
// All functions require a server-side Supabase client (createClient from @/lib/supabase/server)

import type { SupabaseClient } from "@supabase/supabase-js";
import type {
  Build,
  BuildLog,
  EnvironmentVariable,
  Organization,
  OrganizationWithRole,
  OrgInvitation,
  OrgMember,
  WorkflowWithTriggers,
} from "./types";

// Returns all organizations the current user belongs to, with their role.
export async function getUserOrgs(supabase: SupabaseClient): Promise<OrganizationWithRole[]> {
  const { data, error } = await supabase
    .from("org_members")
    .select(
      `
      role,
      organizations (
        id, name, slug, billing_enabled, stripe_customer_id,
        stripe_subscription_id, created_at, updated_at
      )
    `,
    )
    .order("created_at", { ascending: true });

  if (error || !data) return [];

  const seen = new Set<string>();
  const result: OrganizationWithRole[] = [];
  for (const row of data) {
    const org = row.organizations as unknown as Organization;
    if (!org?.id || seen.has(org.id)) continue;
    seen.add(org.id);
    result.push({ ...org, role: row.role });
  }
  return result;
}

// Returns a single organization by slug, or null if not found / not a member.
export async function getOrgBySlug(
  supabase: SupabaseClient,
  slug: string,
): Promise<OrganizationWithRole | null> {
  const orgs = await getUserOrgs(supabase);
  return orgs.find((o) => o.slug === slug) ?? null;
}

// Returns builds for an org, newest first.
export async function getOrgBuilds(
  supabase: SupabaseClient,
  orgId: string,
  limit = 50,
): Promise<Build[]> {
  const { data, error } = await supabase
    .from("builds")
    .select("*")
    .eq("org_id", orgId)
    .order("created_at", { ascending: false })
    .limit(limit);

  if (error || !data) return [];
  return data as Build[];
}

// Returns a single build by id.
export async function getBuildById(supabase: SupabaseClient, buildId: string) {
  const { data, error } = await supabase
    .from("builds")
    .select(
      `
      *,
      build_runs (
        id, status, conclusion, created_at, updated_at
      )
    `,
    )
    .eq("id", buildId)
    .single();

  if (error) return null;
  return data;
}

// Returns logs for a build run, in order.
export async function getBuildRunLogs(
  supabase: SupabaseClient,
  buildRunId: string,
): Promise<BuildLog[]> {
  const { data, error } = await supabase
    .from("build_logs")
    .select("*")
    .eq("build_run_id", buildRunId)
    .order("id", { ascending: true });

  if (error || !data) return [];
  return data as BuildLog[];
}

// Returns a signed download URL for an archived build log file in Supabase Storage.
export async function getBuildLogDownloadUrl(
  supabase: SupabaseClient,
  logArchivePath: string,
): Promise<string | null> {
  const { data, error } = await supabase.storage
    .from("build-logs")
    .createSignedUrl(logArchivePath, 300);

  if (error || !data?.signedUrl) return null;
  return data.signedUrl;
}

// Returns workflows for an org with their triggers.
export async function getOrgWorkflows(
  supabase: SupabaseClient,
  orgId: string,
): Promise<WorkflowWithTriggers[]> {
  const { data, error } = await supabase
    .from("workflows")
    .select(
      `
      *,
      workflow_triggers (*),
      builds (
        id, status, created_at
      )
    `,
    )
    .eq("org_id", orgId)
    .order("created_at", { ascending: true });

  if (error || !data) return [];

  return data.map((wf) => {
    const builds = (wf.builds as Build[]) ?? [];
    const lastBuild =
      builds.length > 0
        ? builds.reduce((a, b) => (new Date(a.created_at) > new Date(b.created_at) ? a : b))
        : null;

    return {
      ...wf,
      workflow_triggers: wf.workflow_triggers ?? [],
      last_build: lastBuild
        ? {
            id: lastBuild.id,
            status: lastBuild.status,
            created_at: lastBuild.created_at,
          }
        : null,
    };
  });
}

// Returns a single workflow with its triggers, or null if not found.
export async function getWorkflowById(
  supabase: SupabaseClient,
  workflowId: string,
): Promise<WorkflowWithTriggers | null> {
  const { data, error } = await supabase
    .from("workflows")
    .select(
      `
      *,
      workflow_triggers (*),
      builds (
        id, status, created_at
      )
    `,
    )
    .eq("id", workflowId)
    .single();

  if (error || !data) return null;

  const builds = (data.builds as Build[]) ?? [];
  const lastBuild =
    builds.length > 0
      ? builds.reduce((a, b) => (new Date(a.created_at) > new Date(b.created_at) ? a : b))
      : null;

  return {
    ...data,
    workflow_triggers: data.workflow_triggers ?? [],
    last_build: lastBuild
      ? {
          id: lastBuild.id,
          status: lastBuild.status,
          created_at: lastBuild.created_at,
        }
      : null,
  };
}

// Returns environment variables for an org (excludes plain values for secrets).
export async function getOrgEnvVars(
  supabase: SupabaseClient,
  orgId: string,
): Promise<EnvironmentVariable[]> {
  const { data, error } = await supabase
    .from("environment_variables")
    .select("id, org_id, key, is_secret, auto_increment, created_at, updated_at")
    .eq("org_id", orgId)
    .order("key", { ascending: true });

  if (error || !data) return [];
  return data as EnvironmentVariable[];
}

// Returns a single environment variable by id.
export async function getEnvVarById(
  supabase: SupabaseClient,
  envVarId: string,
): Promise<EnvironmentVariable | null> {
  const { data, error } = await supabase
    .from("environment_variables")
    .select("id, org_id, key, is_secret, vault_secret_id, auto_increment, created_at, updated_at")
    .eq("id", envVarId)
    .single();

  if (error || !data) return null;
  return data as EnvironmentVariable;
}

// Returns org members with profile info.
export async function getOrgMembers(
  supabase: SupabaseClient,
  orgId: string,
): Promise<
  (OrgMember & {
    profile: { full_name: string | null; avatar_url: string | null } | null;
    email: string | null;
  })[]
> {
  const { data, error } = await supabase
    .from("org_members")
    .select(
      `
      id, org_id, user_id, role, created_at, updated_at,
      profiles (full_name, avatar_url)
    `,
    )
    .eq("org_id", orgId)
    .order("created_at", { ascending: true });

  if (error || !data) return [];

  return data.map((m) => ({
    id: m.id,
    org_id: m.org_id,
    user_id: m.user_id,
    role: m.role,
    created_at: m.created_at,
    updated_at: m.updated_at,
    profile: m.profiles as unknown as {
      full_name: string | null;
      avatar_url: string | null;
    } | null,
    email: null,
  }));
}

// Returns pending invitations for an org.
export async function getOrgInvitations(
  supabase: SupabaseClient,
  orgId: string,
): Promise<OrgInvitation[]> {
  const { data, error } = await supabase
    .from("org_invitations")
    .select("*")
    .eq("org_id", orgId)
    .eq("status", "pending")
    .order("created_at", { ascending: false });

  if (error || !data) return [];
  return data as OrgInvitation[];
}

// Returns org stats for the dashboard.
export async function getOrgStats(
  supabase: SupabaseClient,
  orgId: string,
): Promise<{
  totalBuilds: number;
  successBuilds: number;
  activeWorkflows: number;
}> {
  const [totalResult, successResult, workflowsResult] = await Promise.all([
    supabase.from("builds").select("id", { count: "exact", head: true }).eq("org_id", orgId),
    supabase
      .from("builds")
      .select("id", { count: "exact", head: true })
      .eq("org_id", orgId)
      .eq("status", "success"),
    supabase
      .from("workflows")
      .select("id", { count: "exact", head: true })
      .eq("org_id", orgId)
      .eq("is_active", true),
  ]);

  return {
    totalBuilds: totalResult.count ?? 0,
    successBuilds: successResult.count ?? 0,
    activeWorkflows: workflowsResult.count ?? 0,
  };
}
