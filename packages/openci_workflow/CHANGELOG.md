# Changelog

## 0.8.1

- Add `flutter.buildWeb()` for release builds, with an optional `noPub` flag to skip dependency resolution.

## 0.8.0

- **Breaking:** Replace `MachineType.linuxLatest` with `MachineType.linuxSmall` (1 vCPU, 2 GiB) or `MachineType.linuxMedium` (2 vCPUs, 4 GiB). Update exhaustive switches to handle both presets.

## 0.7.0

- **Removed `shorebird.releaseApk()`.** Use `shorebird.releaseAndroid()` to get the absolute `apkPath` and `aabPath` from one Shorebird release. For APK-only distribution, read the returned record's `apkPath` field.

## 0.6.4

- Look up TestFlight encryption declarations by filtering the declaration collection by app ID. This fixes an App Store Connect `404 PATH_ERROR` during export compliance.
- Include Apple's error code, title, and detail in TestFlight API failures so the CI log explains which request failed and why.

## 0.6.3

- Add `TestFlightExportCompliance.standardEncryption` to `flutter.deployIpaToTestFlight()` to declare standard encryption and explicitly answer whether the app will be distributed in France.
- Add `flutter.applyTestFlightExportCompliance()` to apply the same answers to an existing build after Apple reviews its documentation.

## 0.6.2

- Show the configured `groups` aliases in the error when Firebase App Distribution rejects a release with `INVALID_ARGUMENT`.

## 0.6.1

- Add optional `groups` (Firebase group aliases) and `testers` (email addresses) to `flutter.deployApkToFirebaseAppDistribution()` and `flutter.deployAabToFirebaseAppDistribution()`. Omit both to upload only.

## 0.6.0

- Select an Orchard Vetu Linux worker in an enabled pilot repository with `machine: MachineType.linuxLatest`. Workflows default to `MachineType.macOsLatest`.
- `MachineType` gains a second enum value. Add a `linuxLatest` case to exhaustive switches when upgrading.

## 0.5.3

- Add `firebase.functions.deploy()` using the installed Firebase CLI, with explicit project selection, optional codebase selection, and temporary service account authentication.

## 0.5.2

- Add `patrol.testWithVirtualBle()` to build a Patrol target once and run it on two iOS Simulators.
- Support test paths in `dart.test()`, locked dependency resolution with `flutter.pubGet()` and `noPub` in `flutter.staticAnalysis()`.
- Add `startVirtualBle()` to exchange GATT values between two simulator apps using a loopback WebSocket server and two Bumble devices.

## 0.5.1

- Export `FlutterVersion` with `v3_44_8` and `v3_47_8`. Each member exposes its release string through `.value`.

## 0.5.0

- Add `CITrigger.release(tag: 'v*')` for GitHub Release publication. Omitting `tag` accepts every published release, including pre-releases. Requires the updated webhook planner and a GitHub App subscribed to Release events.
- **Breaking:** `CITrigger` has a third union case. Update exhaustive pattern matches; `branch` and `paths` are null for release triggers. Use `copyWith` on a specific union case instead of the base `CITrigger` type.

## 0.4.8

- Add an optional `env` list to `patrol.test()` for passing `Secret` values to tests as Dart defines. Tests can read each value by its original key with `String.fromEnvironment`.

## 0.4.6

- Add `dart.runBuildRunner()` to generate code once in the workflow directory or a package selected by `dir`.

## 0.4.4

- Add `patrol.test()` using the project's resolved Patrol CLI, with explicit device selection, test targets, directory override and additional CLI arguments. Stream command output and throw on failure so callers can dispose simulators in `finally`.

## 0.4.3

- Add `launchIosSimulator()` to create a fresh simulator and wait for startup, with configurable device, runtime, and boot timeout. Return its UDID and a `dispose()` method to shut down and delete it; clean up after boot failures.

## 0.4.2

- Add `dart.test()` with an optional working directory.

## 0.4.1

- Add `dart.analyze()` with an optional working directory and configurable fatal info and warning diagnostics.
- Add `dart.publishToPubDev()` with Google service account authentication, temporary pub credentials, and an optional skip for versions already published. Return the package name, version, URL, and publication status. Use pub's normal validation with `--force`, without an extra dry run.

## 0.4.0

- **Breaking:** `firebaseHosting.deployPreview()` now returns `FirebaseHostingPreview` with `url` and the actual Firebase `expiresAt` in UTC. Replace uses of the previous `Uri` result with `preview.url`; live `deploy()` still returns `Uri`.
- Add optional `DateTime expiresAt` to `pullRequest.postQrCode()` to display an explicit expiration time in English or Japanese PR comments. Pass `preview.expiresAt` to reuse the Hosting expiry. Omitting it leaves out the expiry line; display requires the updated executor.

