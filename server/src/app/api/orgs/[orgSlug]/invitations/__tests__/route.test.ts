import { describe, it, expect, vi, beforeEach } from "vitest";

// ---- Supabase mock factory ----
function makeSupabaseMock(
  overrides: {
    getClaims?: () => Promise<unknown>;
    from?: ReturnType<typeof vi.fn>;
  } = {},
) {
  const getClaims =
    overrides.getClaims ??
    vi
      .fn()
      .mockResolvedValue({
        data: { claims: { sub: "user-1" } },
        error: null,
      });

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
}));

vi.mock("@/lib/email/resend", () => ({
  sendEmail: vi.fn(),
}));

vi.mock("@/lib/email/templates/invitation", () => ({
  buildInvitationEmail: vi.fn().mockReturnValue({
    subject: "You've been invited to join Acme on OpenCI",
    html: "<p>invitation</p>",
  }),
}));

import { createClient } from "@/lib/supabase/server";
import { getOrgBySlug } from "@/lib/supabase/queries";
import { sendEmail } from "@/lib/email/resend";
import { buildInvitationEmail } from "@/lib/email/templates/invitation";
import { POST } from "../route";

const mockOrg = {
  id: "org-1",
  name: "Acme",
  slug: "acme",
  role: "admin",
};

const mockInvitation = {
  id: "inv-1",
  email: "new@example.com",
  role: "member",
  expires_at: "2026-03-01T00:00:00Z",
  token: "abc123token",
};

function makeRequest(body: unknown) {
  return new Request("http://localhost/api/orgs/acme/invitations", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });
}

function makeFromMock(
  resolvedValue: { data: unknown; error: unknown } = {
    data: mockInvitation,
    error: null,
  },
) {
  const singleMock = vi.fn().mockResolvedValue(resolvedValue);
  const selectMock = vi.fn().mockReturnValue({ single: singleMock });
  const insertMock = vi.fn().mockReturnValue({ select: selectMock });
  return vi.fn().mockReturnValue({ insert: insertMock });
}

