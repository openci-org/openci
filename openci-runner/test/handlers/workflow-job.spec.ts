import {
	createExecutionContext,
	env,
	waitOnExecutionContext,
} from "cloudflare:test";
import { createHmac } from "node:crypto";
import { afterEach, describe, expect, it, vi } from "vitest";
import worker from "../../src/index";

import {
	createInstance,
	deleteInstance,
	fetchAvailableIncusInstances,
} from "../../src/services/incus";
import {
	notifyJobCancelled,
	notifyJobCompleted,
	notifyJobStarted,
} from "../../src/services/slack";

const IncomingRequest = Request<unknown, IncomingRequestCfProperties>;

const mockGenerateJitConfig = vi.fn().mockResolvedValue({
	data: {
		encoded_jit_config: "mock-jit-config-base64",
		runner: {
			id: 1,
			name: "test-runner",
		},
	},
});

vi.mock("@octokit/app", () => {
	return {
		App: vi.fn().mockImplementation(() => ({
			getInstallationOctokit: vi.fn().mockResolvedValue({
				rest: {
					actions: {
						generateRunnerJitconfigForRepo: mockGenerateJitConfig,
					},
				},
			}),
		})),
	};
});

vi.mock("../../src/services/incus", () => {
	return {
		createInstance: vi.fn(),
		deleteInstance: vi.fn(),
		execCommand: vi.fn(),
		fetchAvailableIncusInstances: vi.fn(),
		waitForVMAgent: vi.fn(),
	};
});

vi.mock("../../src/services/slack", () => {
	return {
		notifyJobCancelled: vi.fn(),
		notifyJobCompleted: vi.fn(),
		notifyJobStarted: vi.fn(),
	};
});

// Use env values from wrangler.toml
const OPENCI_RUNNER_LABEL = "openci-runner-beta-dev";

const createSignature = (payload: string, secret: string) =>
	`sha256=${createHmac("sha256", secret).update(payload).digest("hex")}`;

function mockRequest(body: string, signature: string) {
	return new IncomingRequest("http://example.com/webhook", {
		body,
		headers: {
			"content-type": "application/json",
			"x-hub-signature-256": signature,
		},
		method: "POST",
	});
}

async function runFetch(body: Record<string, unknown>) {
	const _body = JSON.stringify(body);
	const signature = createSignature(_body, env.GH_APP_WEBHOOK_SECRET);
	const request = mockRequest(_body, signature);
	const ctx = createExecutionContext();
	const response = await worker.fetch(request, env, ctx);
	await waitOnExecutionContext(ctx);
	return response;
}

afterEach(() => {
	vi.clearAllMocks();
});

