import {
	createExecutionContext,
	env,
	waitOnExecutionContext,
} from "cloudflare:test";
import { describe, expect, it, vi } from "vitest";
import worker from "../../src/index";

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

describe("validate-env middleware", () => {
	it.each([
		["GH_APP_WEBHOOK_SECRET", { GH_APP_WEBHOOK_SECRET: undefined }],
		["GH_APP_ID", { GH_APP_ID: undefined }],
		["GH_APP_PRIVATE_KEY", { GH_APP_PRIVATE_KEY: undefined }],
		["CF_ACCESS_CLIENT_ID", { CF_ACCESS_CLIENT_ID: undefined }],
		["CF_ACCESS_CLIENT_SECRET", { CF_ACCESS_CLIENT_SECRET: undefined }],
		["INCUS_SERVER_URL", { INCUS_SERVER_URL: undefined }],
	])("returns 500 when %s not provided", async (envName, overrideEnv) => {
		const request = new IncomingRequest("http://example.com/webhook", {
			body: "{}",
			headers: { "content-type": "application/json" },
			method: "POST",
		});
		const ctx = createExecutionContext();
		const response = await worker.fetch(
			request,
			{ ...env, ...overrideEnv },
			ctx,
		);
		await waitOnExecutionContext(ctx);
		expect(response.status).toBe(500);
		await expect(response.text()).resolves.toBe(`${envName} not provided`);
	});
});
