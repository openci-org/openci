---
title: Self-hosting
description: Own your build environment. Learn how GenuineCI uses Firebase, GCP and Apple Silicon Macs.
---

## Run in your own environment

GenuineCI is open-source CI. Its control plane uses Firebase and GCP; Apple Silicon Macs provide build capacity through Orchard.

The source code and configuration files are available in the [GitHub repository](https://github.com/openci-org/openci).

## Main components

| Component                          | Role                                             |
| ---------------------------------- | ------------------------------------------------ |
| Dashboard and Firebase Auth        | Sign in and manage teams and builds              |
| Firebase SQL Connect               | Store teams, jobs, logs and billing state        |
| Firebase Functions                 | Receive webhooks, plan jobs and dispatch builds  |
| Cloud Run executor                 | Run workflows through Orchard and record results |
| Orchard Controller and Mac workers | Allocate and run macOS VMs                       |
| GitHub App                         | Connect repositories and receive events          |

You do not need to deploy these components to run Dart workflows locally. Start with the [Quickstart](/en/docs/quickstart/).

## Development and deployment

The former API servers, PostgreSQL Compose stack and `genuineci dev start` command have been retired. The repository still provides a standalone Firebase Auth Emulator. Functions, Data Connect and build execution require their own setup.

- [Firebase development and emulator setup](https://github.com/openci-org/openci/blob/develop/firebase/README.md)
- [Functions and Cloud Run deployment](https://github.com/openci-org/openci/blob/develop/firebase/functions/DEPLOYMENT.md)
- [Orchard Controller deployment](https://github.com/openci-org/openci/blob/develop/infra/orchard/README.md)

For your deployment, configure project-specific identities, GitHub and Stripe settings, network access, secrets and Mac workers. The deployment record describes OpenCI's production project; use your own resource identifiers.
