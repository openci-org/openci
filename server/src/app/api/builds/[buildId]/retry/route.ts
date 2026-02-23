import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export async function POST(
  _request: Request,
  { params }: { params: Promise<{ buildId: string }> }
) {
  const supabase = await createClient();
  const { data: authData } = await supabase.auth.getClaims();

  if (!authData?.claims) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { buildId } = await params;

  // Fetch the original build
  const { data: original, error: fetchError } = await supabase
    .from("builds")
    .select("*")
    .eq("id", buildId)
    .single();

  if (fetchError || !original) {
    return NextResponse.json({ error: "Build not found" }, { status: 404 });
  }

  // Verify the user has write access to the project (RLS will filter if not)
  const { data: project } = await supabase
    .from("projects")
    .select("id")
    .eq("id", original.project_id)
    .single();

  if (!project) {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

  // Create a new queued build as a retry of the original.
  // The installation_token may have expired; the webhook handler should refresh it.
  // For now we clone the build without the token (worker will handle re-auth via GitHub App).
  const { data: retryBuild, error: insertError } = await supabase
    .from("builds")
    .insert({
      project_id: original.project_id,
      workflow_id: original.workflow_id,
      status: "queued",
      github_owner: original.github_owner,
      github_repo: original.github_repo,
      commit_sha: original.commit_sha,
      branch: original.branch,
      tag_name: original.tag_name,
      pull_request_number: original.pull_request_number,
      github_event: original.github_event,
      github_action: original.github_action,
      github_sender: original.github_sender,
      installation_id: original.installation_id,
      retried_from_build_id: original.id,
    })
    .select("id")
    .single();

  if (insertError || !retryBuild) {
    return NextResponse.json({ error: insertError?.message ?? "Failed to retry" }, { status: 400 });
  }

  return NextResponse.json({ buildId: retryBuild.id });
}
