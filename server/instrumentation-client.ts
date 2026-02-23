import * as Sentry from "@sentry/nextjs";
import { initSentryClient } from "./src/lib/sentry/client";
import { createClient } from "./src/lib/supabase/client";

initSentryClient();

// Populate Sentry feedback widget with logged-in user info
createClient()
  .auth.getSession()
  .then(({ data }) => {
    const user = data.session?.user;
    if (user) {
      Sentry.setUser({
        email: user.email,
        username: user.user_metadata?.full_name ?? user.email,
      });
    }
  });

export const onRouterTransitionStart = Sentry.captureRouterTransitionStart;
