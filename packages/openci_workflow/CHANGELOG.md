# Changelog

## Unreleased

- Return the absolute path of the exported IPA from `FlutterCI.buildIpa()`, rejecting missing or ambiguous exports.
- Add `FlutterCI.deployIpaToFirebaseAppDistribution()` using the REST API with service account OAuth, automatic Firebase App ID detection, streamed uploads, bounded processing polls, and optional release notes and tester distribution. No Node.js or Firebase CLI is required.

## 0.1.2

- Add optional `tz` and `excludeTags` arguments to `FlutterCI.unitTests()`, preserving existing defaults when omitted.
- Add the `TimeZone` enum with `asiaTokyo` and `utc` values for typed time zone selection.

## 0.1.1

- Add `FlutterCI.buildApk()` and `FlutterCI.buildAab()` with optional product flavor and working-directory arguments.
- Add configurable fatal-info, fatal-warning, and analytics flags to `FlutterCI.staticAnalysis()`, suppressing analytics by default.
- Pass flavor names as literal shell arguments and expand Flutter helper test coverage.

## 0.1.0

- Publish the initial OpenCI workflow SDK with push and pull-request triggers, shell commands, Flutter helpers, and workspace file utilities.
- Stream command output to the terminal and optionally to Loki.
- Keep runtime dependencies independent of the OpenCI server packages.
