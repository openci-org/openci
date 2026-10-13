# Changelog

## Unreleased

- Add `OpenCI.shorebird.releaseIos()` to prepare iOS signing for an explicit bundle ID, build with Shorebird's selected Flutter version, and return the exported IPA path. Support flavors, Dart defines, Flutter arguments, and dry runs.
- Add `FlutterCI.deployAabToPlayConsole()` with service account authentication, streamed AAB uploads, and Google Play edit commits. Default to internal testing, with configurable tracks and optional draft releases.
- Add `FlutterCI.deployIpaToTestFlight()` with App Store Connect API authentication, streamed IPA uploads, and polling until Apple finishes processing the build.
- Add `FlutterCI.deployAabToFirebaseAppDistribution()` with Google Play integration checks, service account authentication, streamed AAB upload, and processing completion checks.
- Add `FlutterCI.deployApkToFirebaseAppDistribution()` with an explicit Android Firebase App ID, service account authentication, streamed upload, and processing completion checks.
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
