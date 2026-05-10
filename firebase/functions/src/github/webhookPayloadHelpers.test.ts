import { describe, expect, it, vi } from "vitest";

import {
  branchFromRef,
  ownerFromFullName,
  parseWebhookRequest,
  requireInstallationId,
} from "./webhookPayloadHelpers.js";

function makeResponse() {
  const send = vi.fn();
  return {
    response: {
      status: vi.fn(() => ({ send })),
    },
    send,
  };
}

describe("branchFromRef", () => {
  it("removes the refs heads prefix", () => {
    expect(branchFromRef("refs/heads/main")).toBe("main");
    expect(branchFromRef("refs/heads/feature/test")).toBe("feature/test");
  });

  it("leaves non-head refs unchanged", () => {
    expect(branchFromRef("refs/tags/v1.0.0")).toBe("refs/tags/v1.0.0");
    expect(branchFromRef("main")).toBe("main");
  });
});

describe("ownerFromFullName", () => {
  it("extracts the owner segment from full_name", () => {
    expect(ownerFromFullName("openci-org/openci")).toBe("openci-org");
  });

  it("returns the whole value when there is no slash", () => {
    expect(ownerFromFullName("openci")).toBe("openci");
  });
});

describe("requireInstallationId", () => {
  it("returns the installation id when present", () => {
    const response = {
      status: vi.fn(),
    };

    expect(requireInstallationId({ id: 123 }, response as never)).toBe(123);
    expect(response.status).not.toHaveBeenCalled();
  });

  it("responds with 400 when installation id is missing", () => {
    const send = vi.fn();
    const response = {
      status: vi.fn(() => ({ send })),
    };

    expect(requireInstallationId(undefined, response as never)).toBeUndefined();
    expect(response.status).toHaveBeenCalledWith(400);
    expect(send).toHaveBeenCalledWith("Missing installation ID in webhook payload");
  });
});

describe("parseWebhookRequest", () => {
  it("returns parsed webhook request fields", () => {
    const { response } = makeResponse();
    const request = {
      header: vi.fn((name: string) => {
        if (name === "x-github-event") return "push";
        if (name === "x-hub-signature-256") return "sha256=signature";
        if (name === "x-github-delivery") return "delivery-1";
        return undefined;
      }),
      rawBody: Buffer.from('{"ok":true}'),
    };

    expect(parseWebhookRequest(request as never, response as never)).toEqual({
      eventType: "push",
      payload: '{"ok":true}',
      signatureHeader: "sha256=signature",
      deliveryId: "delivery-1",
    });
    expect(response.status).not.toHaveBeenCalled();
  });

  it("responds with 400 when the event header is missing", () => {
    const { response, send } = makeResponse();
    const request = {
      header: vi.fn(() => undefined),
      rawBody: Buffer.from("{}"),
    };

    expect(parseWebhookRequest(request as never, response as never)).toBeUndefined();
    expect(response.status).toHaveBeenCalledWith(400);
    expect(send).toHaveBeenCalledWith("Missing x-github-event header");
  });

  it("responds with 400 when the body is missing", () => {
    const { response, send } = makeResponse();
    const request = {
      header: vi.fn((name: string) => (name === "x-github-event" ? "push" : undefined)),
    };

    expect(parseWebhookRequest(request as never, response as never)).toBeUndefined();
    expect(response.status).toHaveBeenCalledWith(400);
    expect(send).toHaveBeenCalledWith("Missing request body");
  });

  it("responds with 400 when the signature header is missing", () => {
    const { response, send } = makeResponse();
    const request = {
      header: vi.fn((name: string) => (name === "x-github-event" ? "push" : undefined)),
      rawBody: Buffer.from("{}"),
    };

    expect(parseWebhookRequest(request as never, response as never)).toBeUndefined();
    expect(response.status).toHaveBeenCalledWith(400);
    expect(send).toHaveBeenCalledWith("Missing x-hub-signature-256 header");
  });

  it("responds with 400 when the delivery header is missing", () => {
    const { response, send } = makeResponse();
    const request = {
      header: vi.fn((name: string) => {
        if (name === "x-github-event") return "push";
        if (name === "x-hub-signature-256") return "sha256=signature";
        return undefined;
      }),
      rawBody: Buffer.from("{}"),
    };

    expect(parseWebhookRequest(request as never, response as never)).toBeUndefined();
    expect(response.status).toHaveBeenCalledWith(400);
    expect(send).toHaveBeenCalledWith("Missing x-github-delivery header");
  });
});
