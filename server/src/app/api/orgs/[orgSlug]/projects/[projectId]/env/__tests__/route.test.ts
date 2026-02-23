import { describe, it, expect, vi, beforeEach } from "vitest";

vi.mock("@/lib/supabase/server", () => ({
  createClient: vi.fn(),
  createServiceClient: vi.fn(),
}));

vi.mock("@/lib/supabase/queries", () => ({
  getOrgBySlug: vi.fn(),
  getProjectById: vi.fn(),
}));

import { createClient, createServiceClient } from "@/lib/supabase/server";
import { getOrgBySlug, getProjectById } from "@/lib/supabase/queries";
import { POST } from "../route";

const mockOrg = { id: "org-1", slug: "my-org", role: "admin" };
const mockProject = { id: "proj-1", org_id: "org-1", name: "My Project" };

function makeAuthSupabase(authenticated = true) {
  const getClaims = vi.fn().mockResolvedValue(
    authenticated
      ? { data: { claims: { sub: "user-1" } }, error: null }
      : { data: null, error: new Error("Unauthorized") }
  );
  const from = vi.fn();
  return { auth: { getClaims }, from };
}

function makeServiceClient(rpcResult: { data: unknown; error: unknown } = { data: "vault-id-1", error: null }) {
  const rpc = vi.fn().mockResolvedValue(rpcResult);
  return { rpc };
}

function makeParams() {
  return { params: Promise.resolve({ orgSlug: "my-org", projectId: "proj-1" }) };
}

