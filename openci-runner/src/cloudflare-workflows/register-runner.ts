import {
	WorkflowEntrypoint,
	type WorkflowEvent,
	type WorkflowStep,
} from "cloudflare:workers";
import { NonRetryableError } from "cloudflare:workflows";
import type { WorkflowJobQueuedEvent } from "@octokit/webhooks-types";
import { generateInstanceName } from "../handlers/workflow-job";
import type { IncusEnv } from "../types/incus.types";

type Params = {
	github_workflow_job_queued_event: WorkflowJobQueuedEvent;
	github_app_id: string;
	github_app_private_key: string;
	cloudflare_access_client_id: string;
	cloudflare_access_client_secret: string;
	incus_server_url: string;
	openci_runner_base_image: string;
	openci_runner_label: string;
};

function requireValue<T>(value: T | undefined | null, name: string): T {
	if (value == null) {
		throw new NonRetryableError(`${name} not found`);
	}
	return value;
}

export class RegisterRunner extends WorkflowEntrypoint<Env, Params> {
	async run(event: WorkflowEvent<Params>, _step: WorkflowStep) {
		console.log("RegisterRunner workflow started");
		const _env = event.payload;
		const _githubPayload = _env.github_workflow_job_queued_event;

		const _installationId = requireValue(
			_githubPayload.installation?.id,
			"Installation ID",
		);
		const runId = requireValue(_githubPayload.workflow_job?.run_id, "Run ID");

		const _incusEnv: IncusEnv = {
			cloudflare_access_client_id: _env.cloudflare_access_client_id,
			cloudflare_access_client_secret: _env.cloudflare_access_client_secret,
			server_url: _env.incus_server_url,
		};

		const _instanceName = generateInstanceName(runId);
	}
}
