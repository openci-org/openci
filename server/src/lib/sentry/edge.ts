// Sentry initialization for the Edge runtime.
// https://docs.sentry.io/platforms/javascript/guides/nextjs/

import * as Sentry from "@sentry/nextjs";

export function initSentryEdge() {
  Sentry.init({
    dsn: process.env.SENTRY_DSN,
    tracesSampleRate: 1,
    enableLogs: true,
    sendDefaultPii: true,
  });
}