function makeRequest(body: unknown) {
  return new Request("http://localhost/api/orgs/my-org/projects/proj-1/env", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
}

describe("POST /api/orgs/[orgSlug]/projects/[projectId]/env", () => {
  beforeEach(() => vi.clearAllMocks());

  it("returns 401 when not authenticated", async () => {
    vi.mocked(createClient).mockResolvedValue(makeAuthSupabase(false) as never);
    vi.mocked(createServiceClient).mockReturnValue(makeServiceClient() as never);
    const res = await POST(makeRequest({ key: "K", value: "V" }), makeParams());
    expect(res.status).toBe(401);
  });

  it("returns 404 when org not found", async () => {
    vi.mocked(createClient).mockResolvedValue(makeAuthSupabase() as never);
    vi.mocked(createServiceClient).mockReturnValue(makeServiceClient() as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(null);
    const res = await POST(makeRequest({ key: "K", value: "V" }), makeParams());
    expect(res.status).toBe(404);
  });

  it("returns 404 when project not found", async () => {
    vi.mocked(createClient).mockResolvedValue(makeAuthSupabase() as never);
    vi.mocked(createServiceClient).mockReturnValue(makeServiceClient() as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);
    vi.mocked(getProjectById).mockResolvedValue(null);
    const res = await POST(makeRequest({ key: "K", value: "V" }), makeParams());
    expect(res.status).toBe(404);
  });

  it("returns 400 for invalid JSON", async () => {
    vi.mocked(createClient).mockResolvedValue(makeAuthSupabase() as never);
    vi.mocked(createServiceClient).mockReturnValue(makeServiceClient() as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);
    vi.mocked(getProjectById).mockResolvedValue(mockProject as never);
    const badReq = new Request("http://localhost/", { method: "POST", body: "bad json" });
    const res = await POST(badReq, makeParams());
    expect(res.status).toBe(400);
  });

  it("returns 400 when key is missing", async () => {
    vi.mocked(createClient).mockResolvedValue(makeAuthSupabase() as never);
    vi.mocked(createServiceClient).mockReturnValue(makeServiceClient() as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);
    vi.mocked(getProjectById).mockResolvedValue(mockProject as never);
    const res = await POST(makeRequest({ value: "V" }), makeParams());
    expect(res.status).toBe(400);
    const body = await res.json() as { error: string };
    expect(body.error).toMatch(/key/);
  });

  it("returns 400 when value is missing", async () => {
    vi.mocked(createClient).mockResolvedValue(makeAuthSupabase() as never);
    vi.mocked(createServiceClient).mockReturnValue(makeServiceClient() as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);
    vi.mocked(getProjectById).mockResolvedValue(mockProject as never);
    const res = await POST(makeRequest({ key: "K" }), makeParams());
    expect(res.status).toBe(400);
    const body = await res.json() as { error: string };
    expect(body.error).toMatch(/value/);
  });

  it("returns 201 for plain-text variable", async () => {
    const createdEnvVar = { id: "ev-1", project_id: "proj-1", key: "MY_VAR", is_secret: false, vault_secret_id: null, auto_increment: false };
    const singleMock = vi.fn().mockResolvedValue({ data: createdEnvVar, error: null });
    const selectMock = vi.fn().mockReturnValue({ single: singleMock });
    const insertMock = vi.fn().mockReturnValue({ select: selectMock });
    const fromMock = vi.fn().mockReturnValue({ insert: insertMock });
    const supabase = { ...makeAuthSupabase(), from: fromMock };

    vi.mocked(createClient).mockResolvedValue(supabase as never);
    vi.mocked(createServiceClient).mockReturnValue(makeServiceClient() as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);
    vi.mocked(getProjectById).mockResolvedValue(mockProject as never);

    const res = await POST(makeRequest({ key: "MY_VAR", value: "hello" }), makeParams());
    expect(res.status).toBe(201);
    const body = await res.json() as { envVar: { key: string } };
    expect(body.envVar.key).toBe("MY_VAR");
  });

  it("returns 201 for secret variable and calls vault RPC", async () => {
    const createdEnvVar = { id: "ev-2", project_id: "proj-1", key: "SECRET", is_secret: true, vault_secret_id: "vault-id-1", auto_increment: false };
    const singleMock = vi.fn().mockResolvedValue({ data: createdEnvVar, error: null });
    const selectMock = vi.fn().mockReturnValue({ single: singleMock });
    const insertMock = vi.fn().mockReturnValue({ select: selectMock });
    const fromMock = vi.fn().mockReturnValue({ insert: insertMock });
    const supabase = { ...makeAuthSupabase(), from: fromMock };

    const adminRpc = vi.fn().mockResolvedValue({ data: "vault-id-1", error: null });
    const admin = { rpc: adminRpc };

    vi.mocked(createClient).mockResolvedValue(supabase as never);
    vi.mocked(createServiceClient).mockReturnValue(admin as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);
    vi.mocked(getProjectById).mockResolvedValue(mockProject as never);

    const res = await POST(makeRequest({ key: "SECRET", value: "s3cret", is_secret: true }), makeParams());
    expect(res.status).toBe(201);
    expect(adminRpc).toHaveBeenCalledWith("create_vault_secret", expect.objectContaining({ p_secret: "s3cret" }));
    const body = await res.json() as { envVar: { is_secret: boolean } };
    expect(body.envVar.is_secret).toBe(true);
  });

  it("returns 500 when vault RPC fails for secret", async () => {
    vi.mocked(createClient).mockResolvedValue(makeAuthSupabase() as never);
    vi.mocked(createServiceClient).mockReturnValue(makeServiceClient({ data: null, error: new Error("vault error") }) as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);
    vi.mocked(getProjectById).mockResolvedValue(mockProject as never);

    const res = await POST(makeRequest({ key: "SECRET", value: "s3cret", is_secret: true }), makeParams());
    expect(res.status).toBe(500);
  });

  it("returns 409 when key is already taken", async () => {
    const singleMock = vi.fn().mockResolvedValue({ data: null, error: { message: "duplicate key value" } });
    const selectMock = vi.fn().mockReturnValue({ single: singleMock });
    const insertMock = vi.fn().mockReturnValue({ select: selectMock });
    const fromMock = vi.fn().mockReturnValue({ insert: insertMock });
    const supabase = { ...makeAuthSupabase(), from: fromMock };

    vi.mocked(createClient).mockResolvedValue(supabase as never);
    vi.mocked(createServiceClient).mockReturnValue(makeServiceClient() as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);
    vi.mocked(getProjectById).mockResolvedValue(mockProject as never);

    const res = await POST(makeRequest({ key: "EXISTING", value: "v" }), makeParams());
    expect(res.status).toBe(409);
    const body = await res.json() as { error: string };
    expect(body.error).toBe("key_taken");
  });
});
