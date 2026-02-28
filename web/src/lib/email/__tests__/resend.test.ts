import { describe, it, expect, vi, beforeEach } from "vitest";

const mockSend = vi.fn();

vi.mock("resend", () => {
  return {
    Resend: vi.fn().mockImplementation(function (this: { emails: { send: typeof mockSend } }) {
      this.emails = { send: mockSend };
    }),
  };
});

import { sendEmail, _resetForTesting } from "../resend";

describe("sendEmail", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    _resetForTesting();
    vi.stubEnv("RESEND_API_KEY", "re_test_key");
    vi.stubEnv("RESEND_FROM_EMAIL", "OpenCI <noreply@openci.io>");
  });

  it("throws when RESEND_API_KEY is not set", async () => {
    vi.stubEnv("RESEND_API_KEY", "");
    await expect(
      sendEmail({ to: "a@b.com", subject: "Hi", html: "<p>hi</p>" }),
    ).rejects.toThrow("RESEND_API_KEY");
  });

  it("throws when RESEND_FROM_EMAIL is not set and no from override", async () => {
    vi.stubEnv("RESEND_FROM_EMAIL", "");
    await expect(
      sendEmail({ to: "a@b.com", subject: "Hi", html: "<p>hi</p>" }),
    ).rejects.toThrow("RESEND_FROM_EMAIL");
  });

  it("returns id on success", async () => {
    mockSend.mockResolvedValue({ data: { id: "email-123" }, error: null });
    const result = await sendEmail({
      to: "user@example.com",
      subject: "Test",
      html: "<p>test</p>",
    });
    expect(result).toEqual({ id: "email-123" });
    expect(mockSend).toHaveBeenCalledWith({
      from: "OpenCI <noreply@openci.io>",
      to: "user@example.com",
      subject: "Test",
      html: "<p>test</p>",
    });
  });

  it("throws on Resend API error", async () => {
    mockSend.mockResolvedValue({
      data: null,
      error: { message: "Rate limit exceeded" },
    });
    await expect(
      sendEmail({ to: "a@b.com", subject: "Hi", html: "<p>hi</p>" }),
    ).rejects.toThrow("Resend API error: Rate limit exceeded");
  });

  it("uses from override when provided", async () => {
    mockSend.mockResolvedValue({ data: { id: "email-456" }, error: null });
    await sendEmail({
      to: "user@example.com",
      subject: "Test",
      html: "<p>test</p>",
      from: "Custom <custom@openci.io>",
    });
    expect(mockSend).toHaveBeenCalledWith(
      expect.objectContaining({ from: "Custom <custom@openci.io>" }),
    );
  });

  it("uses RESEND_FROM_EMAIL as default sender", async () => {
    mockSend.mockResolvedValue({ data: { id: "email-789" }, error: null });
    await sendEmail({
      to: "user@example.com",
      subject: "Test",
      html: "<p>test</p>",
    });
    expect(mockSend).toHaveBeenCalledWith(
      expect.objectContaining({ from: "OpenCI <noreply@openci.io>" }),
    );
  });

  it("sends to multiple recipients", async () => {
    mockSend.mockResolvedValue({ data: { id: "email-multi" }, error: null });
    await sendEmail({
      to: ["a@b.com", "c@d.com"],
      subject: "Test",
      html: "<p>test</p>",
    });
    expect(mockSend).toHaveBeenCalledWith(
      expect.objectContaining({ to: ["a@b.com", "c@d.com"] }),
    );
  });
});
