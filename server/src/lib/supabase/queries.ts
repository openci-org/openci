// Server-side Supabase query helpers for OpenCI
// All functions require a server-side Supabase client (createClient from @/lib/supabase/server)

import type { SupabaseClient } from "@supabase/supabase-js";
import type { Build, BuildLog, EnvironmentVariable, Team, TeamMember, TeamWithRole } from "./types";

// Returns all teams the current user belongs to, with their role.
export async function getUserTeams(supabase: SupabaseClient): Promise<TeamWithRole[]> {
  const { data, error } = await supabase
    .from("team_members")
    .select(
      `
      role,
      teams (
        id, name, slug, billing_enabled, stripe_customer_id,
        stripe_subscription_id, created_at, updated_at
      )
    `,
    )
    .order("created_at", { ascending: true });

  if (error || !data) return [];

  const seen = new Set<string>();
  const result: TeamWithRole[] = [];
  for (const row of data) {
    const team = row.teams as unknown as Team;
    if (!team?.id || seen.has(team.id)) continue;
    seen.add(team.id);
    result.push({ ...team, role: row.role });
  }
  return result;
}

// Returns a single team by slug, or null if not found / not a member.
export async function getTeamBySlug(
  supabase: SupabaseClient,
  slug: string,
): Promise<TeamWithRole | null> {
  const teams = await getUserTeams(supabase);
  return teams.find((t) => t.slug === slug) ?? null;
}

// Returns builds for a team, newest first.
export async function getTeamBuilds(
  supabase: SupabaseClient,
  teamId: string,
  limit = 50,
): Promise<Build[]> {
  const { data, error } = await supabase
    .from("builds")
    .select("*")
    .eq("team_id", teamId)
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

// Returns environment variables for a team (excludes plain values for secrets).
export async function getTeamEnvVars(
  supabase: SupabaseClient,
  teamId: string,
): Promise<EnvironmentVariable[]> {
  const { data, error } = await supabase
    .from("environment_variables")
    .select("id, team_id, key, is_secret, auto_increment, created_at, updated_at")
    .eq("team_id", teamId)
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
    .select("id, team_id, key, is_secret, vault_secret_id, auto_increment, created_at, updated_at")
    .eq("id", envVarId)
    .single();

  if (error || !data) return null;
  return data as EnvironmentVariable;
}

// Returns team members with profile info.
export async function getTeamMembers(
  supabase: SupabaseClient,
  teamId: string,
): Promise<
  (TeamMember & {
    profile: { full_name: string | null; avatar_url: string | null } | null;
    email: string | null;
  })[]
> {
  const { data, error } = await supabase
    .from("team_members")
    .select(
      `
      id, team_id, user_id, role, created_at, updated_at,
      profiles (full_name, avatar_url)
    `,
    )
    .eq("team_id", teamId)
    .order("created_at", { ascending: true });

  if (error || !data) return [];

  return data.map((m) => ({
    id: m.id,
    team_id: m.team_id,
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

// Returns team stats for the dashboard.
export async function getTeamStats(
  supabase: SupabaseClient,
  teamId: string,
): Promise<{
  totalBuilds: number;
  successBuilds: number;
}> {
  const [totalResult, successResult] = await Promise.all([
    supabase.from("builds").select("id", { count: "exact", head: true }).eq("team_id", teamId),
    supabase
      .from("builds")
      .select("id", { count: "exact", head: true })
      .eq("team_id", teamId)
      .eq("status", "success"),
  ]);

  return {
    totalBuilds: totalResult.count ?? 0,
    successBuilds: successResult.count ?? 0,
  };
}
