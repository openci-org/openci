import { describe, it, expect, vi, beforeEach } from "vitest";

vi.mock("@/lib/supabase/server", () => ({
  createClient: vi.fn(),
  createServiceClient: vi.fn(),
}));

vi.mock("@/lib/supabase/queries", () => ({
  getOrgBySlug: vi.fn(),
  getProjectById: vi.fn(),
  getEnvVarById: vi.fn(),
}));

import { createClient, createServiceClient } from "@/lib/supabase/server";
import { getOrgBySlug, getProjectById, getEnvVarById } from "@/lib/supabase/queries";
import { PATCH, DELETE } from "../route";

const mockOrg = { id: "org-1", slug: "my-org", role: "admin" };
const mockProject = { id: "proj-1", org_id: "org-1" };

const mockPlainEnvVar = {
  id: "ev-1",
  project_id: "proj-1",
  key: "MY_VAR",
  value: "hello",
  is_secret: false,
  vault_secret_id: null,
  auto_increment: false,
  created_at: "2024-01-01T00:00:00Z",
  updated_at: "2024-01-01T00:00:00Z",
};

const mockSecretEnvVar = {
  ...mockPlainEnvVar,
  id: "ev-2",
  key: "SECRET",
  value: null,
  is_secret: true,
  vault_secret_id: "vault-uuid-1",
};

function makeAuthSupabase(authenticated = true) {
  const getClaims = vi.fn().mockResolvedValue(
    authenticated
      ? { data: { claims: { sub: "user-1" } }, error: null }
      : { data: null, error: new Error("Unauthorized") }
  );
  const from = vi.fn();
  return { auth: { getClaims }, from };
}

function makeAdminClient(rpcResult: { data: unknown; error: unknown } = { data: null, error: null }) {
  const rpc = vi.fn().mockResolvedValue(rpcResult);
  return { rpc };
}

function makeParams(envVarId = "ev-1") {
  return { params: Promise.resolve({ orgSlug: "my-org", projectId: "proj-1", envVarId }) };
}

