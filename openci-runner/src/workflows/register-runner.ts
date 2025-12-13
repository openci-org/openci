import {
	WorkflowEntrypoint,
	type WorkflowEvent,
	type WorkflowStep,
} from "cloudflare:workers";
import { NonRetryableError } from "cloudflare:workflows";
import type { WorkflowJobQueuedEvent } from "@octokit/webhooks-types";
import * as Sentry from "@sentry/cloudflare";
import type { Context } from "hono";
import {
	createOctokit,
	generateInstanceName,
	generateRunnerJitConfig,
} from "../handlers/workflow-job";
import {
	fetchStatusOfOperation,
	requestCreateInstance,
} from "../services/incus";
import { IncusAsyncResponseSchema, type IncusEnv } from "../types/incus.types";

type Params = {
	githubPayload: WorkflowJobQueuedEvent;
	c: Context<{ Bindings: Env }>;
};

export class RegisterRunner extends WorkflowEntrypoint<Env, Params> {
	async run(event: WorkflowEvent<Params>, step: WorkflowStep) {
		const _githubPayload = event.payload.githubPayload;
		const _honoContext = event.payload.c;
		const _honoEnv = _honoContext.env;
		const installationId = _githubPayload.installation?.id;
		if (!installationId) {
			Sentry.captureMessage("Installation ID not found", "warning");
			return _honoContext.text("Installation ID not found", 400);
		}

		const runId = _githubPayload.workflow_job?.run_id;
		if (!runId) {
			Sentry.captureMessage("Run ID not found in queued event", "warning");
			return _honoContext.text("Run ID not found", 400);
		}

		const incusEnv: IncusEnv = {
			cloudflare_access_client_id: _honoEnv.CF_ACCESS_CLIENT_ID,
			cloudflare_access_client_secret: _honoEnv.CF_ACCESS_CLIENT_SECRET,
			server_url: _honoEnv.INCUS_SERVER_URL,
		};

		const instanceName = generateInstanceName(runId);

		const operationId = await step.do(
			"create an incus instance",

			async () => {
				console.log("Incus instance creation initiated");

				const operationId = await requestCreateInstance(
					incusEnv,
					instanceName,
					_honoEnv.OPENCI_RUNNER_BASE_IMAGE,
				);

				if (!operationId) {
					throw new NonRetryableError("Failed to initiate instance creation");
				}

				return operationId;
			},
		);

		await step.do(
			"wait for instance creation to complete",
			{
				retries: {
					backoff: "constant",
					delay: "1 seconds",
					limit: 30,
				},
			},
			async () => {
				console.log(
					`Waiting for Incus instance creation operation ${operationId} to complete...`,
				);
				const result = await fetchStatusOfOperation(incusEnv, operationId);
				if (result.status === "Success") {
					console.log(`Incus instance ${instanceName} created successfully`);
					return;
				}
				if (result.status === "Running" || result.status === "Pending") {
					throw new Error(
						`Incus instance creation still in progress with status: ${result.status}`,
					);
				}
				throw new NonRetryableError(
					`Incus instance creation failed with status: ${result.status}`,
				);
			},
		);

		const encodedJitConfig = await step.do(
			"post instance creation tasks",
			async () => {
				const octokit = await createOctokit(_honoContext, installationId);

				const res = await generateRunnerJitConfig(
					octokit,
					_githubPayload.repository.owner.login,
					_githubPayload.repository.name,
					_honoEnv.OPENCI_RUNNER_LABEL,
				);
				console.log("Successfully generated GHA JIT config");
				return res;
			},
		);

		const incusAsyncResponse = await step.do(
			"finalize runner setup",
			async () => {
				const command = [
					"tmux",
					"new-session",
					"-d",
					"-s",
					"runner",
					`RUNNER_ALLOW_RUNASROOT=1 ./run.sh --jitconfig ${encodedJitConfig}`,
				];

				const baseUrl = _honoEnv.INCUS_SERVER_URL;
				const execUrl = `${baseUrl}/1.0/instances/${instanceName}/exec`;

				const requestBody = {
					command,
					cwd: "/root/actions-runner",
					environment: {},
					interactive: false,
					"record-output": true,
					"wait-for-websocket": false,
				};

				const response = await fetch(execUrl, {
					body: JSON.stringify(requestBody),
					headers: {
						"CF-Access-Client-Id": incusEnv.cloudflare_access_client_id,
						"CF-Access-Client-Secret": incusEnv.cloudflare_access_client_secret,
						"Content-Type": "application/json",
					},
					method: "POST",
				});

				if (!response.ok) {
					throw new NonRetryableError(
						`Failed to execute command in Incus instance: ${response.status} ${response.statusText}`,
					);
				}

				return IncusAsyncResponseSchema.parse(await response.json());
			},
		);

		if (incusAsyncResponse.metadata?.status !== "Success") {
			await step.do("wait for runner setup command to complete", async () => {
				const baseUrl = _honoEnv.INCUS_SERVER_URL;
				const operationUrl = `${baseUrl}/1.0/operations/${operationId}`;
				const cloudflareAccessHeaders = {
					"CF-Access-Client-Id": _honoEnv.CF_ACCESS_CLIENT_ID,
					"CF-Access-Client-Secret": _honoEnv.CF_ACCESS_CLIENT_SECRET,
				};

				const response = await fetch(operationUrl, {
					headers: cloudflareAccessHeaders,
				});

				if (!response.ok) {
					throw new NonRetryableError(
						`Failed to check operation status: ${response.status} ${response.statusText}`,
					);
				}

				const result = IncusAsyncResponseSchema.parse(await response.json());

				if (result.metadata?.status === "Success") {
					console.log("Runner setup command completed successfully");
					return;
				} else if (
					result.metadata?.status === "Running" ||
					result.metadata?.status === "Pending"
				) {
					throw new Error(
						`Runner setup command still in progress with status: ${result.metadata?.status}`,
					);
				} else {
					throw new NonRetryableError(
						`Runner setup command failed with status: ${result.metadata?.status}`,
					);
				}
			});
		}
	}
}
