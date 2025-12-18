import { App } from "@octokit/app";
import { Octokit } from "@octokit/rest";
import * as Sentry from "@sentry/cloudflare";
import type { Context } from "hono";
import {
	createInstance,
	deleteInstance,
	execCommand,
	fetchAvailableIncusInstances,
	waitForVMAgent,
} from "../services/incus";
import {
	notifyJobCancelled,
	notifyJobCompleted,
	notifyJobStarted,
} from "../services/slack";
import type { WorkflowJobPayload } from "../types/github.types";
import type { IncusEnv } from "../types/incus.types";

async function createOctokit(
	c: Context<{ Bindings: Env }>,
	installationId: number,
) {
	const app = new App({
		appId: c.env.GH_APP_ID,
		Octokit: Octokit,
		privateKey: c.env.GH_APP_PRIVATE_KEY,
	});

	return await app.getInstallationOctokit(installationId);
}

async function generateRunnerJitConfig(
	octokit: Octokit,
	payload: WorkflowJobPayload,
	runnerLabel: string,
) {
	const runnerName = "OpenCIランナーβ(開発環境)";

	const { data } = await octokit.rest.actions.generateRunnerJitconfigForRepo({
		labels: [runnerLabel],
		name: `${runnerName}-${Date.now()}`,
		owner: payload.repository.owner.login,
		repo: payload.repository.name,
		runner_group_id: 1,
		work_folder: "_work",
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

async function getOrCreateIncusInstance(
	incusEnv: IncusEnv,
	runId: number,
	baseImage: string,
): Promise<string> {
	console.log("Started to search available Incus VMs");

	const availableInstances = await fetchAvailableIncusInstances(incusEnv);
	console.log(`Found ${availableInstances.length} available Incus instances`);

	// 次のissueでVMのWarm Poolを実装する https://github.com/open-ci-io/openci/issues/591
	console.log("Start to create new Incus instance");
	const instanceName = generateInstanceName(runId);
	await createInstance(incusEnv, instanceName, baseImage);
	return instanceName;
}

export async function handleWorkflowJobQueued(
	c: Context<{ Bindings: Env }>,
	payload: WorkflowJobPayload,
) {
	const installationId = payload.installation?.id;
	if (!installationId) {
		Sentry.captureMessage("Installation ID not found", "warning");
		return c.text("Installation ID not found", 400);
	}

	const runId = payload.workflow_job?.run_id;
	if (!runId) {
		Sentry.captureMessage("Run ID not found in queued event", "warning");
		return c.text("Run ID not found", 400);
	}

	try {
		const octokit = await createOctokit(c, installationId);

		const encodedJitConfig = await generateRunnerJitConfig(
			octokit,
			payload,
			c.env.OPENCI_RUNNER_LABEL,
		);
		console.log("Successfully generated GHA JIT config");

		const incusEnv = {
			cloudflare_access_client_id: c.env.CF_ACCESS_CLIENT_ID,
			cloudflare_access_client_secret: c.env.CF_ACCESS_CLIENT_SECRET,
			server_url: c.env.INCUS_SERVER_URL,
		};

		c.executionCtx.waitUntil(
			(async () => {
				try {
					const instanceName = await getOrCreateIncusInstance(
						incusEnv,
						runId,
						c.env.OPENCI_RUNNER_BASE_IMAGE,
					);

					await waitForVMAgent(incusEnv, instanceName);

					await execCommand(
						incusEnv,
						instanceName,
						[
							"tmux",
							"new-session",
							"-d",
							"-s",
							"runner",
							`RUNNER_ALLOW_RUNASROOT=1 ./run.sh --jitconfig ${encodedJitConfig}`,
						],
						{ cwd: "/root/actions-runner" },
					);
					console.log(
						"Successfully registered as GitHub Actions Self-Hosted Runner",
					);

					if (c.env.SLACK_WEBHOOK_URL) {
						await notifyJobStarted(c.env.SLACK_WEBHOOK_URL, payload);
					}
				} catch (e) {
					Sentry.captureException(e);
					console.error("Background task failed:", e);
				}
			})(),
		);

		return c.text("Workflow job accepted, runner provisioning started", 202);
	} catch (e) {
		Sentry.captureException(e);
		console.error(e);
		return c.text("Internal Server Error", 500);
	}
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

export async function handleWorkflowJobCancelled(
	c: Context<{ Bindings: Env }>,
	payload: WorkflowJobPayload,
) {
	const runId = payload.workflow_job?.run_id;
	if (!runId) {
		Sentry.captureMessage("Run ID not found in cancelled event", "warning");
		return c.text("Run ID not found", 400);
	}

	try {
		await deleteRunnerInstance(c, runId);

		if (c.env.SLACK_WEBHOOK_URL) {
			await notifyJobCancelled(c.env.SLACK_WEBHOOK_URL, payload);
		}

		return c.text("Successfully deleted cancelled OpenCI runner", 200);
	} catch (e) {
		Sentry.captureException(e);
		console.error(e);
		return c.text("Internal Server Error", 500);
	}
}
