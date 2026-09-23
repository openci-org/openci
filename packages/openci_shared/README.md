# openci_shared

Shared constants and models for OpenCI.

## Workflow files

`OpenCIApiService.fetchOpenCIFiles` requests
`GET /teams/{teamId}/repositories/{repo}/openci-files`. Pass the commit or
branch as `ref`, plus the repository `owner` and GitHub App `installationId`.
The response contains Dart workflow files from `openci/` as JSON objects with
`name`, `path`, and `content`. Requests require team membership or a valid
internal API key.
