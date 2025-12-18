import {
	createExecutionContext,
	env,
	waitOnExecutionContext,
} from "cloudflare:test";
import { createHmac } from "node:crypto";
import { afterEach, describe, expect, it, vi } from "vitest";
import worker from "../../src/index";
import { fetchAvailableIncusInstances } from "../../src/services/incus";

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
		deleteInstance: vi.fn(),
		execCommand: vi.fn(),
		fetchAvailableIncusInstances: vi.fn(),
		OPENCI_RUNNER_BASE_IMAGE: "openci-runner-0.0.4",
		waitForVMAgent: vi.fn(),
	};
});

vi.mock("../../src/services/slack", () => {
	return {
		notifyJobCompleted: vi.fn(),
		notifyJobStarted: vi.fn(),
	};
});

// Use env.OPENCI_RUNNER_LABEL from wrangler.toml
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

describe("webhook route", () => {
	it("responds with 200 for non-workflow_job events", async () => {
		const response = await runFetch({ action: "ping" });

		expect(response.status).toBe(200);
		await expect(response.text()).resolves.toMatchInlineSnapshot(
			`"Event ignored"`,
		);
	});

	it("responds with 200 when workflow_job action is not supported", async () => {
		const response = await runFetch({
			action: "in_progress",
			workflow_job: { labels: [OPENCI_RUNNER_LABEL] },
		});
		expect(response.status).toBe(200);
		await expect(response.text()).resolves.toMatchInlineSnapshot(
			`"Workflow Job action not supported"`,
		);
	});

	it("forwards queued workflow_job events to handler when openci-runner-beta label is present", async () => {
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

	it("ignores queued workflow_job events without openci-runner-beta label", async () => {
		const response = await runFetch({
			action: "queued",
			installation: { id: 123456 },
			repository: {
				name: "test-repo",
				owner: { login: "test-owner" },
			},
			workflow_job: {
				id: 1,
				labels: ["self-hosted", "linux"],
			},
		});

		expect(response.status).toBe(200);
		await expect(response.text()).resolves.toMatchInlineSnapshot(
			`"Workflow Job does not target OpenCI runner"`,
		);
	});

	it("deletes instance when workflow_job is completed", async () => {
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
		await expect(response.text()).resolves.toMatchInlineSnapshot(
			`"Successfully deleted OpenCI runner"`,
		);
	});
});
