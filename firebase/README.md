# Local Firebase Auth Emulator

This standalone Docker Compose setup runs the Auth Emulator and Emulator UI
using project ID `demo-openci`. It requires Docker Compose with `--wait` support;
no Firebase login, real Firebase project, or service account is needed.

The image uses the existing `firebase/firebase.json` configuration and starts
with `--project demo-openci --only auth`.

From the repository root, build and start the emulator:

```sh
docker compose -f docker-compose.local.yml up -d --build --wait
```

Compose waits for the Auth Emulator's health check to pass. The first build
downloads the pinned Firebase CLI and Emulator UI.

- Auth endpoint: <http://127.0.0.1:9099>
- Emulator UI: <http://127.0.0.1:4000/auth>

Both ports bind only to the host's loopback interface. Open the UI to create,
inspect, or delete email/password users. User data is temporary and is lost
when the emulator restarts; this setup does not import or export data.

When a connected client requests email verification or a password reset, the
emulator prints an action link instead of sending real email. Read it in the
logs and open the link locally:

```sh
docker compose -f docker-compose.local.yml logs -f firebase-auth
```

Stop and remove the emulator container:

```sh
docker compose -f docker-compose.local.yml down
```

To lint and type-check `healthcheck.ts`, run from the repository root:

```sh
vp install --frozen-lockfile
vp run --filter firebase-dev check
```

This check also runs as part of `vp run -r check` in CI.

## Connect the local API

Use Docker Compose 2.24.4 or later for the `!reset` and `!override` tags in
`docker-compose.local-api.yml`. Prepare the root `.env` and
`github-private-key.pem` required by `docker-compose.yml`; the API still needs
its database and non-Firebase configuration.

From the repository root, combine the base services, emulator, and local API
override in this order:

```sh
docker compose \
  -f docker-compose.yml \
  -f docker-compose.local.yml \
  -f docker-compose.local-api.yml \
  config --quiet

docker compose \
  -f docker-compose.yml \
  -f docker-compose.local.yml \
  -f docker-compose.local-api.yml \
  up -d --build --wait server
```

This starts the API after PostgreSQL and the Auth Emulator are healthy. It sets
`GCLOUD_PROJECT=demo-openci` and
`FIREBASE_AUTH_EMULATOR_HOST=firebase-auth:9099` on the API container, and removes
both `GOOGLE_APPLICATION_CREDENTIALS` and the Firebase service account mount.
No `firebase-service-account.json` is needed. The Admin SDK uses its existing
emulator support.

| Service       | From the host                | From the API container           |
| ------------- | ---------------------------- | -------------------------------- |
| API           | `http://127.0.0.1:8080`      | `http://server:8080`             |
| Auth Emulator | `http://127.0.0.1:9099`      | `http://firebase-auth:9099`      |
| Emulator UI   | `http://127.0.0.1:4000/auth` | `http://firebase-auth:4000/auth` |

`FIREBASE_AUTH_EMULATOR_HOST` takes `host:port` without `http://`. The local
override leaves `SERVER_ACCESS_MODE`, `ALLOWED_USER_EMAILS`, and non-Firebase
settings unchanged. The base `docker-compose.yml` still uses the configured
Firebase service account when this override is omitted. Use the override only
for local development.

`openci dev start` now uses this same three-file configuration for every Compose
step. It first runs `up -d --build --wait firebase-auth`, so an emulator startup
or readiness failure stops the command before the API starts. The standalone
emulator commands above remain available.

To stop the local API and its dependencies, use the same three `-f` options with
`stop server db firebase-auth`.

## Test server authentication

Start the standalone Auth Emulator with the first Compose command above. Then
run the server integration test from `apps/openci_server`:

```sh
cd apps/openci_server
env -u GOOGLE_APPLICATION_CREDENTIALS \
  -u GOOGLE_CLOUD_PROJECT \
  -u FIREBASE_CONFIG \
  GCLOUD_PROJECT=demo-openci \
  FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 \
  dart test integration_test/auth_emulator_test.dart
```

The test refuses to run unless the project ID and loopback emulator host match
the local setup, and it rejects production Firebase credential/configuration
environment variables. It creates a unique email/password user, checks the
server's real authentication middleware with ID tokens before and after email
verification, then deletes only that user. A separate process checks that the
same unsigned token is rejected when emulator mode is disabled. The regular
`dart test` server suite does not require a running emulator.

## Follow-up work

Dashboard is tracked in [#2867](https://github.com/openci-org/openci/issues/2867).
CLI authentication is tracked in
[#2868](https://github.com/openci-org/openci/issues/2868) and
[#2869](https://github.com/openci-org/openci/issues/2869). Automatic development
user and team membership creation is tracked in
[#2862](https://github.com/openci-org/openci/issues/2862).

See [Firebase's Auth Emulator documentation](https://firebase.google.com/docs/emulator-suite/connect_auth).
