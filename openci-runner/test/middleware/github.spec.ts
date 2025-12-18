import {
	createExecutionContext,
	env,
	waitOnExecutionContext,
} from "cloudflare:test";
import { createHmac } from "node:crypto";
import { afterEach, describe, expect, it, vi } from "vitest";
import z from "zod";
import worker from "../../src/index";

const HttpMethod = z.enum([
	"GET",
	"POST",
	"PUT",
	"DELETE",
	"PATCH",
	"OPTIONS",
	"HEAD",
]);
type HttpMethod = z.infer<typeof HttpMethod>;

const IncomingRequest = Request<unknown, IncomingRequestCfProperties>;

vi.mock("@octokit/app", () => {
	return {
		App: vi.fn().mockImplementation(() => ({
			getInstallationOctokit: vi.fn().mockResolvedValue({
				rest: {
					actions: {
						generateRunnerJitconfigForRepo: vi.fn().mockResolvedValue({
							data: {
								encoded_jit_config: "mock-jit-config-base64",
								runner: { id: 1, name: "test-runner" },
							},
						}),
					},
				},
			}),
		})),
	};
});

vi.mock("../../src/services/incus", () => {
	return {
		createInstance: vi.fn(),
		fetchAvailableIncusInstances: vi.fn(),
	};
});

const createSignature = (payload: string, secret: string) =>
	`sha256=${createHmac("sha256", secret).update(payload).digest("hex")}`;

function mockRequest(method: HttpMethod, body?: string, signature?: string) {
	const headers: Record<string, string> = {
		"content-type": "application/json",
	};
	if (signature) {
		headers["x-hub-signature-256"] = signature;
	}
	const canHaveBody =
		method !== HttpMethod.enum.GET && method !== HttpMethod.enum.HEAD;
	return new IncomingRequest("http://example.com/webhook", {
		body: canHaveBody ? body : undefined,
		headers,
		method,
	});
}

const webhookSecret = env.GH_APP_WEBHOOK_SECRET;

afterEach(() => {
	vi.clearAllMocks();
});

describe("github middleware - signature verification", () => {
	it.each(
		HttpMethod.options.filter((e) => e !== HttpMethod.enum.POST),
	)("returns 401 for %s method without signature", async (method) => {
		const request = mockRequest(method, JSON.stringify({}));
		const ctx = createExecutionContext();
		const response = await worker.fetch(request, env, ctx);
		await waitOnExecutionContext(ctx);
		expect(response.status).toBe(401);
		if (method !== HttpMethod.enum.HEAD) {
			await expect(response.text()).resolves.toBe("Signature is null");
		}
	});

	it("returns 401 when signature is missing", async () => {
		const request = mockRequest(
			HttpMethod.enum.POST,
			JSON.stringify({ action: "ping" }),
		);
		const ctx = createExecutionContext();
		const response = await worker.fetch(request, env, ctx);
		await waitOnExecutionContext(ctx);
		expect(response.status).toBe(401);
		await expect(response.text()).resolves.toMatchInlineSnapshot(
			`"Signature is null"`,
		);
	});

	it("returns 401 when signature is not valid", async () => {
		const body = JSON.stringify({ action: "ping" });
		const invalidSignature = createSignature(body, "NOT_THE_REAL_SECRET");
		const request = mockRequest(HttpMethod.enum.POST, body, invalidSignature);
		const ctx = createExecutionContext();
		const response = await worker.fetch(request, env, ctx);
		await waitOnExecutionContext(ctx);
		expect(response.status).toBe(401);
		await expect(response.text()).resolves.toMatchInlineSnapshot(
			`"Unauthorized"`,
		);
	});

	it("allows request with valid signature", async () => {
		const body = JSON.stringify({ action: "ping" });
		const validSignature = createSignature(body, webhookSecret);
		const request = mockRequest(HttpMethod.enum.POST, body, validSignature);
		const ctx = createExecutionContext();
		const response = await worker.fetch(request, env, ctx);
		await waitOnExecutionContext(ctx);
		expect(response.status).toBe(200);
	});
});
