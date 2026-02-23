// Server-side Supabase query helpers for OpenCI
// All functions require a server-side Supabase client (createClient from @/lib/supabase/server)

import type { SupabaseClient } from "@supabase/supabase-js";
import type {
  Organization,
  OrganizationWithRole,
  ProjectWithLastBuild,
  WorkflowWithTriggers,
  Build,
  BuildLog,
  EnvironmentVariable,
  OrgMember,
  OrgInvitation,
} from "./types";

// Returns all organizations the current user belongs to, with their role.
export async function getUserOrgs(
  supabase: SupabaseClient
): Promise<OrganizationWithRole[]> {
  const { data, error } = await supabase
    .from("org_members")
    .select(
      `
      role,
      organizations (
        id, name, slug, billing_enabled, stripe_customer_id,
        stripe_subscription_id, created_at, updated_at
      )
    `
    )
    .order("created_at", { ascending: true });

  if (error || !data) return [];

  // Deduplicate by org id, keeping the first occurrence (highest-privilege role
  // would appear first if the user has multiple memberships for the same org).
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
  slug: string
): Promise<OrganizationWithRole | null> {
  const orgs = await getUserOrgs(supabase);
  return orgs.find((o) => o.slug === slug) ?? null;
}

// Returns all projects in an org with last build status and counts.
export async function getOrgProjects(
  supabase: SupabaseClient,
  orgId: string
): Promise<ProjectWithLastBuild[]> {
  const { data, error } = await supabase
    .from("projects")
    .select(
      `
      id, org_id, name, slug, description, framework, platforms,
      created_at, updated_at,
      builds (
        id, status, branch, created_at
      ),
      workflows (id)
    `
    )
    .eq("org_id", orgId)
    .order("created_at", { ascending: true });

  if (error || !data) return [];

  return data.map((project) => {
    const builds = (project.builds as Build[]) ?? [];
    const lastBuild =
      builds.length > 0
        ? builds.reduce((a, b) =>
            new Date(a.created_at) > new Date(b.created_at) ? a : b
          )
        : null;

    return {
      id: project.id,
      org_id: project.org_id,
      name: project.name,
      slug: project.slug,
      description: project.description,
      framework: project.framework,
      platforms: project.platforms,
      created_at: project.created_at,
      updated_at: project.updated_at,
      last_build: lastBuild
        ? {
            id: lastBuild.id,
            status: lastBuild.status,
            branch: lastBuild.branch,
            created_at: lastBuild.created_at,
          }
        : null,
      build_count: builds.length,
      workflow_count: ((project.workflows as { id: string }[]) ?? []).length,
    };
  });
}

// Returns a single project by slug within an org.
export async function getProjectBySlug(
  supabase: SupabaseClient,
  orgId: string,
  slug: string
) {
  const { data, error } = await supabase
    .from("projects")
    .select("*")
    .eq("org_id", orgId)
    .eq("slug", slug)
    .single();

  if (error) return null;
  return data;
}

// Returns a single project by id.
// When orgId is provided, also filters by org_id as defense-in-depth
// to prevent cross-org access when a user belongs to multiple organizations.
export async function getProjectById(
  supabase: SupabaseClient,
  projectId: string,
  orgId?: string
) {
  let query = supabase
    .from("projects")
    .select("*")
    .eq("id", projectId);

  if (orgId) {
    query = query.eq("org_id", orgId);
  }

  const { data, error } = await query.single();
  if (error) return null;
  return data;
}

// Returns builds for a project, newest first.
export async function getProjectBuilds(
  supabase: SupabaseClient,
  projectId: string,
  limit = 50
): Promise<Build[]> {
  const { data, error } = await supabase
    .from("builds")
    .select("*")
    .eq("project_id", projectId)
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
    `
    )
    .eq("id", buildId)
    .single();

  if (error) return null;
  return data;
}

// Returns logs for a build run, in order.
export async function getBuildRunLogs(
  supabase: SupabaseClient,
  buildRunId: string
): Promise<BuildLog[]> {
  const { data, error } = await supabase
    .from("build_logs")
    .select("*")
    .eq("build_run_id", buildRunId)
    .order("created_at", { ascending: true });

  if (error || !data) return [];
  return data as BuildLog[];
}

// Returns workflows for a project with their triggers.
export async function getProjectWorkflows(
  supabase: SupabaseClient,
  projectId: string
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
    `
    )
    .eq("project_id", projectId)
    .order("created_at", { ascending: true });

  if (error || !data) return [];

  return data.map((wf) => {
    const builds = (wf.builds as Build[]) ?? [];
    const lastBuild =
      builds.length > 0
        ? builds.reduce((a, b) =>
            new Date(a.created_at) > new Date(b.created_at) ? a : b
          )
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
  workflowId: string
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
    `
    )
    .eq("id", workflowId)
    .single();

  if (error || !data) return null;

  const builds = (data.builds as Build[]) ?? [];
  const lastBuild =
    builds.length > 0
      ? builds.reduce((a, b) =>
          new Date(a.created_at) > new Date(b.created_at) ? a : b
        )
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

// Returns environment variables for a project (excludes plain values for secrets).
export async function getProjectEnvVars(
  supabase: SupabaseClient,
  projectId: string
): Promise<EnvironmentVariable[]> {
  const { data, error } = await supabase
    .from("environment_variables")
    .select("id, project_id, key, is_secret, auto_increment, created_at, updated_at")
    .eq("project_id", projectId)
    .order("key", { ascending: true });

  if (error || !data) return [];
  return data as EnvironmentVariable[];
}

// Returns org members with profile info.
export async function getOrgMembers(
  supabase: SupabaseClient,
  orgId: string
): Promise<(OrgMember & { profile: { full_name: string | null; avatar_url: string | null } | null; email: string | null })[]> {
  const { data, error } = await supabase
    .from("org_members")
    .select(
      `
      id, org_id, user_id, role, created_at, updated_at,
      profiles (full_name, avatar_url)
    `
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
    profile: m.profiles as unknown as { full_name: string | null; avatar_url: string | null } | null,
    email: null, // email comes from auth.users, not directly queryable via RLS
  }));
}

// Returns pending invitations for an org.
export async function getOrgInvitations(
  supabase: SupabaseClient,
  orgId: string
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
  orgId: string
): Promise<{
  totalBuilds: number;
  successBuilds: number;
  activeWorkflows: number;
}> {
  const { data: projectIds } = await supabase
    .from("projects")
    .select("id")
    .eq("org_id", orgId);

  if (!projectIds || projectIds.length === 0) {
    return { totalBuilds: 0, successBuilds: 0, activeWorkflows: 0 };
  }

  const ids = projectIds.map((p) => p.id);

  const [totalResult, successResult, workflowsResult] = await Promise.all([
    supabase
      .from("builds")
      .select("id", { count: "exact", head: true })
      .in("project_id", ids),
    supabase
      .from("builds")
      .select("id", { count: "exact", head: true })
      .in("project_id", ids)
      .eq("status", "success"),
    supabase
      .from("workflows")
      .select("id", { count: "exact", head: true })
      .in("project_id", ids)
      .eq("is_active", true),
  ]);

  return {
    totalBuilds: totalResult.count ?? 0,
    successBuilds: successResult.count ?? 0,
    activeWorkflows: workflowsResult.count ?? 0,
  };
}
