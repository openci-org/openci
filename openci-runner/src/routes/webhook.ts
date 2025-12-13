import type { WebhookEvent } from "@octokit/webhooks-types";
import { Hono } from "hono";
import { verifySignature } from "../middleware/github";

const webhook = new Hono<{ Bindings: Env }>();

webhook.use("*", verifySignature());

webhook.post("/", async (c) => {
	const payload = (await c.req.json()) as WebhookEvent;

	if (!("workflow_job" in payload)) {
		return c.text("Event ignored", 200);
	}

	const labels: string[] = payload.workflow_job.labels ?? [];
	if (!labels.includes(c.env.OPENCI_RUNNER_LABEL)) {
		return c.text("Workflow Job does not target OpenCI runner", 200);
	}

	if (payload.action === "queued") {
		await c.env.REGISTER_RUNNER.create({
			params: {
				c: c,
				githubPayload: payload,
			},
		});
		return c.text("Workflow Job registration initiated", 202);
	}

	// if (payload.action === "completed") {
	// 	return handleWorkflowJobCompleted(c, payload);
	// }

	return c.text("Workflow Job action not supported", 200);
});

export { webhook };
