# OpenCI Worker CLI (Node.js)

Node.js implementation of the OpenCI worker. It claims queued build jobs from SQL Connect, creates build runs, streams logs back to SQL Connect, runs the workflow with `act`, and runs build-job follow-up work directly through the shared Data Connect Admin SDK services.

## Usage

Install from npm:

```sh
npm install -g openci-worker-cli
openci_worker --service-account /path/to/service-account.json --worker-id worker-1
```

Run from source:

```sh
npm install
npm run build
node dist/index.js --service-account /path/to/service-account.json --worker-id worker-1
```

For a single-job smoke test:

```sh
node dist/index.js --service-account /path/to/service-account.json --worker-id worker-1 --once
```

The worker claims `ubuntu` jobs on Linux and runs them inside `openci-ubuntu:latest`. On macOS it claims `macos` jobs and runs them inside a cloned Lume VM.

## Publishing

The worker bundles the generated Data Connect Admin SDK and shared build-job services so it can be installed from npm without repository-local `file:` dependencies.

Before publishing from this package directory:

```sh
npm install --install-links
npm run pack:dry-run
npm publish
```

The dry run should list `@openci/dataconnect-admin` and `@openci/build-job-services` as bundled dependencies.

## Requirements

- Node.js 22
- A Firebase service account JSON with Data Connect, Secret Manager, and FCM permissions
- `act` available in the worker runtime
- Linux workers: Docker and the `openci-ubuntu:latest` image
- macOS workers: Lume and the `tahoe-base_v1.1.1` base VM

