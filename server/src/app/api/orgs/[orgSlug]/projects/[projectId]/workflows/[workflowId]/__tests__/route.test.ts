import { describe, it, expect, vi, beforeEach } from "vitest";

vi.mock("@/lib/supabase/server", () => ({
  createClient: vi.fn(),
}));

vi.mock("@/lib/supabase/queries", () => ({
  getOrgBySlug: vi.fn(),
  getProjectById: vi.fn(),
  getWorkflowById: vi.fn(),
}));

import { createClient } from "@/lib/supabase/server";
import { getOrgBySlug, getProjectById, getWorkflowById } from "@/lib/supabase/queries";
import { GET, PATCH, DELETE } from "../route";

const mockOrg = { id: "org-1", slug: "my-org", role: "admin" };
const mockProject = { id: "proj-1", org_id: "org-1", name: "My Project" };
function makePatchRequest(body: unknown) {
  return new Request("http://localhost", {
    method: "PATCH",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
}

const mockWorkflow = {
  id: "wf-1",
  project_id: "proj-1",
  name: "My Workflow",
  yaml_definition: "",
  is_active: true,
  created_at: "2024-01-01T00:00:00Z",
  updated_at: "2024-01-01T00:00:00Z",
  workflow_triggers: [],
  last_build: null,
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

function makeParams(workflowId = "wf-1") {
  return { params: Promise.resolve({ orgSlug: "my-org", projectId: "proj-1", workflowId }) };
}

describe("GET /api/.../workflows/[workflowId]", () => {
  beforeEach(() => vi.clearAllMocks());

  it("returns 401 when not authenticated", async () => {
    const supabase = makeAuthSupabase(false);
    vi.mocked(createClient).mockResolvedValue(supabase as never);
    const res = await GET(new Request("http://localhost"), makeParams());
    expect(res.status).toBe(401);
  });

  it("returns 404 when org not found", async () => {
    vi.mocked(createClient).mockResolvedValue(makeAuthSupabase() as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(null);
    const res = await GET(new Request("http://localhost"), makeParams());
    expect(res.status).toBe(404);
  });

  it("returns 404 when project not found", async () => {
    vi.mocked(createClient).mockResolvedValue(makeAuthSupabase() as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);
    vi.mocked(getProjectById).mockResolvedValue(null);
    const res = await GET(new Request("http://localhost"), makeParams());
    expect(res.status).toBe(404);
  });

  it("returns 404 when workflow not found", async () => {
    vi.mocked(createClient).mockResolvedValue(makeAuthSupabase() as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);
    vi.mocked(getProjectById).mockResolvedValue(mockProject as never);
    vi.mocked(getWorkflowById).mockResolvedValue(null);
    const res = await GET(new Request("http://localhost"), makeParams());
    expect(res.status).toBe(404);
  });

  it("returns 404 when workflow belongs to different project", async () => {
    vi.mocked(createClient).mockResolvedValue(makeAuthSupabase() as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);
    vi.mocked(getProjectById).mockResolvedValue(mockProject as never);
    vi.mocked(getWorkflowById).mockResolvedValue({ ...mockWorkflow, project_id: "other-proj" } as never);
    const res = await GET(new Request("http://localhost"), makeParams());
    expect(res.status).toBe(404);
  });

  it("returns 200 with workflow", async () => {
    vi.mocked(createClient).mockResolvedValue(makeAuthSupabase() as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);
    vi.mocked(getProjectById).mockResolvedValue(mockProject as never);
    vi.mocked(getWorkflowById).mockResolvedValue(mockWorkflow as never);
    const res = await GET(new Request("http://localhost"), makeParams());
    expect(res.status).toBe(200);
    const body = await res.json() as { workflow: typeof mockWorkflow };
    expect(body.workflow.id).toBe("wf-1");
  });
});

describe("PATCH /api/.../workflows/[workflowId]", () => {
  beforeEach(() => vi.clearAllMocks());

  it("returns 401 when not authenticated", async () => {
    vi.mocked(createClient).mockResolvedValue(makeAuthSupabase(false) as never);
    const res = await PATCH(makePatchRequest({}), makeParams());
    expect(res.status).toBe(401);
  });

  it("returns 400 for invalid JSON", async () => {
    vi.mocked(createClient).mockResolvedValue(makeAuthSupabase() as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);
    vi.mocked(getProjectById).mockResolvedValue(mockProject as never);
    vi.mocked(getWorkflowById).mockResolvedValue(mockWorkflow as never);
    const badReq = new Request("http://localhost", { method: "PATCH", body: "bad json" });
    const res = await PATCH(badReq, makeParams());
    expect(res.status).toBe(400);
  });

  it("returns 400 when name is empty string", async () => {
    vi.mocked(createClient).mockResolvedValue(makeAuthSupabase() as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);
    vi.mocked(getProjectById).mockResolvedValue(mockProject as never);
    vi.mocked(getWorkflowById).mockResolvedValue(mockWorkflow as never);
    const res = await PATCH(makePatchRequest({ name: "  " }), makeParams());
    expect(res.status).toBe(400);
  });

  it("returns 200 after successful update", async () => {
    const updateEqMock = vi.fn().mockResolvedValue({ error: null });
    const eqMock = vi.fn().mockReturnValue({ eq: updateEqMock });
    const updateMock = vi.fn().mockReturnValue({ eq: eqMock });
    const fromMock = vi.fn().mockReturnValue({ update: updateMock });
    const supabase = { ...makeAuthSupabase(), from: fromMock };

    vi.mocked(createClient).mockResolvedValue(supabase as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);
    vi.mocked(getProjectById).mockResolvedValue(mockProject as never);
    vi.mocked(getWorkflowById)
      .mockResolvedValueOnce(mockWorkflow as never)
      .mockResolvedValueOnce({ ...mockWorkflow, name: "Updated" } as never);

    const res = await PATCH(makePatchRequest({ name: "Updated" }), makeParams());
    expect(res.status).toBe(200);
    const body = await res.json() as { workflow: { name: string } };
    expect(body.workflow.name).toBe("Updated");
  });

  it("replaces triggers when provided", async () => {
    const deleteEqMock = vi.fn().mockResolvedValue({ error: null });
    const deleteMock = vi.fn().mockReturnValue({ eq: deleteEqMock });
    const insertMock = vi.fn().mockResolvedValue({ error: null });
    const updateEqMock = vi.fn().mockResolvedValue({ error: null });
    const eqMock = vi.fn().mockReturnValue({ eq: updateEqMock });
    const updateMock = vi.fn().mockReturnValue({ eq: eqMock });
    const fromMock = vi.fn().mockImplementation((table: string) => {
      if (table === "workflows") return { update: updateMock };
      if (table === "workflow_triggers") return { delete: deleteMock, insert: insertMock };
      return {};
    });

    const supabase = { ...makeAuthSupabase(), from: fromMock };
    vi.mocked(createClient).mockResolvedValue(supabase as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);
    vi.mocked(getProjectById).mockResolvedValue(mockProject as never);
    vi.mocked(getWorkflowById)
      .mockResolvedValueOnce(mockWorkflow as never)
      .mockResolvedValueOnce(mockWorkflow as never);

    const res = await PATCH(
      makePatchRequest({ triggers: [{ trigger_type: "push", github_repo: "owner/repo" }] }),
      makeParams()
    );
    expect(res.status).toBe(200);
    expect(insertMock).toHaveBeenCalled();
  });
});

describe("DELETE /api/.../workflows/[workflowId]", () => {
  beforeEach(() => vi.clearAllMocks());

  it("returns 401 when not authenticated", async () => {
    vi.mocked(createClient).mockResolvedValue(makeAuthSupabase(false) as never);
    const res = await DELETE(new Request("http://localhost"), makeParams());
    expect(res.status).toBe(401);
  });

  it("returns 204 on successful delete", async () => {
    const deleteEqMock = vi.fn().mockResolvedValue({ error: null });
    const deleteMock = vi.fn().mockReturnValue({ eq: deleteEqMock });
    const fromMock = vi.fn().mockReturnValue({ delete: deleteMock });
    const supabase = { ...makeAuthSupabase(), from: fromMock };

    vi.mocked(createClient).mockResolvedValue(supabase as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);
    vi.mocked(getProjectById).mockResolvedValue(mockProject as never);
    vi.mocked(getWorkflowById).mockResolvedValue(mockWorkflow as never);

    const res = await DELETE(new Request("http://localhost"), makeParams());
    expect(res.status).toBe(204);
  });

  it("returns 500 when delete fails", async () => {
    const deleteEqMock = vi.fn().mockResolvedValue({ error: new Error("db error") });
    const deleteMock = vi.fn().mockReturnValue({ eq: deleteEqMock });
    const fromMock = vi.fn().mockReturnValue({ delete: deleteMock });
    const supabase = { ...makeAuthSupabase(), from: fromMock };

    vi.mocked(createClient).mockResolvedValue(supabase as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);
    vi.mocked(getProjectById).mockResolvedValue(mockProject as never);
    vi.mocked(getWorkflowById).mockResolvedValue(mockWorkflow as never);

    const res = await DELETE(new Request("http://localhost"), makeParams());
    expect(res.status).toBe(500);
  });
});
