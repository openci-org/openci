import * as Sentry from "@sentry/nextjs";
import { initSentryClient } from "./src/lib/sentry/client";

initSentryClient();

export const onRouterTransitionStart = Sentry.captureRouterTransitionStart;
