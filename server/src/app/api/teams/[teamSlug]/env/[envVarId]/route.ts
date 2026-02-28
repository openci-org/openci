import { getEnvVarById, getTeamBySlug } from "@/lib/supabase/queries";
import { createClient, createServiceClient } from "@/lib/supabase/server";
import { NextResponse } from "next/server";

type Params = { params: Promise<{ teamSlug: string; envVarId: string }> };

async function resolveContext(teamSlug: string, envVarId: string) {
  const supabase = await createClient();
  const { data: authData, error: authError } = await supabase.auth.getClaims();
  if (authError || !authData?.claims) return { error: "Unauthorized", status: 401 } as const;

  const org = await getTeamBySlug(supabase, teamSlug);
  if (!org) return { error: "Team not found", status: 404 } as const;

  const envVar = await getEnvVarById(supabase, envVarId);
  if (!envVar || envVar.team_id !== org.id) {
    return { error: "Environment variable not found", status: 404 } as const;
  }

  return { supabase, envVar, org } as const;
}

// PATCH /api/orgs/[teamSlug]/env/[envVarId] — update value
export async function PATCH(request: Request, { params }: Params) {
  const { teamSlug, envVarId } = await params;
  const ctx = await resolveContext(teamSlug, envVarId);
  if ("error" in ctx) {
    return NextResponse.json({ error: ctx.error }, { status: ctx.status });
  }
  const { supabase, envVar } = ctx;

  let body: { value?: string; is_secret?: boolean };
  try {
    body = (await request.json()) as typeof body;
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const newValue = body.value;
  const newIsSecret = body.is_secret;

  if (newValue === undefined || newValue === null || newValue === "") {
    return NextResponse.json({ error: "value is required" }, { status: 400 });
  }

  const admin = createServiceClient();
  const targetIsSecret = newIsSecret !== undefined ? newIsSecret : envVar.is_secret;

  if (envVar.is_secret && targetIsSecret) {
    const { error: vaultError } = await admin.rpc("update_vault_secret", {
      p_vault_secret_id: envVar.vault_secret_id,
      p_new_secret: newValue,
    });
    if (vaultError) {
      return NextResponse.json({ error: "Failed to update secret in Vault" }, { status: 500 });
    }
    const updated = await getEnvVarById(supabase, envVarId);
    return NextResponse.json({ envVar: updated });
  }

  if (envVar.is_secret && !targetIsSecret) {
    const { error: dbError } = await supabase
      .from("environment_variables")
      .update({ value: newValue, is_secret: false, vault_secret_id: null })
      .eq("id", envVarId);

    if (dbError) return NextResponse.json({ error: dbError.message }, { status: 500 });

    if (envVar.vault_secret_id) {
      await admin.rpc("delete_vault_secret", { p_vault_secret_id: envVar.vault_secret_id });
    }
    const updated = await getEnvVarById(supabase, envVarId);
    return NextResponse.json({ envVar: updated });
  }

  if (!envVar.is_secret && targetIsSecret) {
    const { data: vaultId, error: vaultError } = await admin.rpc("create_vault_secret", {
      p_secret: newValue,
      p_name: `${ctx.org.id}/${envVar.key}`,
    });
    if (vaultError || !vaultId) {
      return NextResponse.json({ error: "Failed to store secret in Vault" }, { status: 500 });
    }

    const { error: dbError } = await supabase
      .from("environment_variables")
      .update({ value: null, is_secret: true, vault_secret_id: vaultId as string })
      .eq("id", envVarId);

    if (dbError) {
      await admin.rpc("delete_vault_secret", { p_vault_secret_id: vaultId });
      return NextResponse.json({ error: dbError.message }, { status: 500 });
    }
    const updated = await getEnvVarById(supabase, envVarId);
    return NextResponse.json({ envVar: updated });
  }

  const { error: dbError } = await supabase
    .from("environment_variables")
    .update({ value: newValue })
    .eq("id", envVarId);

  if (dbError) return NextResponse.json({ error: dbError.message }, { status: 500 });
  const updated = await getEnvVarById(supabase, envVarId);
  return NextResponse.json({ envVar: updated });
}

// DELETE /api/orgs/[teamSlug]/env/[envVarId]
export async function DELETE(_request: Request, { params }: Params) {
  const { teamSlug, envVarId } = await params;
  const ctx = await resolveContext(teamSlug, envVarId);
  if ("error" in ctx) {
    return NextResponse.json({ error: ctx.error }, { status: ctx.status });
  }
  const { supabase, envVar } = ctx;
  const admin = createServiceClient();

  const { error } = await supabase.from("environment_variables").delete().eq("id", envVarId);
  if (error) return NextResponse.json({ error: error.message }, { status: 500 });

  if (envVar.is_secret && envVar.vault_secret_id) {
    await admin.rpc("delete_vault_secret", { p_vault_secret_id: envVar.vault_secret_id });
  }

  return new NextResponse(null, { status: 204 });
}
