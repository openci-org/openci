import { createClient } from "@/lib/supabase/server";
import { NextResponse } from "next/server";

export async function POST(
  _request: Request,
  { params }: { params: Promise<{ buildId: string }> },
) {
  const supabase = await createClient();
  const { data: authData } = await supabase.auth.getClaims();

  if (!authData?.claims) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { buildId } = await params;

  const { data: original, error: fetchError } = await supabase
    .from("builds")
    .select("*")
    .eq("id", buildId)
    .single();

  if (fetchError || !original) {
    return NextResponse.json({ error: "Build not found" }, { status: 404 });
  }

  const { data: retryBuild, error: insertError } = await supabase
    .from("builds")
    .insert({
      org_id: original.org_id,
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