describe("workflow-job handler", () => {
	it("returns 202 when workflow job is accepted and runner provisioning starts", async () => {
		vi.mocked(fetchAvailableIncusInstances).mockResolvedValueOnce([
			{ name: "vm-1", status: "Stopped" },
		]);

		const response = await runFetch({
			action: "queued",
			installation: { id: 123456 },
			repository: {
				name: "test-repo",
				owner: { login: "test-owner" },
			},
			workflow_job: {
				id: 1,
				labels: [OPENCI_RUNNER_LABEL],
				run_id: 12345,
			},
		});

		expect(response.status).toBe(202);
		await expect(response.text()).resolves.toMatchInlineSnapshot(
			`"Workflow job accepted, runner provisioning started"`,
		);
	});

	it("returns 400 when installationId is undefined", async () => {
		const response = await runFetch({
			action: "queued",
			repository: {
				name: "test-repo",
				owner: { login: "test-owner" },
			},
			workflow_job: {
				id: 1,
				labels: [OPENCI_RUNNER_LABEL],
				run_id: 12345,
			},
		});

		expect(response.status).toBe(400);
		await expect(response.text()).resolves.toMatchInlineSnapshot(
			`"Installation ID not found"`,
		);
	});

	it("returns 500 when GitHub API fails", async () => {
		mockGenerateJitConfig.mockRejectedValueOnce(new Error("API Error"));

		const response = await runFetch({
			action: "queued",
			installation: { id: 123456 },
			repository: {
				name: "test-repo",
				owner: { login: "test-owner" },
			},
			workflow_job: {
				id: 1,
				labels: [OPENCI_RUNNER_LABEL],
				run_id: 12345,
			},
		});

		expect(response.status).toBe(500);
		await expect(response.text()).resolves.toMatchInlineSnapshot(
			`"Internal Server Error"`,
		);
	});

	it("returns 202 when fetchAvailableIncusInstances fails (error handled in background)", async () => {
		vi.mocked(fetchAvailableIncusInstances).mockRejectedValueOnce(
			new Error("Failed to connect to Incus server"),
		);

		const response = await runFetch({
			action: "queued",
			installation: { id: 123456 },
			repository: {
				name: "test-repo",
				owner: { login: "test-owner" },
			},
			workflow_job: {
				id: 1,
				labels: [OPENCI_RUNNER_LABEL],
				run_id: 12345,
			},
		});

		// Background task errors are logged but don't affect the response
		expect(response.status).toBe(202);
		await expect(response.text()).resolves.toBe(
			"Workflow job accepted, runner provisioning started",
		);
	});

	it("creates new instance when no available instances found", async () => {
		vi.mocked(fetchAvailableIncusInstances).mockResolvedValueOnce([]);
		vi.mocked(createInstance).mockResolvedValueOnce(undefined);

		const response = await runFetch({
			action: "queued",
			installation: { id: 123456 },
			repository: {
				name: "test-repo",
				owner: { login: "test-owner" },
			},
			workflow_job: {
				id: 1,
				labels: [OPENCI_RUNNER_LABEL],
				run_id: 12345,
			},
		});

		expect(response.status).toBe(202);
		await expect(response.text()).resolves.toBe(
			"Workflow job accepted, runner provisioning started",
		);
		expect(createInstance).toHaveBeenCalledWith(
			expect.objectContaining({
				cloudflare_access_client_id: env.CF_ACCESS_CLIENT_ID,
				cloudflare_access_client_secret: env.CF_ACCESS_CLIENT_SECRET,
				server_url: env.INCUS_SERVER_URL,
			}),
			"openci-runner-12345",
			env.OPENCI_RUNNER_BASE_IMAGE,
		);
	});

	it("returns 202 when createInstance fails (error handled in background)", async () => {
		vi.mocked(fetchAvailableIncusInstances).mockResolvedValueOnce([]);
		vi.mocked(createInstance).mockRejectedValueOnce(
			new Error("Failed to create instance"),
		);

		const response = await runFetch({
			action: "queued",
			installation: { id: 123456 },
			repository: {
				name: "test-repo",
				owner: { login: "test-owner" },
			},
			workflow_job: {
				id: 1,
				labels: [OPENCI_RUNNER_LABEL],
				run_id: 12345,
			},
		});

		// Background task errors are logged but don't affect the response
		expect(response.status).toBe(202);
		await expect(response.text()).resolves.toBe(
			"Workflow job accepted, runner provisioning started",
		);
		expect(createInstance).toHaveBeenCalledTimes(1);
	});

	it("returns 400 when run_id is undefined in queued action", async () => {
		const response = await runFetch({
			action: "queued",
			installation: { id: 123456 },
			repository: {
				name: "test-repo",
				owner: { login: "test-owner" },
			},
			workflow_job: {
				id: 1,
				labels: [OPENCI_RUNNER_LABEL],
			},
		});

		expect(response.status).toBe(400);
		await expect(response.text()).resolves.toBe("Run ID not found");
	});

	it("returns 200 when runner is deleted on completed action", async () => {
		vi.mocked(deleteInstance).mockResolvedValueOnce(undefined);

		const response = await runFetch({
			action: "completed",
			repository: {
				name: "test-repo",
				owner: { login: "test-owner" },
			},
			workflow_job: {
				id: 1,
				labels: [OPENCI_RUNNER_LABEL],
				run_id: 12345,
			},
		});

		expect(response.status).toBe(200);
		await expect(response.text()).resolves.toBe(
			"Successfully deleted OpenCI runner",
		);
		expect(deleteInstance).toHaveBeenCalledWith(
			expect.objectContaining({
				cloudflare_access_client_id: env.CF_ACCESS_CLIENT_ID,
				cloudflare_access_client_secret: env.CF_ACCESS_CLIENT_SECRET,
				server_url: env.INCUS_SERVER_URL,
			}),
			"openci-runner-12345",
		);
	});

	it("returns 400 when run_id is undefined in completed action", async () => {
		const response = await runFetch({
			action: "completed",
			repository: {
				name: "test-repo",
				owner: { login: "test-owner" },
			},
			workflow_job: {
				id: 1,
				labels: [OPENCI_RUNNER_LABEL],
			},
		});

		expect(response.status).toBe(400);
		await expect(response.text()).resolves.toBe("Run ID not found");
	});

	it("returns 500 when deleteInstance fails in completed action", async () => {
		vi.mocked(deleteInstance).mockRejectedValueOnce(
			new Error("Failed to delete instance"),
		);

		const response = await runFetch({
			action: "completed",
			repository: {
				name: "test-repo",
				owner: { login: "test-owner" },
			},
			workflow_job: {
				id: 1,
				labels: [OPENCI_RUNNER_LABEL],
				run_id: 12345,
			},
		});

		expect(response.status).toBe(500);
		await expect(response.text()).resolves.toBe("Internal Server Error");
	});

	it("calls notifyJobStarted when SLACK_WEBHOOK_URL is set", async () => {
		vi.mocked(fetchAvailableIncusInstances).mockResolvedValueOnce([]);
		vi.mocked(createInstance).mockResolvedValueOnce(undefined);

		const response = await runFetch({
			action: "queued",
			installation: { id: 123456 },
			repository: {
				name: "test-repo",
				owner: { login: "test-owner" },
			},
			workflow_job: {
				id: 1,
				labels: [OPENCI_RUNNER_LABEL],
				name: "test-job",
				run_id: 12345,
			},
		});

		expect(response.status).toBe(202);
		expect(vi.mocked(notifyJobStarted)).toHaveBeenCalledWith(
			env.SLACK_WEBHOOK_URL,
			expect.objectContaining({
				repository: { name: "test-repo", owner: { login: "test-owner" } },
				workflow_job: expect.objectContaining({ name: "test-job" }),
			}),
		);
	});

	it("calls notifyJobCompleted when SLACK_WEBHOOK_URL is set", async () => {
		vi.mocked(deleteInstance).mockResolvedValueOnce(undefined);

		const response = await runFetch({
			action: "completed",
			repository: {
				name: "test-repo",
				owner: { login: "test-owner" },
			},
			workflow_job: {
				conclusion: "success",
				id: 1,
				labels: [OPENCI_RUNNER_LABEL],
				name: "test-job",
				run_id: 12345,
			},
		});

		expect(response.status).toBe(200);
		expect(vi.mocked(notifyJobCompleted)).toHaveBeenCalledWith(
			env.SLACK_WEBHOOK_URL,
			expect.objectContaining({
				repository: { name: "test-repo", owner: { login: "test-owner" } },
				workflow_job: expect.objectContaining({
					conclusion: "success",
					name: "test-job",
				}),
			}),
		);
	});

	it("returns 200 when runner is deleted on cancelled action", async () => {
		vi.mocked(deleteInstance).mockResolvedValueOnce(undefined);

		const response = await runFetch({
			action: "cancelled",
			repository: {
				name: "test-repo",
				owner: { login: "test-owner" },
			},
			workflow_job: {
				id: 1,
				labels: [OPENCI_RUNNER_LABEL],
				run_id: 12345,
			},
		});

		expect(response.status).toBe(200);
		await expect(response.text()).resolves.toBe(
			"Successfully deleted cancelled OpenCI runner",
		);
		expect(deleteInstance).toHaveBeenCalledWith(
			expect.objectContaining({
				cloudflare_access_client_id: env.CF_ACCESS_CLIENT_ID,
				cloudflare_access_client_secret: env.CF_ACCESS_CLIENT_SECRET,
				server_url: env.INCUS_SERVER_URL,
			}),
			"openci-runner-12345",
		);
	});

	it("returns 400 when run_id is undefined in cancelled action", async () => {
		const response = await runFetch({
			action: "cancelled",
			repository: {
				name: "test-repo",
				owner: { login: "test-owner" },
			},
			workflow_job: {
				id: 1,
				labels: [OPENCI_RUNNER_LABEL],
			},
		});

		expect(response.status).toBe(400);
		await expect(response.text()).resolves.toBe("Run ID not found");
	});

	it("returns 500 when deleteInstance fails in cancelled action", async () => {
		vi.mocked(deleteInstance).mockRejectedValueOnce(
			new Error("Failed to delete instance"),
		);

		const response = await runFetch({
			action: "cancelled",
			repository: {
				name: "test-repo",
				owner: { login: "test-owner" },
			},
			workflow_job: {
				id: 1,
				labels: [OPENCI_RUNNER_LABEL],
				run_id: 12345,
			},
		});

		expect(response.status).toBe(500);
		await expect(response.text()).resolves.toBe("Internal Server Error");
	});

	it("calls notifyJobCancelled when SLACK_WEBHOOK_URL is set on cancelled action", async () => {
		vi.mocked(deleteInstance).mockResolvedValueOnce(undefined);

		const response = await runFetch({
			action: "cancelled",
			repository: {
				name: "test-repo",
				owner: { login: "test-owner" },
			},
			workflow_job: {
				conclusion: "cancelled",
				id: 1,
				labels: [OPENCI_RUNNER_LABEL],
				name: "test-job",
				run_id: 12345,
			},
		});

		expect(response.status).toBe(200);
		expect(vi.mocked(notifyJobCancelled)).toHaveBeenCalledWith(
			env.SLACK_WEBHOOK_URL,
			expect.objectContaining({
				repository: { name: "test-repo", owner: { login: "test-owner" } },
				workflow_job: expect.objectContaining({
					conclusion: "cancelled",
					name: "test-job",
				}),
			}),
		);
	});
});
