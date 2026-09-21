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

Application connections are separate follow-ups: API and `genuineci dev start`
in [#2866](https://github.com/openci-org/openci/issues/2866), Dashboard in
[#2867](https://github.com/openci-org/openci/issues/2867), and CLI authentication
in [#2868](https://github.com/openci-org/openci/issues/2868) and
[#2869](https://github.com/openci-org/openci/issues/2869). Automatic development
user and team membership creation is tracked in
[#2862](https://github.com/openci-org/openci/issues/2862).

See [Firebase's Auth Emulator documentation](https://firebase.google.com/docs/emulator-suite/connect_auth).
