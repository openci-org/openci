import { createMiddleware } from "hono/factory";

export const validateEnv = () => {
	return createMiddleware<{ Bindings: Env }>(async (c, next) => {
		const { env } = c;

		if (!env.GH_APP_WEBHOOK_SECRET) {
			console.error("GH_APP_WEBHOOK_SECRET not provided");
			return c.text("GH_APP_WEBHOOK_SECRET not provided", 500);
		}
		if (!env.GH_APP_ID) {
			console.error("GH_APP_ID not provided");
			return c.text("GH_APP_ID not provided", 500);
		}
		if (!env.GH_APP_PRIVATE_KEY) {
			console.error("GH_APP_PRIVATE_KEY not provided");
			return c.text("GH_APP_PRIVATE_KEY not provided", 500);
		}
		if (!env.CF_ACCESS_CLIENT_ID) {
			console.error("CF_ACCESS_CLIENT_ID not provided");
			return c.text("CF_ACCESS_CLIENT_ID not provided", 500);
		}
		if (!env.CF_ACCESS_CLIENT_SECRET) {
			console.error("CF_ACCESS_CLIENT_SECRET not provided");
			return c.text("CF_ACCESS_CLIENT_SECRET not provided", 500);
		}
		if (!env.INCUS_SERVER_URL) {
			console.error("INCUS_SERVER_URL not provided");
			return c.text("INCUS_SERVER_URL not provided", 500);
		}

		await next();
	});
};