## 0.3.1

- Read static Hosting settings from `firebaseConfigPath` in `deploy()` and `deployPreview()`, including public paths, ignore patterns, routing and response headers. Select multi-site configurations by site ID or deploy target, with optional public-directory overrides.

## 0.3.0

- Add `openCI.context` with typed push, pull request and local execution metadata. CI context includes repository/run identity and the exact checkout SHA; PR head and verified base SHAs remain distinct.
- **Breaking:** Remove `GoCI` and `OpenCI.go`, including the Go format, vet,
  and test helpers.
- Add `openCI.firebaseHosting.deploy()` and `deployPreview()` with in-memory service account authentication and direct Hosting REST uploads. Both return a serving URL for use with PR QR comments.
- Reuse preview channel IDs with a one-hour default expiry and one retained previous release. Bound previews to 20 per site by default, cleaning expired and then least recently updated OpenCI-managed previews without deleting live or unrelated channels.

## 0.2.9

- Document `openci/pr-qr` as the branch for new pull request QR images and how
  to keep images in older comments available.

## 0.2.8

- Update CLI installation and secret-sync examples to use `openci_cli_plus` and
  the `openci` command. Document the QR image branch transition for existing PRs.

## 0.2.7

- Show the workflow name in PR QR comments, with the app version and build number when available. Keep CI run numbers internal so GitHub does not link them to unrelated PRs.
- Automatically retain Firebase App Distribution's uploaded app version and build number for iOS and Android tester URLs. Existing upload and `postQrCode` calls continue to work; other URLs can pass the optional `version` and `buildNumber` arguments.

## 0.2.6

- Add `PostQrCodeSize` (`small`, `medium`, `large`, and `PostQrCodeSize.custom(width: ..., height: ...)`) and the optional `size` argument to `openCI.pullRequest.postQrCode(...)`, defaulting to `PostQrCodeSize.medium`.

## 0.2.5

- Return the tester URL from `deployApkToFirebaseAppDistribution`.

## 0.2.4

- Add `openCI.pullRequest.postQrCode(url: ..., lang: ...)` for posting a web URL and a QR code on the originating PR. Each workflow updates its comment on subsequent successful runs. Comments support English and Japanese.
- Return the tester URL from `deployIpaToFirebaseAppDistribution`.

## 0.2.3

- Add opt-in `OpenCI.init(cancelPreviousRuns: true)` for PR workflows. A new
  commit's scheduled run cancels older opted-in queued/running jobs for the same
  repository, PR and workflow file. Push runs and same-commit reruns are retained.

## 0.2.2

- Add `OpenCI.dart.checkFormat()` to check tracked and non-ignored new Dart
  files without rewriting them, with an optional working directory.

## 0.2.1

- Add optional `OpenCI.init(flutterVersion: '3.47.8')` metadata. CI selects the
  declared release through FVM before resolving dependencies. Omitted or null
  values use the image's default Flutter SDK; local runs keep their current SDK.

## 0.2.0

- **Breaking:** Rename `CITrigger.whenChanged` to `CITrigger.paths` for push and
  pull-request triggers. Replace `whenChanged:` arguments and `.whenChanged`
  property access with `paths:` and `.paths`.
- Document changed-path filtering, skipped GitHub Checks, and migration to
  `paths`. Triggers without a path condition continue to run on matching events
  and branches.
- Remove direct Loki log forwarding through `LOKI_URL`. Commands continue to
  stream stdout and stderr; the OpenCI executor captures and persists these logs
  in Firebase SQL Connect.

## 0.1.6

- Add `OpenCI.runNumber` to read the server-assigned team sequence from
  `OPENCI_RUN_NUMBER`, with validation and guidance for local workflows.

## 0.1.5

- Add `Secret` references with the original environment name in `.key` and lazy
  runtime access through `.value`, for secret definitions generated by the OpenCI CLI.

## 0.1.4

- Add `OpenCI.go.format()`, `OpenCI.go.vet()`, and `OpenCI.go.test()` to format Go files and run checks with an optional working directory, using the preinstalled Go toolchain.
- Expose the `OpenCI` constructor with an injectable command runner, replacing `OpenCI.forTesting()`.
- Add value equality and `copyWith()` to signing credential models while keeping credential values out of `toString()`.

## 0.1.3

- Add `OpenCI.shorebird.releaseApk()` to build a universal Android APK with Shorebird and return its absolute path, with flavors, Dart defines, Flutter arguments, and dry runs.
- Add `OpenCI.shorebird.releaseAab()` to build Android App Bundles with Shorebird and return the selected variant's absolute AAB path, with flavors, Dart defines, Flutter arguments, and dry runs.
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