describe("POST /api/orgs/[orgSlug]/invitations", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.stubEnv("NEXT_PUBLIC_APP_URL", "https://app.openci.io");
  });

  it("returns 401 when not authenticated", async () => {
    const supabase = makeSupabaseMock({
      getClaims: vi
        .fn()
        .mockResolvedValue({ data: null, error: new Error("Unauthorized") }),
    });
    vi.mocked(createClient).mockResolvedValue(supabase as never);

    const res = await POST(makeRequest({ email: "a@b.com" }), {
      params: Promise.resolve({ orgSlug: "acme" }),
    });
    expect(res.status).toBe(401);
    expect(sendEmail).not.toHaveBeenCalled();
  });

  it("returns 404 when org not found", async () => {
    const supabase = makeSupabaseMock();
    vi.mocked(createClient).mockResolvedValue(supabase as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(null);

    const res = await POST(makeRequest({ email: "a@b.com" }), {
      params: Promise.resolve({ orgSlug: "acme" }),
    });
    expect(res.status).toBe(404);
    expect(sendEmail).not.toHaveBeenCalled();
  });

  it("returns 403 when user is not admin or owner", async () => {
    const supabase = makeSupabaseMock();
    vi.mocked(createClient).mockResolvedValue(supabase as never);
    vi.mocked(getOrgBySlug).mockResolvedValue({
      ...mockOrg,
      role: "member",
    } as never);

    const res = await POST(makeRequest({ email: "a@b.com" }), {
      params: Promise.resolve({ orgSlug: "acme" }),
    });
    expect(res.status).toBe(403);
    expect(sendEmail).not.toHaveBeenCalled();
  });

  it("returns 400 for invalid JSON", async () => {
    const supabase = makeSupabaseMock();
    vi.mocked(createClient).mockResolvedValue(supabase as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);

    const badRequest = new Request("http://localhost/api/orgs/acme/invitations", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: "not json",
    });
    const res = await POST(badRequest, {
      params: Promise.resolve({ orgSlug: "acme" }),
    });
    expect(res.status).toBe(400);
    expect(sendEmail).not.toHaveBeenCalled();
  });

  it("returns 400 for invalid email", async () => {
    const supabase = makeSupabaseMock();
    vi.mocked(createClient).mockResolvedValue(supabase as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);

    const res = await POST(makeRequest({ email: "not-an-email" }), {
      params: Promise.resolve({ orgSlug: "acme" }),
    });
    expect(res.status).toBe(400);
    expect(sendEmail).not.toHaveBeenCalled();
  });

  it("returns 400 for invalid role", async () => {
    const supabase = makeSupabaseMock();
    vi.mocked(createClient).mockResolvedValue(supabase as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);

    const res = await POST(
      makeRequest({ email: "a@b.com", role: "superadmin" }),
      { params: Promise.resolve({ orgSlug: "acme" }) },
    );
    expect(res.status).toBe(400);
    expect(sendEmail).not.toHaveBeenCalled();
  });

  it("returns 409 for duplicate invitation", async () => {
    const fromMock = makeFromMock({
      data: null,
      error: { message: "duplicate key value violates unique constraint" },
    });
    const supabase = makeSupabaseMock({ from: fromMock });
    vi.mocked(createClient).mockResolvedValue(supabase as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);

    const res = await POST(makeRequest({ email: "a@b.com" }), {
      params: Promise.resolve({ orgSlug: "acme" }),
    });
    expect(res.status).toBe(409);
    expect(sendEmail).not.toHaveBeenCalled();
  });

  it("returns 500 on database error", async () => {
    const fromMock = makeFromMock({
      data: null,
      error: { message: "connection refused" },
    });
    const supabase = makeSupabaseMock({ from: fromMock });
    vi.mocked(createClient).mockResolvedValue(supabase as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);

    const res = await POST(makeRequest({ email: "a@b.com" }), {
      params: Promise.resolve({ orgSlug: "acme" }),
    });
    expect(res.status).toBe(500);
    expect(sendEmail).not.toHaveBeenCalled();
  });

  it("returns 201 and sends email on success", async () => {
    const fromMock = makeFromMock();
    const supabase = makeSupabaseMock({ from: fromMock });
    vi.mocked(createClient).mockResolvedValue(supabase as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);
    vi.mocked(sendEmail).mockResolvedValue({ id: "email-1" });

    const res = await POST(makeRequest({ email: "new@example.com" }), {
      params: Promise.resolve({ orgSlug: "acme" }),
    });
    expect(res.status).toBe(201);

    const body = (await res.json()) as {
      invitation: { id: string };
      inviteLink: string;
    };
    expect(body.invitation.id).toBe("inv-1");
    expect(body.inviteLink).toContain("abc123token");

    expect(buildInvitationEmail).toHaveBeenCalledWith({
      orgName: "Acme",
      role: "member",
      inviteLink: "https://app.openci.io/auth/accept-invite?token=abc123token",
    });
    expect(sendEmail).toHaveBeenCalledWith({
      to: "new@example.com",
      subject: "You've been invited to join Acme on OpenCI",
      html: "<p>invitation</p>",
    });
  });

  it("returns 201 even when email sending fails", async () => {
    const fromMock = makeFromMock();
    const supabase = makeSupabaseMock({ from: fromMock });
    vi.mocked(createClient).mockResolvedValue(supabase as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);
    vi.mocked(sendEmail).mockRejectedValue(new Error("Resend is down"));

    const consoleSpy = vi
      .spyOn(console, "error")
      .mockImplementation(() => {});

    const res = await POST(makeRequest({ email: "new@example.com" }), {
      params: Promise.resolve({ orgSlug: "acme" }),
    });
    expect(res.status).toBe(201);
    expect(consoleSpy).toHaveBeenCalledWith(
      "Failed to send invitation email:",
      expect.any(Error),
    );

    consoleSpy.mockRestore();
  });

  it("does not include token in response", async () => {
    const fromMock = makeFromMock();
    const supabase = makeSupabaseMock({ from: fromMock });
    vi.mocked(createClient).mockResolvedValue(supabase as never);
    vi.mocked(getOrgBySlug).mockResolvedValue(mockOrg as never);
    vi.mocked(sendEmail).mockResolvedValue({ id: "email-1" });

    const res = await POST(makeRequest({ email: "new@example.com" }), {
      params: Promise.resolve({ orgSlug: "acme" }),
    });
    const body = (await res.json()) as { invitation: Record<string, unknown> };
    expect(body.invitation).not.toHaveProperty("token");
  });
});
