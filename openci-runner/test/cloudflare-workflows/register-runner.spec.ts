import { env, introspectWorkflowInstance } from "cloudflare:test";
import { expect, it } from "vitest";
import { mockGithubPayload } from "./mock-github-payload";

const mockWorkflowParams = {
	cloudflare_access_client_id: "test-cf-client-id",
	cloudflare_access_client_secret: "test-cf-client-secret",
	github_app_id: "test-app-id",
	github_app_private_key: "test-private-key",
	github_workflow_job_queued_event: mockGithubPayload,
	incus_server_url: "https://incus.example.com",
	openci_runner_base_image: "test-base-image",
	openci_runner_label: "test-runner-label",
};

it("initial state", async () => {
	const instanceId = "test-initial-state";
	const instance = await introspectWorkflowInstance(
		env.REGISTER_RUNNER,
		instanceId,
	);

	await instance.modify(async (m) => {
		await m.disableSleeps();
	});

	await env.REGISTER_RUNNER.create({
		id: instanceId,
		params: mockWorkflowParams,
	});
	await expect(instance.waitForStatus("complete")).resolves.not.toThrow();

	await instance.dispose();
});

it("GitHub installation_id is missing", async () => {
	const instanceId = "test-missing-installation-id";
	const instance = await introspectWorkflowInstance(
		env.REGISTER_RUNNER,
		instanceId,
	);

	await instance.modify(async (m) => {
		await m.disableSleeps();
	});

	const paramsWithoutInstallationId = {
		...mockWorkflowParams,
		github_workflow_job_queued_event: {
			...mockGithubPayload,
			installation: undefined,
		},
	};

	await env.REGISTER_RUNNER.create({
		id: instanceId,
		params: paramsWithoutInstallationId,
	});
	await expect(instance.waitForStatus("errored")).resolves.not.toThrow();

	await instance.dispose();
});
