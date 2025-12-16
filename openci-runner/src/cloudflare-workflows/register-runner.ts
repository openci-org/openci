import {
	WorkflowEntrypoint,
	type WorkflowEvent,
	type WorkflowStep,
} from "cloudflare:workers";
import type { WorkflowJobQueuedEvent } from "@octokit/webhooks-types";

type Params = {
	github_payload: WorkflowJobQueuedEvent;
	github_app_id: string;
	github_app_private_key: string;
	cloudflare_access_client_id: string;
	cloudflare_access_client_secret: string;
	incus_server_url: string;
	openci_runner_base_image: string;
	openci_runner_label: string;
};

export class RegisterRunner extends WorkflowEntrypoint<Env, Params> {
	async run(_event: WorkflowEvent<Params>, _step: WorkflowStep) {}
}
