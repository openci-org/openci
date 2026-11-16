# Firebase Auth signup notifications

`notifyAuthUserCreated` sends a Slack notification after Firebase Auth creates a
user. It includes the name and email when present, provider IDs, creation time
(UTC), and Firebase UID. Values use bounded plain-text fields so names cannot
create Slack mentions or links. No profile, email, webhook URL, or Slack response
body is written to application logs.

The first-generation `auth.user().onCreate` trigger runs in `asia-northeast1`
using `OPENCI_API_SERVICE_ACCOUNT`. This uses the established Auth trigger while
[second-generation Auth events](https://firebase.google.com/docs/functions/auth-events)
are in preview. It runs after account creation and cannot block registration.
Regular sign-ins and profile updates do not send notifications. Firebase also
emits creation events for Admin SDK-created and anonymous accounts; these are
included. Firebase does not emit this event for first sign-in with a custom token.
See [Firebase's trigger documentation](https://firebase.google.com/docs/functions/1st-gen/auth-events).

## Setup and deployment

1. Create a [Slack incoming webhook](https://docs.slack.dev/messaging/sending-messages-using-incoming-webhooks/)
   for the intended workspace and channel. The webhook determines the channel.
2. Store its URL in the `SLACK_SIGNUP_WEBHOOK_URL` Firebase secret for
   `openci-b1b91`. Enter it at the prompt; do not put it in a command, source file,
   or PR description. The runtime identity needs Secret Accessor on this secret.
3. From `firebase/`, deploy only the new function:

   ```sh
   firebase functions:secrets:set SLACK_SIGNUP_WEBHOOK_URL --project openci-b1b91
   firebase deploy --only functions:openci:notifyAuthUserCreated --project openci-b1b91
   ```

Production builds use
`openci-build@openci-b1b91.iam.gserviceaccount.com`. This is configured as
`buildServiceAccount` on the deployed first-generation function; Firebase's
runtime options do not expose this setting. The build identity has conditional
Storage Object Viewer access limited to this function's source prefix in
`gcf-sources-372767414789-asia-northeast1`. If the function is recreated, configure
the build identity and its new source prefix before retrying the build. Routine
Firebase CLI updates preserve the deployed build identity.

Use a separate webhook secret in other projects to keep their notifications
separate. For a local Auth/Functions emulator smoke test, set the secret in the
ignored `firebase/.secret.local` file and use a test Slack channel. Only create a
test account and send a test notification when that live test is intended.

For a production delivery smoke test without creating an Auth account, invoke
the deployed function through the Cloud Functions v1 `functions.call` testing
API with synthetic user data clearly labeled as a test. Confirm the single test
message in the intended Slack channel and the `Signup notification delivered`
log entry. This checks delivery through the deployed handler and secret, but
does not exercise a real Auth creation event.

## Delivery behavior

Each HTTP attempt has a 10-second timeout and does not follow redirects.
Only a successful HTTP response with Slack's `ok` acknowledgement counts as
delivery. Failed attempts throw a sanitized error and Firebase retries them;
events older than 24 hours are logged as expired and acknowledged without sending.
Correct missing/revoked webhook configuration within that window to allow retry.

Delivery is at least once. A lost response after Slack accepted a message, or
Firebase redelivery, can produce a duplicate notification. There is no durable
deduplication store or backfill of users created before deployment. The Firebase
UID identifies the account when investigating duplicate messages.
