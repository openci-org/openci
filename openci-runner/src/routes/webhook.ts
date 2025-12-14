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
				cloudflare_access_client_id: c.env.CF_ACCESS_CLIENT_ID,
				cloudflare_access_client_secret: c.env.CF_ACCESS_CLIENT_SECRET,
				github_app_id: c.env.GH_APP_ID,
				github_app_private_key: c.env.GH_APP_PRIVATE_KEY,
				githubPayload: payload,
				incus_server_url: c.env.INCUS_SERVER_URL,
				openci_runner_base_image: c.env.OPENCI_RUNNER_BASE_IMAGE,
				openci_runner_label: c.env.OPENCI_RUNNER_LABEL,
			},
		});
		return c.text("Workflow Job registration initiated", 202);
	}

	// cancel, completedで対応

	// if (payload.action === "completed") {
	// 	return handleWorkflowJobCompleted(c, payload);
	// }

	return c.text("Workflow Job action not supported", 200);
});

export { webhook };