function makePatchRequest(body: unknown) {
  return new Request("http://localhost", {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
}

describe("PATCH /api/.../env/[envVarId]", () => {
  beforeEach(() => vi.clearAllMocks());

  it("returns 401 when not authenticated", async () => {
    vi.mocked(createClient).mockResolvedValue(makeAuthSupabase(false) as never);
    vi.mocked(createServiceClient).mockReturnValue(makeAdminClient() as never);
    const res = await PATCH(makePatchRequest({ value: "new" }), makeParams());
    expect(res.status).toBe(401);
  });

  it("returns 404 when env var not found", async () => {
    vi.mocked(createClient).mockResolvedValue(makeAuthSupabase() as never);
    vi.mocked(createServiceClient).mockReturnValue(makeAdminClient() as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);
    vi.mocked(getProjectById).mockResolvedValue(mockProject as never);
    vi.mocked(getEnvVarById).mockResolvedValue(null);
    const res = await PATCH(makePatchRequest({ value: "new" }), makeParams());
    expect(res.status).toBe(404);
  });

  it("returns 400 when value is empty", async () => {
    vi.mocked(createClient).mockResolvedValue(makeAuthSupabase() as never);
    vi.mocked(createServiceClient).mockReturnValue(makeAdminClient() as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);
    vi.mocked(getProjectById).mockResolvedValue(mockProject as never);
    vi.mocked(getEnvVarById).mockResolvedValue(mockPlainEnvVar as never);
    const res = await PATCH(makePatchRequest({ value: "" }), makeParams());
    expect(res.status).toBe(400);
  });

  it("returns 400 for invalid JSON", async () => {
    vi.mocked(createClient).mockResolvedValue(makeAuthSupabase() as never);
    vi.mocked(createServiceClient).mockReturnValue(makeAdminClient() as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);
    vi.mocked(getProjectById).mockResolvedValue(mockProject as never);
    vi.mocked(getEnvVarById).mockResolvedValue(mockPlainEnvVar as never);
    const badReq = new Request("http://localhost", { method: "PATCH", body: "bad json" });
    const res = await PATCH(badReq, makeParams());
    expect(res.status).toBe(400);
  });

  it("updates plain variable (plain→plain)", async () => {
    const updateEq = vi.fn().mockResolvedValue({ error: null });
    const eq = vi.fn().mockReturnValue({ eq: updateEq });
    const update = vi.fn().mockReturnValue({ eq });
    const from = vi.fn().mockReturnValue({ update });
    const supabase = { ...makeAuthSupabase(), from };

    vi.mocked(createClient).mockResolvedValue(supabase as never);
    vi.mocked(createServiceClient).mockReturnValue(makeAdminClient() as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);
    vi.mocked(getProjectById).mockResolvedValue(mockProject as never);
    vi.mocked(getEnvVarById)
      .mockResolvedValueOnce(mockPlainEnvVar as never)
      .mockResolvedValueOnce({ ...mockPlainEnvVar, value: "updated" } as never);

    const res = await PATCH(makePatchRequest({ value: "updated" }), makeParams());
    expect(res.status).toBe(200);
    const body = await res.json() as { envVar: { key: string } };
    expect(body.envVar.key).toBe("MY_VAR");
  });

  it("updates vault for secret→secret", async () => {
    const adminRpc = vi.fn().mockResolvedValue({ data: null, error: null });
    const admin = { rpc: adminRpc };

    vi.mocked(createClient).mockResolvedValue(makeAuthSupabase() as never);
    vi.mocked(createServiceClient).mockReturnValue(admin as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);
    vi.mocked(getProjectById).mockResolvedValue(mockProject as never);
    vi.mocked(getEnvVarById)
      .mockResolvedValueOnce(mockSecretEnvVar as never)
      .mockResolvedValueOnce(mockSecretEnvVar as never);

    const res = await PATCH(makePatchRequest({ value: "new-secret" }), makeParams("ev-2"));
    expect(res.status).toBe(200);
    expect(adminRpc).toHaveBeenCalledWith("update_vault_secret", expect.objectContaining({
      p_vault_secret_id: "vault-uuid-1",
      p_new_secret: "new-secret",
    }));
  });
});

describe("DELETE /api/.../env/[envVarId]", () => {
  beforeEach(() => vi.clearAllMocks());

  it("returns 401 when not authenticated", async () => {
    vi.mocked(createClient).mockResolvedValue(makeAuthSupabase(false) as never);
    vi.mocked(createServiceClient).mockReturnValue(makeAdminClient() as never);
    const res = await DELETE(new Request("http://localhost"), makeParams());
    expect(res.status).toBe(401);
  });

  it("returns 404 when env var not found", async () => {
    vi.mocked(createClient).mockResolvedValue(makeAuthSupabase() as never);
    vi.mocked(createServiceClient).mockReturnValue(makeAdminClient() as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);
    vi.mocked(getProjectById).mockResolvedValue(mockProject as never);
    vi.mocked(getEnvVarById).mockResolvedValue(null);
    const res = await DELETE(new Request("http://localhost"), makeParams());
    expect(res.status).toBe(404);
  });

  it("returns 204 and deletes plain variable", async () => {
    const deleteEq = vi.fn().mockResolvedValue({ error: null });
    const del = vi.fn().mockReturnValue({ eq: deleteEq });
    const from = vi.fn().mockReturnValue({ delete: del });
    const supabase = { ...makeAuthSupabase(), from };
    const adminRpc = vi.fn().mockResolvedValue({ data: null, error: null });

    vi.mocked(createClient).mockResolvedValue(supabase as never);
    vi.mocked(createServiceClient).mockReturnValue({ rpc: adminRpc } as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);
    vi.mocked(getProjectById).mockResolvedValue(mockProject as never);
    vi.mocked(getEnvVarById).mockResolvedValue(mockPlainEnvVar as never);

    const res = await DELETE(new Request("http://localhost"), makeParams());
    expect(res.status).toBe(204);
    // Should NOT call vault delete for plain variable
    expect(adminRpc).not.toHaveBeenCalled();
  });

  it("returns 204 and deletes vault secret", async () => {
    const deleteEq = vi.fn().mockResolvedValue({ error: null });
    const del = vi.fn().mockReturnValue({ eq: deleteEq });
    const from = vi.fn().mockReturnValue({ delete: del });
    const supabase = { ...makeAuthSupabase(), from };
    const adminRpc = vi.fn().mockResolvedValue({ data: null, error: null });

    vi.mocked(createClient).mockResolvedValue(supabase as never);
    vi.mocked(createServiceClient).mockReturnValue({ rpc: adminRpc } as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);
    vi.mocked(getProjectById).mockResolvedValue(mockProject as never);
    vi.mocked(getEnvVarById).mockResolvedValue(mockSecretEnvVar as never);

    const res = await DELETE(new Request("http://localhost"), makeParams("ev-2"));
    expect(res.status).toBe(204);
    // Should call vault delete for secret variable
    expect(adminRpc).toHaveBeenCalledWith("delete_vault_secret", { p_vault_secret_id: "vault-uuid-1" });
  });

  it("returns 500 when DB delete fails", async () => {
    const deleteEq = vi.fn().mockResolvedValue({ error: new Error("db error") });
    const del = vi.fn().mockReturnValue({ eq: deleteEq });
    const from = vi.fn().mockReturnValue({ delete: del });
    const supabase = { ...makeAuthSupabase(), from };

    vi.mocked(createClient).mockResolvedValue(supabase as never);
    vi.mocked(createServiceClient).mockReturnValue(makeAdminClient() as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);
    vi.mocked(getProjectById).mockResolvedValue(mockProject as never);
    vi.mocked(getEnvVarById).mockResolvedValue(mockPlainEnvVar as never);

    const res = await DELETE(new Request("http://localhost"), makeParams());
    expect(res.status).toBe(500);
  });
});
