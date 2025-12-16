import {
	WorkflowEntrypoint,
	type WorkflowEvent,
	type WorkflowStep,
} from "cloudflare:workers";
import { NonRetryableError } from "cloudflare:workflows";
import type { WorkflowJobQueuedEvent } from "@octokit/webhooks-types";
import { generateInstanceName } from "../handlers/workflow-job";

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

export class RegisterRunner extends WorkflowEntrypoint<Env, Params> {
	async run(event: WorkflowEvent<Params>, _step: WorkflowStep) {
		console.log("RegisterRunner workflow started");
		const _env = event.payload;
		const _githubPayload = _env.github_workflow_job_queued_event;

		const installationId = _githubPayload.installation?.id;
		if (!installationId) {
			throw new NonRetryableError("GitHub installation_id not found");
		}

		const runId = _githubPayload.workflow_job?.run_id;
		if (!runId) {
			throw new NonRetryableError("GitHub run_id not found");
		}

		const _incusServerUrl = _env.incus_server_url;
		const _baseUrl = `${_incusServerUrl}/1.0`;

		const header = {
			"CF-Access-Client-Id": _env.cloudflare_access_client_id,
			"CF-Access-Client-Secret": _env.cloudflare_access_client_secret,
		};
		const _headerWithContentType = {
			...header,
			"Content-Type": "application/json",
		};

		const _instanceName = generateInstanceName(runId);
	}
}
