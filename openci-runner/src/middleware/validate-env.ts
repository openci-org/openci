import { createMiddleware } from "hono/factory";

export const validateEnv = () => {
	return createMiddleware<{ Bindings: Env }>(async (c, next) => {
		const { env } = c;

		if (!env.GH_APP_WEBHOOK_SECRET) {
			return c.text("GH_APP_WEBHOOK_SECRET not provided", 500);
		}
		if (!env.GH_APP_ID) {
			return c.text("GH_APP_ID not provided", 500);
		}
		if (!env.GH_APP_PRIVATE_KEY) {
			return c.text("GH_APP_PRIVATE_KEY not provided", 500);
		}
		if (!env.CF_ACCESS_CLIENT_ID) {
			return c.text("CF_ACCESS_CLIENT_ID not provided", 500);
		}
		if (!env.CF_ACCESS_CLIENT_SECRET) {
			return c.text("CF_ACCESS_CLIENT_SECRET not provided", 500);
		}
		if (!env.INCUS_SERVER_URL) {
			return c.text("INCUS_SERVER_URL not provided", 500);
		}

		await next();
	});
};
