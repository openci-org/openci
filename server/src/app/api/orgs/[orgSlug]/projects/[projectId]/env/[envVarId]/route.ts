import { NextResponse } from "next/server";
import { createClient, createServiceClient } from "@/lib/supabase/server";
import { getOrgBySlug, getProjectById, getEnvVarById } from "@/lib/supabase/queries";

type Params = { params: Promise<{ orgSlug: string; projectId: string; envVarId: string }> };

async function resolveContext(orgSlug: string, projectId: string, envVarId: string) {
  const supabase = await createClient();
  const { data: authData, error: authError } = await supabase.auth.getClaims();
  if (authError || !authData?.claims) return { error: "Unauthorized", status: 401 } as const;

  const org = await getOrgBySlug(supabase, orgSlug);
  if (!org) return { error: "Organization not found", status: 404 } as const;

  const project = await getProjectById(supabase, projectId, org.id);
  if (!project) return { error: "Project not found", status: 404 } as const;

  const envVar = await getEnvVarById(supabase, envVarId);
  if (!envVar || envVar.project_id !== projectId) {
    return { error: "Environment variable not found", status: 404 } as const;
  }

  return { supabase, envVar } as const;
}

// PATCH /api/orgs/[orgSlug]/projects/[projectId]/env/[envVarId] — update value
export async function PATCH(
  request: Request,
  { params }: Params
) {
  const { orgSlug, projectId, envVarId } = await params;
  const ctx = await resolveContext(orgSlug, projectId, envVarId);
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

  // Case 1: was secret, stays secret → update vault value
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

  // Case 2: was secret, now plain → delete vault entry, store plain value
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

  // Case 3: was plain, now secret → create vault entry, clear plain value
  if (!envVar.is_secret && targetIsSecret) {
    const { data: vaultId, error: vaultError } = await admin.rpc("create_vault_secret", {
      p_secret: newValue,
      p_name: `${projectId}/${envVar.key}`,
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

  // Case 4: was plain, stays plain → update value directly
  const { error: dbError } = await supabase
    .from("environment_variables")
    .update({ value: newValue })
    .eq("id", envVarId);

  if (dbError) return NextResponse.json({ error: dbError.message }, { status: 500 });
  const updated = await getEnvVarById(supabase, envVarId);
  return NextResponse.json({ envVar: updated });
}

// DELETE /api/orgs/[orgSlug]/projects/[projectId]/env/[envVarId]
export async function DELETE(
  _request: Request,
  { params }: Params
) {
  const { orgSlug, projectId, envVarId } = await params;
  const ctx = await resolveContext(orgSlug, projectId, envVarId);
  if ("error" in ctx) {
    return NextResponse.json({ error: ctx.error }, { status: ctx.status });
  }
  const { supabase, envVar } = ctx;
  const admin = createServiceClient();

  const { error } = await supabase.from("environment_variables").delete().eq("id", envVarId);
  if (error) return NextResponse.json({ error: error.message }, { status: 500 });

  // Clean up vault entry after DB row is gone
  if (envVar.is_secret && envVar.vault_secret_id) {
    await admin.rpc("delete_vault_secret", { p_vault_secret_id: envVar.vault_secret_id });
  }

  return new NextResponse(null, { status: 204 });
}
