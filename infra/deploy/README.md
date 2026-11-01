# Independent self-hosted deployments

These helpers prepare an independent Firebase deployment using the shared
application code. Environment-specific Terraform, Firebase/GitHub identifiers,
certificates and rollout records belong in the ignored `infra/environments/`
directory. Keep a private backup or private repository for those files.
Terraform does not require them to be pushed to the application's Git remote;
its configured remote state backend is independent of Git.

## Local configuration

Create `infra/environments/PROJECT_ID/deployment.json` using the project's
Firebase web app configuration. For example, replace the placeholders below:

```json
{
  "projectId": "openci-self-hosted-example",
  "selfHosted": true,
  "firebase": {
    "apiKey": "PUBLIC_FIREBASE_WEB_API_KEY",
    "appId": "FIREBASE_WEB_APP_ID",
    "messagingSenderId": "PROJECT_NUMBER",
    "projectId": "openci-self-hosted-example",
    "authDomain": "openci-self-hosted-example.firebaseapp.com",
    "storageBucket": "openci-self-hosted-example.firebasestorage.app"
  }
}
```

From the repository root, run:

```sh
node infra/deploy/prepare.mjs PROJECT_ID
```

This generates ignored Firebase CLI configuration, schema/connector deployment
copies, Dashboard build defines and web-only Firebase options. Service and
database names use `PROJECT_ID-service` and `PROJECT_ID-database`; the Cloud SQL
instance is `PROJECT_ID-instance`, in `asia-northeast1`.

Set `OPENCI_DATA_CONNECT_SERVICE_ID=PROJECT_ID-service` for Node Functions, the
Dart planner and the executor. For self-hosting, also set `OPENCI_SELF_HOSTED=true`
and `BILLING_ENABLED=false` for Node Functions and the executor. Supply runtime
credentials through the target project's Secret Manager.

Build the Dashboard from `apps/dashboard` with
`flutter build web --release --dart-define-from-file=../../firebase/.deploy/PROJECT_ID/dashboard-defines.json`,
then copy `build/web/` to `firebase/public/`. Use the generated
`firebase/firebase.PROJECT_ID.local.json` with Firebase CLI and always specify
`--project PROJECT_ID`. Review SQL changes before applying migrations.

## Initial bootstrap

After `npm run build --workspace firebase`, `prepare-core.mjs PROJECT_ID` can
prepare the initial self-hosted Functions package before GitHub/Orchard
credentials are available. It reads the ignored `firebase/.env.PROJECT_ID` and
requires `OPENCI_SELF_HOSTED=true`.

Use this bootstrap only before deploying the full Functions codebase. Deploying
it afterward would omit the other Functions. Full operation also requires the
dedicated Dart planner, executor Job, Orchard Controller/workers, Cloud Tasks
and invocation IAM bindings. Keep infrastructure provisioning and rollout
verification with the private environment configuration.
