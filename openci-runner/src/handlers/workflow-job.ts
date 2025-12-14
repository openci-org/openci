import { App } from "@octokit/app";
import { Octokit } from "@octokit/rest";
import * as Sentry from "@sentry/cloudflare";
import type { Context } from "hono";
import { deleteInstance } from "../services/incus";
import { notifyJobCompleted } from "../services/slack";
import type { WorkflowJobPayload } from "../types/github.types";

export async function createOctokit(
	github_app_id: string,
	github_app_private_key: string,
	installationId: number,
) {
	const app = new App({
		appId: github_app_id,
		Octokit: Octokit,
		privateKey: github_app_private_key,
	});

	return await app.getInstallationOctokit(installationId);
}

export async function generateRunnerJitConfig(
	octokit: Octokit,
	owner: string,
	repositoryName: string,
	runnerLabel: string,
) {
	const runnerName = "OpenCIランナーβ(開発環境)";
	const workingDIrectory = "_work";

	const { data } = await octokit.rest.actions.generateRunnerJitconfigForRepo({
		labels: [runnerLabel],
		name: `${runnerName}-${Date.now()}`,
		owner: owner,
		repo: repositoryName,
		runner_group_id: 1,
		work_folder: workingDIrectory,
	});

	return data.encoded_jit_config;
}

export function generateInstanceName(runId: number): string {
	return `openci-runner-${runId}`;
}

async function deleteRunnerInstance(
	c: Context<{ Bindings: Env }>,
	runId: number,
): Promise<void> {
	const incusEnv = {
		cloudflare_access_client_id: c.env.CF_ACCESS_CLIENT_ID,
		cloudflare_access_client_secret: c.env.CF_ACCESS_CLIENT_SECRET,
		server_url: c.env.INCUS_SERVER_URL,
	};

	const instanceName = generateInstanceName(runId);
	await deleteInstance(incusEnv, instanceName);
}

export async function handleWorkflowJobCompleted(
	c: Context<{ Bindings: Env }>,
	payload: WorkflowJobPayload,
) {
	const runId = payload.workflow_job?.run_id;
	if (!runId) {
		Sentry.captureMessage("Run ID not found in completed event", "warning");
		return c.text("Run ID not found", 400);
	}

	try {
		await deleteRunnerInstance(c, runId);

		if (c.env.SLACK_WEBHOOK_URL) {
			await notifyJobCompleted(c.env.SLACK_WEBHOOK_URL, payload);
		}

		return c.text("Successfully deleted OpenCI runner", 200);
	} catch (e) {
		Sentry.captureException(e);
		console.error(e);
		return c.text("Internal Server Error", 500);
	}
}
