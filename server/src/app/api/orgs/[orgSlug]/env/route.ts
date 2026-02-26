import { getOrgBySlug } from "@/lib/supabase/queries";
import { createClient, createServiceClient } from "@/lib/supabase/server";
import { NextResponse } from "next/server";

// POST /api/orgs/[orgSlug]/env — add an environment variable
export async function POST(request: Request, { params }: { params: Promise<{ orgSlug: string }> }) {
  const supabase = await createClient();
  const { data: authData, error: authError } = await supabase.auth.getClaims();
  if (authError || !authData?.claims) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { orgSlug } = await params;
  const org = await getOrgBySlug(supabase, orgSlug);
  if (!org) {
    return NextResponse.json({ error: "Organization not found" }, { status: 404 });
  }

  let body: { key?: string; value?: string; is_secret?: boolean };
  try {
    body = (await request.json()) as typeof body;
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const key = body.key?.trim();
  const value = body.value;
  const isSecret = body.is_secret === true;

  if (!key) {
    return NextResponse.json({ error: "key is required" }, { status: 400 });
  }
  if (!value) {
    return NextResponse.json({ error: "value is required" }, { status: 400 });
  }

  const admin = createServiceClient();

  if (isSecret) {
    const { data: vaultId, error: vaultError } = await admin.rpc("create_vault_secret", {
      p_secret: value,
      p_name: `${org.id}/${key}`,
    });

    if (vaultError || !vaultId) {
      return NextResponse.json({ error: "Failed to store secret in Vault" }, { status: 500 });
    }

    const { data: envVar, error: dbError } = await supabase
      .from("environment_variables")
      .insert({
        org_id: org.id,
        key,
        value: null,
        is_secret: true,
        vault_secret_id: vaultId as string,
      })
      .select("id, org_id, key, is_secret, vault_secret_id, auto_increment, created_at, updated_at")
      .single();

    if (dbError) {
      await admin.rpc("delete_vault_secret", { p_vault_secret_id: vaultId });
      if (dbError.message.includes("duplicate") || dbError.message.includes("unique")) {
        return NextResponse.json({ error: "key_taken" }, { status: 409 });
      }
      return NextResponse.json({ error: dbError.message }, { status: 500 });
    }

    return NextResponse.json({ envVar }, { status: 201 });
  } else {
    const { data: envVar, error: dbError } = await supabase
      .from("environment_variables")
      .insert({
        org_id: org.id,
        key,
        value,
        is_secret: false,
        vault_secret_id: null,
      })
      .select("id, org_id, key, is_secret, vault_secret_id, auto_increment, created_at, updated_at")
      .single();

    if (dbError) {
      if (dbError.message.includes("duplicate") || dbError.message.includes("unique")) {
        return NextResponse.json({ error: "key_taken" }, { status: 409 });
      }
      return NextResponse.json({ error: dbError.message }, { status: 500 });
    }

    return NextResponse.json({ envVar }, { status: 201 });
  }
}
