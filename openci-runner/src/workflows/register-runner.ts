import {
	WorkflowEntrypoint,
	type WorkflowEvent,
	type WorkflowStep,
} from "cloudflare:workers";
import { NonRetryableError } from "cloudflare:workflows";
import type { WorkflowJobQueuedEvent } from "@octokit/webhooks-types";
import * as Sentry from "@sentry/cloudflare";
import {
	createOctokit,
	generateInstanceName,
	generateRunnerJitConfig,
} from "../handlers/workflow-job";
import { requestCreateInstance } from "../services/incus";
import {
	IncusAsyncResponseSchema,
	type IncusEnv,
	IncusInstanceStateResponseSchema,
} from "../types/incus.types";

type Params = {
	githubPayload: WorkflowJobQueuedEvent;
	github_app_id: string;
	github_app_private_key: string;
	cloudflare_access_client_id: string;
	cloudflare_access_client_secret: string;
	incus_server_url: string;
	openci_runner_base_image: string;
	openci_runner_label: string;
};

export class RegisterRunner extends WorkflowEntrypoint<Env, Params> {
	async run(event: WorkflowEvent<Params>, step: WorkflowStep) {
		console.log("RegisterRunner workflow started");
		const _env = event.payload;
		const _githubPayload = _env.githubPayload;

		const installationId = _githubPayload.installation?.id;
		if (!installationId) {
			Sentry.captureMessage("Installation ID not found", "warning");
			throw new NonRetryableError("Installation ID not found");
		}

		const runId = _githubPayload.workflow_job?.run_id;
		if (!runId) {
			Sentry.captureMessage("Run ID not found in queued event", "warning");
			throw new NonRetryableError("Run ID not found");
		}

		const incusEnv: IncusEnv = {
			cloudflare_access_client_id: _env.cloudflare_access_client_id,
			cloudflare_access_client_secret: _env.cloudflare_access_client_secret,
			server_url: _env.incus_server_url,
		};

		const instanceName = generateInstanceName(runId);
		console.log(`Generated instance name: ${instanceName}`);

		const operationIdOfCreatingIncusInstance = await step.do(
			"create an incus instance",

			async () => {
				console.log("Incus instance creation initiated");

				const operationId = await requestCreateInstance(
					incusEnv,
					instanceName,
					_env.openci_runner_base_image,
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
					`Waiting for Incus instance creation operation ${operationIdOfCreatingIncusInstance} to complete...`,
				);

				const baseUrl = _env.incus_server_url;
				const operationUrl = `${baseUrl}/1.0/operations/${operationIdOfCreatingIncusInstance}`;
				const cloudflareAccessHeaders = {
					"CF-Access-Client-Id": _env.cloudflare_access_client_id,
					"CF-Access-Client-Secret": _env.cloudflare_access_client_secret,
				};

				const response = await fetch(operationUrl, {
					headers: cloudflareAccessHeaders,
				});

				if (!response.ok) {
					throw new Error(
						`Failed to check operation status: ${response.status} ${response.statusText}`,
					);
				}
				const json = await response.json();
				const result = IncusAsyncResponseSchema.parse(json);
				console.log("Operation status response:", json);

				const status = result.metadata?.status;
				if (status === "Failure") {
					throw new NonRetryableError(
						`Incus instance creation failed with status: ${result.metadata}`,
					);
				}
				if (status === "Success") {
					console.log(`Incus instance ${instanceName} created successfully`);
					return;
				}
				if (status === "Running" || status === "Pending") {
					throw new Error(
						`Incus instance creation still in progress with status: ${status}`,
					);
				}
				throw new NonRetryableError(
					`Incus instance creation failed with status: ${status}`,
				);
			},
		);

		const encodedJitConfig = await step.do(
			"generate JIT config for GitHub Actions runner",
			async () => {
				const octokit = await createOctokit(
					_env.github_app_id,
					_env.github_app_private_key,
					installationId,
				);

				const res = await generateRunnerJitConfig(
					octokit,
					_githubPayload.repository.owner.login,
					_githubPayload.repository.name,
					_env.openci_runner_label,
				);
				console.log("Successfully generated GHA JIT config");
				return res;
			},
		);

		await step.do("Wait for VM and agent to be ready", async () => {
			const baseUrl = _env.incus_server_url;
			const execUrl = `${baseUrl}/1.0/instances/${instanceName}/state`;

			const response = await fetch(execUrl, {
				headers: {
					"CF-Access-Client-Id": incusEnv.cloudflare_access_client_id,
					"CF-Access-Client-Secret": incusEnv.cloudflare_access_client_secret,
				},
				method: "GET",
			});

			if (!response.ok) {
				throw new NonRetryableError(
					`Failed to get VM state: ${response.status} ${response.statusText}`,
				);
			}

			const json = await response.json();

			console.log("IncusVMStatusResult:", json);

			const result = IncusInstanceStateResponseSchema.parse(json);

			const incusVMStatus = result.metadata.status;
			const processes = result.metadata.processes;

			switch (incusVMStatus) {
				case "Frozen":
					throw new NonRetryableError(
						"Incus VM has some issues: Status: Frozen. Shutting down.",
					);
				case "Error":
					throw new NonRetryableError(
						"Incus VM has some issues: Status: Error. Shutting down.",
					);
				case "Running":
					if (processes <= 0) {
						console.log(
							`VM is running but agent not ready yet (processes: ${processes}). Waiting...`,
						);
						throw new Error("VM agent is not ready yet");
					}
					console.log(
						`VM has started and agent is ready! (processes: ${processes})`,
					);
					return;
				case "Stopped":
					throw new Error("VM is now stopped. Waiting for it to start");
			}
		});

		const execCommandOperationResult = await step.do(
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

				const baseUrl = _env.incus_server_url;
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
				const json = await response.json();
				const incusAsyncResponse = IncusAsyncResponseSchema.parse(json);
				console.log("Exec command response:", incusAsyncResponse);

				return incusAsyncResponse;
			},
		);

		if (execCommandOperationResult.metadata?.status === "Success") {
			console.log("Runner setup command completed successfully");
			return;
		}

		await step.do("wait for runner setup command to complete", async () => {
			const baseUrl = _env.incus_server_url;
			const operationUrl = `${baseUrl}/1.0/operations/${execCommandOperationResult.metadata?.id}`;
			const cloudflareAccessHeaders = {
				"CF-Access-Client-Id": _env.cloudflare_access_client_id,
				"CF-Access-Client-Secret": _env.cloudflare_access_client_secret,
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
				console.error("Runner setup command failed:", result);
				throw new NonRetryableError(
					`Runner setup command failed with status: ${result.metadata?.status}`,
				);
			}
		});
	}
}
