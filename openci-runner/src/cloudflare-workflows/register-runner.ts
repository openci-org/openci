import {
	WorkflowEntrypoint,
	type WorkflowEvent,
	type WorkflowStep,
} from "cloudflare:workers";

export class RegisterRunner extends WorkflowEntrypoint<Env, Params> {
	async run(_event: WorkflowEvent<Params>, _step: WorkflowStep) {
		return true;
	}
}
