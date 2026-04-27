# OpenCI Worker CLI (Node.js)

Node.js implementation of the OpenCI worker. It claims queued build jobs from SQL Connect, creates build runs, streams logs back to SQL Connect, runs the workflow with `act`, and runs build-job follow-up work directly through the shared Data Connect Admin SDK services.

## Usage

Install from npm:

```sh
npm install -g openci-worker-cli
openci_worker --service-account /path/to/service-account.json --worker-id worker-1
```

By default, the worker derives the SQL Connect service ID from the Firebase
service account `project_id` for self-hosted `openci-dmis-*` projects. You can
override it explicitly when needed:

```sh
openci_worker \
  --service-account /path/to/service-account.json \
  --worker-id worker-1 \
  --dataconnect-service-id openci-dmis-a6d69-service \
  --dataconnect-location asia-northeast1
```

The same override is also available via environment variables:

```sh
OPENCI_DATACONNECT_SERVICE_ID=openci-dmis-a6d69-service \
OPENCI_DATACONNECT_LOCATION=asia-northeast1 \
openci_worker --service-account /path/to/service-account.json --worker-id worker-1
```

Run from source:

```sh
npm install
npm run build
node dist/index.cjs --service-account /path/to/service-account.json --worker-id worker-1
```

For a single-job smoke test:

```sh
node dist/index.cjs --service-account /path/to/service-account.json --worker-id worker-1 --once
```

The worker claims `ubuntu` jobs on Linux and runs them inside `openci-ubuntu:latest`. On macOS it claims `macos` jobs and runs them inside a cloned Lume VM.

## Publishing

The worker build bundles the generated Data Connect Admin SDK and shared build-job services into `dist/index.cjs` so it can be installed from npm without repository-local `file:` dependencies.

Before publishing from this package directory:

```sh
npm run pack:dry-run
npm publish
```

The dry run should only include `dist`, `README.md`, and `package.json`; it should not list `../../packages/...` paths or bundled dependencies.

## Requirements

- Node.js 22
- A Firebase service account JSON with Data Connect, Secret Manager, and FCM permissions
- `act` available in the worker runtime
- Linux workers: Docker and the `openci-ubuntu:latest` image
- macOS workers: Lume and the `tahoe-base_v1.1.1` base VM
