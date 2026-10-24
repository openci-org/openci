---
title: Self-hosting
description: Own your build environment. Learn how GenuineCI uses Apple Silicon Macs to run workflows.
---

## Run in your own environment

GenuineCI is open-source CI. You can set up your own environment with Apple Silicon Macs as build machines.

The source code and configuration files are available in the [GitHub repository](https://github.com/openci-org/openci).

## Main components

| Component     | Role                                          |
| ------------- | --------------------------------------------- |
| Dashboard     | Manage teams, repositories, and build results |
| API / planner | Plan workflows from GitHub events             |
| Worker        | Execute build jobs on Macs                    |
| GitHub App    | Connect repositories and receive events       |

You do not need to start these components just to run Dart workflows locally. Try the [Quickstart](/en/docs/quickstart/).

## Local development environment

The repository includes a command that starts the API, Firebase Auth Emulator, Orchard Controller, and Mac workers for development.

```sh
genuineci dev start
```

Run this command inside a checkout of the GenuineCI source code. Prepare Docker Compose 2.24.4 or later, the Compose configuration and credentials, and a `base-macos` VM beforehand.

> `dev start` is for local development. It does not automatically complete production deployment or authentication setup.

## Detailed setup

See the current [CLI README](https://github.com/openci-org/openci/tree/develop/apps/openci_cli) for prerequisites and development startup instructions.

For production, configure the GitHub App, authentication, networking, secrets, and build machine management for your environment. Questions and suggestions are welcome on [GitHub Issues](https://github.com/openci-org/openci/issues).
