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

  // RLS policy "builds: write role can cancel" enforces that only users with
  // write access to the project can set status to 'cancelled'.
  const { error } = await supabase
    .from("builds")
    .update({ status: "cancelled" })
    .eq("id", buildId)
    .in("status", ["queued", "in_progress"]);

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 400 });
  }

  return NextResponse.json({ success: true });
}
