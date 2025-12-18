import * as Sentry from "@sentry/cloudflare";

export const sentryConfig = (env: Env): Sentry.CloudflareOptions => ({
	dsn: env.SENTRY_DSN,
	enableLogs: true,
	environment: env.ENVIRONMENT,
	integrations: [
		Sentry.consoleLoggingIntegration({ levels: ["log", "warn", "error"] }),
	],
	tracesSampleRate: 1.0,
});
