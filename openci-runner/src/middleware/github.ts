import { verify } from "@octokit/webhooks-methods";
import { createMiddleware } from "hono/factory";

export const verifySignature = () => {
	return createMiddleware<{ Bindings: Env }>(async (c, next) => {
		const signature = c.req.header("x-hub-signature-256");
		if (!signature) {
			return c.text("Signature is null", 401);
		}

		const body = await c.req.text();
		const isValid = await verify(c.env.GH_APP_WEBHOOK_SECRET, body, signature);
		if (!isValid) {
			return c.text("Unauthorized", 401);
		}

		await next();
	});
};
