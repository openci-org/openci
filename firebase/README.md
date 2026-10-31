# Local Firebase Auth Emulator

For the separate Firebase SQL Connect configuration, see
[Data Connect](dataconnect/README.md).

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

## FSC development

The legacy API, PostgreSQL and Orchard Docker Compose stack and `genuineci dev
start` have been retired. The standalone Auth Emulator above remains available.
It starts authentication only; it does not start Functions or Data Connect.

- [Data Connect setup and emulator tests](dataconnect/README.md)
- [Functions development](functions/README.md)
- [Functions and Cloud Run deployment](functions/DEPLOYMENT.md)
- [Orchard Controller setup](../infra/orchard/README.md)

Dashboard and CLI APIs now use Firebase Functions and Data Connect. To exercise
these features locally, run their emulators in the same `demo-openci` project as
Auth. The Dashboard's **Local Auth Emulator** launch selects this project and
uses the Functions emulator on port 5001; it does not start any emulators or seed
teams. Create local Auth users in the Emulator UI. Local Auth users alone do not
provide team membership or build execution capacity.
