import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

// POST /api/orgs — create a new organization for the current user
export async function POST(request: Request) {
  const supabase = await createClient();
  const { data: authData, error: authError } = await supabase.auth.getClaims();
  if (authError || !authData?.claims) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  let body: { name?: string; slug?: string };
  try {
    body = (await request.json()) as { name?: string; slug?: string };
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const name = body.name?.trim();
  const slug = body.slug?.trim().toLowerCase();

  if (!name || !slug) {
    return NextResponse.json({ error: "name and slug are required" }, { status: 400 });
  }

  if (!/^[a-z0-9-]{2,40}$/.test(slug)) {
    return NextResponse.json(
      { error: "Slug must be 2-40 characters: lowercase letters, numbers, hyphens only" },
      { status: 400 }
    );
  }

  // Call the create_organization RPC (creates org + adds caller as owner)
  const { data, error } = await supabase.rpc("create_organization", {
    p_name: name,
    p_slug: slug,
  });

  if (error) {
    if (error.message.includes("duplicate") || error.message.includes("unique")) {
      return NextResponse.json({ error: "slug_taken" }, { status: 409 });
    }
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ org: data }, { status: 201 });
}
