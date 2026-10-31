# openci_shared

Shared Dart models and utilities for the Dashboard, CLI, workflow SDK and Dart
planner. Team, build and GitHub connection DTOs remain available.

## FSC API access

The legacy `OpenCIApiService` REST client, its Chopper converter and token
interceptor have been removed with the retired servers. Use the generated
Data Connect SDKs for authorized queries and Firebase callable Functions for
team, Secrets, GitHub connection and billing operations. Functions verify
Firebase identity and team access before using Admin SDK operations.

See [Functions](../../firebase/functions/README.md) and
[Data Connect](../../firebase/dataconnect/README.md) for operation definitions.

`BuildJobPlan.fromJson` continues to accept older planner payloads by ignoring
the legacy `githubBaseUrl` field. Repository access and workflow retrieval are
owned by the Dart planner and its verified GitHub connection.
