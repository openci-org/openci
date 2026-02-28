import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { buildInvitationEmail } from "../templates/invitation";

describe("buildInvitationEmail", () => {
  beforeEach(() => {
    vi.stubEnv("NODE_ENV", "production");
  });

  afterEach(() => {
    vi.unstubAllEnvs();
  });

  const baseParams = {
    orgName: "Acme Corp",
    role: "admin",
    inviteLink: "https://app.openci.io/auth/accept-invite?token=abc123",
  };

  it("returns subject containing org name", () => {
    const { subject } = buildInvitationEmail(baseParams);
    expect(subject).toContain("Acme Corp");
    expect(subject).toContain("OpenCI");
  });

  it("html contains org name, role, and invite link", () => {
    const { html } = buildInvitationEmail(baseParams);
    expect(html).toContain("Acme Corp");
    expect(html).toContain("admin");
    expect(html).toContain(
      "https://app.openci.io/auth/accept-invite?token=abc123",
    );
  });

  it("html contains Accept Invitation button", () => {
    const { html } = buildInvitationEmail(baseParams);
    expect(html).toContain("Accept Invitation");
  });

  it("escapes special characters in org name", () => {
    const { html } = buildInvitationEmail({
      ...baseParams,
      orgName: '<script>alert("xss")</script>',
    });
    expect(html).not.toContain("<script>");
    expect(html).toContain("&lt;script&gt;");
  });

  it("includes dev banner when NODE_ENV is development", () => {
    vi.stubEnv("NODE_ENV", "development");
    const { html } = buildInvitationEmail(baseParams);
    expect(html).toContain("development environment");
  });

  it("excludes dev banner when NODE_ENV is production", () => {
    vi.stubEnv("NODE_ENV", "production");
    const { html } = buildInvitationEmail(baseParams);
    expect(html).not.toContain("development environment");
  });

  it("returns valid HTML structure", () => {
    const { html } = buildInvitationEmail(baseParams);
    expect(html).toContain("<!DOCTYPE html>");
    expect(html).toContain("OpenCI");
  });
});
