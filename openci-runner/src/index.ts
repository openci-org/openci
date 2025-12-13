import * as Sentry from "@sentry/cloudflare";
import { Hono } from "hono";
import { sentryConfig } from "./config/sentry";
import { validateEnv } from "./middleware/validate-env";
import { webhook } from "./routes/webhook";

const app = new Hono<{ Bindings: Env }>();

app.use("*", validateEnv());
app.route("/webhook", webhook);

export { RegisterRunner } from "./workflows/register-runner";

export default Sentry.withSentry(sentryConfig, app);
