import { describe, it, expect, vi, beforeEach } from "vitest";

// ---- Supabase mock factory ----
function makeSupabaseMock(overrides: {
  getClaims?: () => Promise<unknown>;
  from?: ReturnType<typeof vi.fn>;
} = {}) {
  const getClaims =
    overrides.getClaims ??
    vi.fn().mockResolvedValue({ data: { claims: { sub: "user-1" } }, error: null });

  const fromMock = overrides.from ?? vi.fn();

  return {
    auth: { getClaims },
    from: fromMock,
  };
}

// ---- Module mocks ----
vi.mock("@/lib/supabase/server", () => ({
  createClient: vi.fn(),
}));

vi.mock("@/lib/supabase/queries", () => ({
  getOrgBySlug: vi.fn(),
  getProjectById: vi.fn(),
}));

import { createClient } from "@/lib/supabase/server";
import { getOrgBySlug, getProjectById } from "@/lib/supabase/queries";
import { POST } from "../route";

const mockOrg = { id: "org-1", slug: "my-org", role: "admin" };
const mockProject = { id: "proj-1", org_id: "org-1", name: "My Project" };

function makeRequest(body: unknown) {
  return new Request("http://localhost/api/orgs/my-org/projects/proj-1/workflows", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
}

describe("POST /api/orgs/[orgSlug]/projects/[projectId]/workflows", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("returns 401 when not authenticated", async () => {
    const supabase = makeSupabaseMock({
      getClaims: vi.fn().mockResolvedValue({ data: null, error: new Error("Unauthorized") }),
    });
    vi.mocked(createClient).mockResolvedValue(supabase as never);

    const res = await POST(makeRequest({ name: "Test" }), {
      params: Promise.resolve({ orgSlug: "my-org", projectId: "proj-1" }),
    });
    expect(res.status).toBe(401);
  });

  it("returns 404 when org not found", async () => {
    const supabase = makeSupabaseMock();
    vi.mocked(createClient).mockResolvedValue(supabase as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(null);

    const res = await POST(makeRequest({ name: "Test" }), {
      params: Promise.resolve({ orgSlug: "my-org", projectId: "proj-1" }),
    });
    expect(res.status).toBe(404);
  });

  it("returns 404 when project not found", async () => {
    const supabase = makeSupabaseMock();
    vi.mocked(createClient).mockResolvedValue(supabase as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);
    vi.mocked(getProjectById).mockResolvedValue(null);

    const res = await POST(makeRequest({ name: "Test" }), {
      params: Promise.resolve({ orgSlug: "my-org", projectId: "proj-1" }),
    });
    expect(res.status).toBe(404);
  });

  it("returns 400 when name is missing", async () => {
    const supabase = makeSupabaseMock();
    vi.mocked(createClient).mockResolvedValue(supabase as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);
    vi.mocked(getProjectById).mockResolvedValue(mockProject as never);

    const res = await POST(makeRequest({ name: "" }), {
      params: Promise.resolve({ orgSlug: "my-org", projectId: "proj-1" }),
    });
    expect(res.status).toBe(400);
    const body = await res.json() as { error: string };
    expect(body.error).toMatch(/name/);
  });

  it("returns 400 for invalid JSON", async () => {
    const supabase = makeSupabaseMock();
    vi.mocked(createClient).mockResolvedValue(supabase as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);
    vi.mocked(getProjectById).mockResolvedValue(mockProject as never);

    const badRequest = new Request("http://localhost/api/...", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: "not json",
    });
    const res = await POST(badRequest, {
      params: Promise.resolve({ orgSlug: "my-org", projectId: "proj-1" }),
    });
    expect(res.status).toBe(400);
  });

  it("returns 201 with workflow on success", async () => {
    const createdWorkflow = { id: "wf-new", name: "My CI", project_id: "proj-1" };
    const singleMock = vi.fn().mockResolvedValue({ data: createdWorkflow, error: null });
    const selectMock = vi.fn().mockReturnValue({ single: singleMock });
    const insertMock = vi.fn().mockReturnValue({ select: selectMock });
    const fromMock = vi.fn().mockReturnValue({ insert: insertMock });

    const supabase = makeSupabaseMock({ from: fromMock });
    vi.mocked(createClient).mockResolvedValue(supabase as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);
    vi.mocked(getProjectById).mockResolvedValue(mockProject as never);

    const res = await POST(makeRequest({ name: "My CI" }), {
      params: Promise.resolve({ orgSlug: "my-org", projectId: "proj-1" }),
    });
    expect(res.status).toBe(201);
    const body = await res.json() as { workflow: typeof createdWorkflow };
    expect(body.workflow.id).toBe("wf-new");
  });

  it("returns 500 when database insert fails", async () => {
    const singleMock = vi.fn().mockResolvedValue({ data: null, error: new Error("db error") });
    const selectMock = vi.fn().mockReturnValue({ single: singleMock });
    const insertMock = vi.fn().mockReturnValue({ select: selectMock });
    const fromMock = vi.fn().mockReturnValue({ insert: insertMock });

    const supabase = makeSupabaseMock({ from: fromMock });
    vi.mocked(createClient).mockResolvedValue(supabase as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);
    vi.mocked(getProjectById).mockResolvedValue(mockProject as never);

    const res = await POST(makeRequest({ name: "My CI" }), {
      params: Promise.resolve({ orgSlug: "my-org", projectId: "proj-1" }),
    });
    expect(res.status).toBe(500);
  });
});
