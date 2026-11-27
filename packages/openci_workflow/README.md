# OpenCI Workflow

Write OpenCI workflows in Dart. Define branch triggers, run shell commands, and stream command output to OpenCI's build logs.

## Install

Add the SDK to your repository's root package:

```sh
dart pub add --dev openci_workflow
```

For a Flutter repository, use `flutter pub add --dev openci_workflow`.

Install the OpenCI CLI to run `openci sync` from your repository root.

```sh
dart install openci_cli_plus
```

## Secrets

Run `openci sync --secrets` to generate `openci/generated/secrets.g.dart`.
Each generated member is a `Secret` reference:

```dart
import 'generated/secrets.g.dart';

final secret = Secrets.apiToken;
final key = secret.key; // API_TOKEN
final token = secret.value; // Read the environment variable as a String.
```

The reference and its `.key` can be used without reading the environment.
`.value` throws a `StateError` when the variable is missing and preserves empty
strings. After regenerating older String getters, add `.value` wherever your
workflow needs the secret's value, including string interpolation. The updated
server parser supports both generated formats.

## Run numbers

Read the number assigned to the current run synchronously. This getter is built
into the SDK and is available without running `openci sync`:

```dart
final runNumber = openCI.runNumber;
await openCI.run('flutter build ipa --build-number=$runNumber');
```

The getter reads `OPENCI_RUN_NUMBER` as a positive decimal integer. It makes no
network request and does not allocate or increment a number. Repeated reads in
the same run return the same value. Missing or invalid values throw `StateError`.
Workflows that do not read the getter can still run without this variable.

All workflows in a team share one sequence; each team has its own sequence.
A rerun with a new run ID receives a new number while the original run keeps its
number. A build that fails after run creation still consumes its number, so
published builds can have gaps. Rolled-back run creation does not consume a number.
Historical runs retain a null `runNumber` in the server API and are not backfilled.

For local testing, set the variable explicitly before running your workflow:

```sh
OPENCI_RUN_NUMBER=42 dart run openci/release.dart
```

This local value does not reserve a number or update the team's counter.

Roll out the database migration and server allocation API first, then the worker
that exports `OPENCI_RUN_NUMBER`, and finally workflows using the SDK with this
getter. Older workers do not supply the variable.

## Define a workflow

Create `openci/static_analysis.dart` in the repository root:

```dart
import 'package:openci_workflow/openci_workflow.dart';

Future<void> main() async {
  final openCI = await OpenCI.init(
    workflowName: 'Static Analysis',
    ciTriggers: [
      CITrigger.push(branch: 'main'),
      CITrigger.pullRequest(branch: 'main'),
    ],
  );

  await openCI.run('dart analyze --fatal-infos');
}
```

OpenCI discovers workflows in `openci/` and its subdirectories. For example,
`openci/dashboard/ios/build.dart` and `openci/sdk/build.dart` are distinct
workflows. The worker runs each file by its full path from the checkout root.
Use letters, digits, underscores or hyphens for workflow directory names.
The top-level `openci/generated/`, `openci/lib/`, `openci/test/` and
`openci/tool/` directories hold support code. Relative Dart imports resolve
from the workflow file, so a workflow in `dashboard/ios/` imports generated
paths with `../../generated/paths.g.dart`.

Keep workflow names and trigger branches as string literals so the planner can
match them to GitHub events.

Use `CITrigger.release()` to run on GitHub Release publication, or
`CITrigger.release(tag: 'v*')` to filter tag names. Published pre-releases are
included; draft saves, edits, and tag pushes do not match. The workflow must be
present at the tagged commit. OpenCI resolves lightweight and annotated tags to
a commit before reading workflows and queues that exact commit for checkout.
Release runs currently expose the pinned tag as `PushContext.branch`
(`refs/tags/<tag>`). Path filters apply to push and pull request triggers.
Release triggers require SDK 0.5.0, the updated webhook and planner, and a
GitHub App subscribed to Release events with Contents read permission.

### Choose a worker

Workflows use macOS by default. Repositories enabled for the hosted Linux pilot
can choose one of two amd64 VMs. Linux workflows receive team secrets under
the same conditions as macOS workflows.

| Machine                   | vCPUs |   RAM |
| ------------------------- | ----: | ----: |
| `MachineType.linuxSmall`  |     1 | 2 GiB |
| `MachineType.linuxMedium` |     2 | 4 GiB |

```dart
final ci = await OpenCI.init(
  workflowName: 'Linux Tests',
  ciTriggers: [CITrigger.push(branch: 'main')],
  machine: MachineType.linuxSmall,
);
await ci.dart.test();
```

### Read the current execution context

Use `openCI.context` to branch on the event that actually started this run:

```dart
final context = openCI.context;
if (context is PullRequestContext) {
  final channelId = 'dashboard-pr-${context.number}';
  // Deploy a preview using channelId.
} else if (context is PushContext && context.branch == 'develop') {
  // Deploy to the live site.
}
```

`PullRequestContext` exposes `number`, `headBranch`, `baseBranch`, `headSha`,
`baseSha`, and `checkoutSha`. The checkout SHA identifies the verified test merge
commit; its base parent can be newer than the original webhook. `PushContext`
exposes the saved `branch`, `commitSha`, and `checkoutSha`, even if the branch has
advanced while queued. Tag pushes retain `refs/tags/<name>` as their push target.
Both extend `CIContext`, with `repository.owner`, `repository.name`,
`repository.githubBaseUrl` (including GitHub Enterprise), `jobId`, `runId`, and
`runNumber`.

Local runs return `LocalContext` and enter neither deployment branch. Context is
decoded once on first access, without Git or network requests. CI on an older
executor throws an upgrade error when context is accessed; existing workflows
that do not read it continue to work. Deploy the updated executor before adopting
the SDK API. Malformed, unsupported, or inconsistent metadata is rejected rather
than interpreted as a push. Tests can inject a context into the `OpenCI`
constructor or decode a complete environment with `WorkflowContext.fromEnvironment`.
This is an execution snapshot; publication still needs its existing checks for
newer commits. `ciTriggers` continues to declare scheduling conditions independently.

### Select a Flutter version

With SDK 0.2.1 or later, add an exact release to the workflow:

```dart
final openCI = await OpenCI.init(
  workflowName: 'Flutter CI',
  ciTriggers: [CITrigger.pullRequest(branch: 'main')],
  flutterVersion: '3.47.8',
);
```

CI selects this SDK through FVM before the first `flutter pub get` and before
running the workflow. Releases cached in the image are reused; other releases
are installed in the job's disposable VM. Installation failures stop the job.
Use a string literal release, including a prerelease such as `3.48.0-0.1.pre`;
channel names and computed values are not supported.

Omit `flutterVersion` or set it to `null` to use the image's default SDK.
OpenCI does not infer this value from `.fvmrc`. The selected SDK is available to
ordinary `flutter` and `dart` commands; explicit `fvm` or Shorebird commands can
select their own SDK. Running a workflow locally keeps the current SDK.

### Cancel older pull-request runs

With SDK 0.2.3 and a server supporting PR auto cancellation, enable it per workflow:

```dart
final ci = await OpenCI.init(
  workflowName: 'PR checks',
  ciTriggers: [CITrigger.pullRequest(branch: 'main')],
  cancelPreviousRuns: true,
);
```

The option defaults to `false` and must be a literal boolean. When a new commit
gets a scheduled run, older opted-in queued and running jobs for the same
repository, PR and workflow file are cancelled. Running commands observe the
cancellation on the next heartbeat (normally about 15 seconds), followed by VM
cleanup and a cancelled GitHub Check.

Other PRs (including other PRs in a stack), push jobs, completed jobs and
same-commit reruns remain independent. Path filtering preserves previous runs
of a skipped workflow. Runs created while the option was disabled are preserved.
Leave it disabled for deployment workflows that must finish. Local execution is
unaffected.

### Run only for matching changed paths

With SDK 0.2.0 or later, add `paths` to a push or pull-request trigger:

```dart
CITrigger.pullRequest(
  branch: 'main',
  paths: [
    'apps/mobile/**',
    'packages/shared/**',
    'openci/static_analysis.dart',
    '**/pubspec.yaml',
    'pubspec.lock',
  ],
)
```

With `paths`, the trigger runs when its event and branch match and at least one
changed file matches a pattern. Include shared dependencies and workflow
configuration files that can affect the build.

### Skip changes that only match ignored paths

With a compatible SDK and OpenCI planner, use `pathsIgnore` on a push or pull
request trigger. This example skips documentation-only changes.

```dart
CITrigger.push(
  branch: 'main',
  pathsIgnore: ['docs/**', 'README.md'],
)
```

At least one changed file outside the ignore patterns is enough to run the
workflow. Choose one path filter per trigger. Omit both filters to run on every
matching event and branch. A complete empty diff skips a path-filtered trigger.

Both filters take nonempty literal lists of positive, case-sensitive patterns
relative to the repository root. `*` matches within a path segment and `**`
matches recursively. Omit any `..` segments. Pull requests use the full PR diff
and pushes use the before/after diff. Deleted paths and both names of renamed
files count as changes. OpenCI skips only when it has a complete changed-file
list. Incomplete data or temporary retrieval failures run the applicable CI.

Excluded workflows finish their GitHub Checks as `skipped`, without creating a
build job or starting a worker VM. Filtering is performed by the OpenCI planner;
running a workflow locally still executes its commands.

When upgrading from 0.1.x, replace `whenChanged:` with `paths:` and
`.whenChanged` with `.paths`.

### Post a QR code on a pull request

Pass an HTTP or HTTPS URL to `openCI.pullRequest.postQrCode`. Use `lang: PostQrCodeLang.ja` for a Japanese comment, or `PostQrCodeLang.en` for English (the default). Set `size` to `PostQrCodeSize.small` (120x120 px), `PostQrCodeSize.medium` (180x180 px, the default), `PostQrCodeSize.large` (240x240 px), or `PostQrCodeSize.custom(width: ..., height: ...)` (1–1,000 px per side).

```dart
await openCI.pullRequest.postQrCode(
  url: Uri.parse('https://preview.example.com/build/42?platform=ios'),
  lang: PostQrCodeLang.ja,
  size: PostQrCodeSize.small,
);
```

After the workflow succeeds, OpenCI posts the workflow's registered name, URL and QR code in one comment per workflow file on the originating PR. Firebase App Distribution uploads also provide the uploaded app's version and build number automatically when their returned tester URL is passed to `postQrCode`, including across workflow isolates or processes in the same run. The Japanese comment displays:

```text
ワークフロー名: IOS CD
バージョン: 1.16.2
ビルド番号: 3
```

English comments use `Workflow name`, `Version`, and `Build number`. Other URLs can supply `version: '1.16.2'` and `buildNumber: '3'` explicitly. Each value accepts up to 256 UTF-8 bytes, without leading/trailing whitespace or control characters. Unknown version or build values are omitted; CI run numbers are used internally to order updates and are never substituted for app build numbers.

Pass an optional `DateTime expiresAt` to display `Expires at` / `有効期限`, for example `2026-11-22 06:05:30 UTC`. The timestamp is converted to UTC (years 1–9999); omitting it leaves out the expiry line. Expiry is always explicit, including for Hosting URLs, and is not remembered for later calls using the same URL. The comment remains visible after expiration. Display requires the updated executor; older executors ignore this optional field.

Later successful runs with QR output update the same comment's workflow name, app details, URLs, images, size and language. A failed run keeps the previous successful comment. A URL's query and fragment are included in both the link and the QR code. A run accepts up to eight requests, each with a URL of up to 2,331 bytes and no embedded credentials. Push and local runs skip publication.

App version details require both the updated executor and SDK 0.2.7 or later. Older SDKs still post URL-only output with the workflow name; older executors safely ignore the optional metadata and keep their existing comment format.

OpenCI stores new QR images on `openci/pr-qr` in the same repository. Keep any
existing `genuineci/pr-qr` branch so older PR comments can still load their
images. The GitHub App needs write access to Contents and Pull requests. If the
PR closes or its head changes during the build, OpenCI skips the comment.

### Run commands

For packages that depend on `build_runner`, generate code before analysis or tests.
The build runs in the workflow directory, or in the package selected by `dir`.

```dart
await openCI.dart.runBuildRunner();
```

Analyze Dart code with the installed SDK:

```dart
await openCI.dart.analyze();
await openCI.dart.analyze(dir: 'openci', fatalInfos: true);
```

Warnings fail by default. Set `fatalInfos: true` to also fail on info-level
diagnostics, or `fatalWarnings: false` to allow warnings. `dir` overrides the
workflow's working directory for this call.

Run Dart package tests in the workflow's working directory, or override it
for one call with `dir`. Failed tests fail the workflow.

```dart
await openCI.dart.test();
await openCI.dart.test(dir: 'openci');
```

Check Dart formatting without rewriting files:

```dart
await openCI.dart.checkFormat();
await openCI.dart.checkFormat(dir: 'apps/mobile');
```

The check uses `dart format --output=none --set-exit-if-changed` on tracked
and non-ignored new Dart files in the selected directory and its descendants.
This includes tracked generated code and excludes ignored build outputs and
downloaded packages. Formatting differences, Git errors, and formatter errors
fail the workflow. A directory with no matching files succeeds.

Like the other helpers, it uses the workflow's working directory and accepts
`dir` to override it for one call. The directory must be inside a Git checkout.
Dart, Git, Bash, and `xargs` must already be on `PATH`; the helper does not
install them.

For Flutter analysis, use `await openCI.flutter.staticAnalysis()` or pass your preferred `flutter analyze` flags to `openCI.run()`.

### Launch an iOS Simulator

Create a fresh simulator and wait for it to finish booting:

```dart
final simulator = await openCI.launchIosSimulator();
// Pass simulator.id to Flutter or Patrol's --device option.
await simulator.dispose();
```

This requires macOS with Xcode and an installed compatible runtime. By default,
it creates an iPhone 17 Pro and lets Xcode choose the newest compatible installed
iOS runtime (iOS 26 or later). It does not download runtimes or reuse existing
devices. Customize the device type, simulator name, runtime, or boot timeout:

```dart
final simulator = await openCI.launchIosSimulator(
  device: 'iPhone 17 Pro',
  name: 'Dashboard Patrol',
  runtime: 'com.apple.CoreSimulator.SimRuntime.iOS-26-5',
  bootTimeout: const Duration(minutes: 10),
);
```

`device` and `runtime` accept the names or identifiers supported by `simctl`.
Boot errors and timeouts trigger cleanup of the newly created device. After a
successful launch, call `dispose()` in `finally` to shut down and delete it.
Repeated disposal is safe, and failed deletion can be retried.

Use `patrol.test()` inside `try/finally` so the simulator is also disposed when a
test fails:

```dart
final simulator = await openCI.launchIosSimulator();
try {
  await openCI.patrol.test(
    dir: 'apps/dashboard',
    device: simulator.id,
    targets: ['patrol_test/app_startup_test.dart'],
    env: [Secrets.dashboardPatrolEmail, Secrets.dashboardPatrolPassword],
  );
} finally {
  await simulator.dispose();
}
```

### Exchange GATT values between two simulators

For a Patrol test, `openCI.patrol.testWithVirtualBle()` builds the app once,
starts two iOS Simulators and Bumble, and runs the prebuilt test on each device.
The app reads its `endpoint` from `tmp/openci-virtual-ble.json` in its data container.
B publishes first. Once B is ready, the SDK starts A. Each app has ten minutes
to connect to the bridge and another eight minutes to publish its GATT value.
The configuration for B includes `peerWaitTimeoutSeconds` for UI tests that
wait for A to appear. Both devices are removed when the test finishes.

```dart
await openCI.patrol.testWithVirtualBle(
  dir: 'apps/mobile',
  target: 'patrol_test/pairing_test.dart',
  bundleId: 'org.example.mobile',
  serviceUuid: 'BE110001-5D9F-4810-8692-47717E010001',
  characteristicUuid: 'BE110002-5D9F-4810-8692-47717E010001',
);
```

Use Patrol's [build-time test discovery](https://patrol.leancode.co/documentation/ci/build-time-test-discovery)
with the static iOS XCTest runner. The example uses Patrol 4.11.0 and `patrol_cli` 4.9.0.
The returned directory contains per-device logs and XCTest result bundles.
Pass `resultJsonFile` to collect a JSON file written to each app's `tmp` directory
as `A.json` and `B.json` for workflow-specific assertions.

`startVirtualBle()` starts one loopback WebSocket server and two Bumble GATT
devices. It creates a temporary Python environment and installs the pinned
Bumble release. The default interpreter is `python3.13`. To use another
Python 3.11+ installation with venv and pip, pass `pythonExecutable`.
Allow package installation on the host. Both simulator apps use the same Mac.

```dart
final radio = await openCI.startVirtualBle(
  serviceUuid: 'BE110001-5D9F-4810-8692-47717E010001',
  characteristicUuid: 'BE110002-5D9F-4810-8692-47717E010001',
);
try {
  final a = radio.endpoint(VirtualBlePeer.a);
  final b = radio.endpoint(VirtualBlePeer.b);
  // Pass the two ws://127.0.0.1 URLs to your simulator apps.
  await runYourSimulatorTests(a, b);
} finally {
  await radio.dispose();
}
```

The clients publish a readable characteristic value (`card`, base64) over
`/A` and `/B`. Once both have published, each receives the value read over
GATT from its peer (`peer`). A `write` delivers `incoming` to the receiving
app. Its `reply` releases the ATT Write Response and the sender receives
`accepted`. Each session owns one connection per role. Use
`waitForPeer()` to wait for an app to publish before starting its partner.

See the [two-simulator Flutter example](https://github.com/openci-org/openci/tree/develop/packages/openci_virtual_ble/example).

### Run Patrol tests

`openCI.patrol.test()` runs `dart run patrol_cli:main test` using the project's
resolved `patrol_cli` package. Configure Patrol in the app, resolve dependencies,
and make the test device available first. No global CLI installation is needed.

```dart
await openCI.patrol.test(
  dir: 'apps/mobile',
  device: 'emulator-5554',
  targets: ['patrol_test/login_test.dart'],
  verbose: true,
  additionalArguments: ['--flavor', 'staging', '--tags', 'smoke && !slow'],
);
```

`device` is required. Omit `targets` to use Patrol's configured test directory.
`env` accepts generated `Secret` references with non-empty values. Use
`String.fromEnvironment` in the test to read a value by its original key.
The SDK passes a temporary JSON file to Patrol and deletes it when the command
finishes.
`dir` overrides the workflow's working directory for this call. Additional CLI
arguments are passed individually without shell expansion; Patrol's own parsing
rules still apply. Command output streams to the workflow log. Nonzero exits
throw `ProcessException`, allowing callers to use `finally` for cleanup before
the workflow fails. The helper does not create devices or configure native test
targets.

### Publish a Dart package to pub.dev

Call `publishToPubDev()` after your analysis and tests in a publishing workflow:

```dart
final result = await openCI.dart.publishToPubDev(
  serviceAccountJsonBase64:
      Secrets.pubDevServiceAccountJsonBase64.value,
  skipIfPublished: true,
);

print('${result.name} ${result.version}: ${result.status.name}');
print(result.url);
```

The helper reads `name` and `version` from the workflow directory's `pubspec.yaml`.
Use `dir` to override the directory for this call. It accepts the default
publication destination or an explicit `https://pub.dev`; private packages and
other registries are rejected. Dart must already be on `PATH`.

Enable [automated publishing with a Google service account](https://dart.dev/tools/pub/automated-publishing#publish-from-anywhere-using-a-service-account)
in the package's pub.dev Admin tab. Pass its Base64-encoded JSON key using the
generated `Secrets` accessor. This is a Google ID token flow, not an OAuth
access token or GitHub Actions token. No gcloud installation is needed. Pub.dev
requires a package's first version to be published manually before configuring
automated publishing.

The helper runs `dart pub publish --force` once, without a separate dry run or
`--skip-validation`. Pub's normal validation still rejects errors; warnings are
accepted without a prompt. Temporary authentication settings are isolated from
your normal pub configuration and removed when the call finishes. The JSON key
is kept in memory, and the short-lived token is passed through a child-process
environment variable and redacted from command output.

`PubPublishResult` contains `name`, `version`, `url`, and `status`:

- `PubPublishStatus.published`: pub successfully submitted the version. Indexing
  and dependency resolution can take a few minutes to catch up.
- `PubPublishStatus.alreadyPublished`: the version existed before any upload was
  attempted. This requires `skipIfPublished: true`; the default is to throw.
  Skipping compares the name and version, not the archive contents.

HTTP requests time out after one minute; each pub command after ten minutes.
Authentication, validation, and upload failures propagate, including a concurrent
publish that wins after the initial version lookup. The helper does not retry
uploads or turn failed uploads into skips. A timeout or lost response can occur
after pub.dev has accepted a version: check its page before rerunning.

Limit publishing credentials to trusted runs in your CI configuration. This SDK
method does not change executor secret permissions. The current OpenCI executor
injects team secrets into jobs; a workflow trigger or Dart context guard alone
does not isolate a publishing key from other jobs in the team.

### Flutter builds and tests

Call `await openCI.flutter.buildWeb()` to build a release web bundle. Use
`buildWeb(noPub: true)` when the workflow has already resolved dependencies.

Run Flutter tests with an optional time zone and tag exclusion:

```dart
await openCI.flutter.unitTests(tz: TimeZone.asiaTokyo, excludeTags: 'golden');
```

The `tz` argument accepts `TimeZone.asiaTokyo` or `TimeZone.utc` and sets the command's `TZ` environment variable. Omitting it preserves the inherited time zone. The `excludeTags` argument is passed as Flutter's `--exclude-tags` selector, including expressions such as `'golden || slow'`. Omit it to run without a tag exclusion. Use `dir` to override the workflow's working directory for that call.

Build Android APKs and app bundles with an optional product flavor and Dart defines:

```dart
await openCI.flutter.buildApk(
  flavor: 'staging',
  dartDefines: {'API_URL': 'https://staging.example.com'},
);
await openCI.flutter.buildAab(
  flavor: 'production',
  dartDefines: {
    'API_URL': 'https://api.example.com',
    'FEATURE_ENABLED': 'true',
  },
);
```

The `flavor` argument is passed to Flutter's `--flavor` option. Omit it to keep Flutter's default flavor selection. Both methods also accept `dir` to override the workflow's working directory for that call.

The `dartDefines` argument accepts a `Map<String, String>`. Each entry becomes a separate `--dart-define 'KEY=VALUE'` argument, preserving spaces, quotes, and other shell characters literally. Omitting it or passing an empty map adds no defines. Read the values in your app with compile-time constructors such as `const String.fromEnvironment('API_URL')` or `const bool.fromEnvironment('FEATURE_ENABLED')`.

Flutter's restrictions on define values still apply: the Flutter 3.47.3 compiler used for validation rejects values containing literal newlines.

Create a Shorebird Android release and receive its App Bundle path:

```dart
if (Secrets.shorebirdToken.value.isEmpty) {
  throw StateError('SHOREBIRD_TOKEN must not be empty.');
}

final aabPath = await openCI.shorebird.releaseAab(
  flutterVersion: '3.47.7',
  flavor: 'production',
  dartDefines: {'ENV': 'production'},
  additionalArguments: ['--build-number=42'],
);
```

Install the [Shorebird CLI](https://docs.shorebird.dev/code-push/ci/github/), Java, and the Android SDK on the build machine. Initialize the app with `shorebird init` and commit `shorebird.yaml`. Register `SHOREBIRD_TOKEN` in OpenCI Secrets, run `openci sync --secrets`, and reference `Secrets.shorebirdToken` in the workflow so the worker injects it. Configure Android release signing in Gradle and restore its keystore and properties from your secrets before calling the helper, as with `buildAab()`. The project's Gradle configuration determines the signing identity.

`releaseAab()` runs `shorebird release android --artifact aab` with the required `flutterVersion`. Pass `flavor` explicitly for flavored Shorebird apps. `dir` overrides the workflow directory. `dartDefines` and each literal argument in `additionalArguments` are forwarded to Flutter after `--`; artifact type, flavor, and release build mode are managed by the helper.

The returned path is the single nonempty `.aab` in `build/app/outputs/bundle/release`, or `build/app/outputs/bundle/<flavor>Release` when a flavor is supplied. This follows Shorebird's standard Android output layout. A successful incremental Gradle build may reuse an existing bundle. A failed command, missing bundle, or multiple nonempty bundles fails the workflow.

By default, the command [registers the release with Shorebird](https://docs.shorebird.dev/code-push/release/). Set `dryRun: true` to build and validate without registering it. Authentication and an unused version/build number are required even for dry runs. Pass the returned `aabPath` to `deployAabToPlayConsole()` or `deployAabToFirebaseAppDistribution()` when ready to upload it.

To build a universal APK and an app bundle in a single Shorebird release, use `releaseAndroid()`.

```dart
if (Secrets.shorebirdToken.value.isEmpty) {
  throw StateError('SHOREBIRD_TOKEN must not be empty.');
}

final artifacts = await openCI.shorebird.releaseAndroid(
  flutterVersion: '3.47.7',
  flavor: 'production',
  dartDefines: {'ENV': 'production'},
  additionalArguments: ['--build-number=42'],
);
```

Use the same CLI, Android SDK, token, and Gradle release-signing setup as `releaseAab()`. `releaseAndroid()` runs `shorebird release android --artifact apk`. It accepts the same arguments as `releaseAab()` and requires a universal APK.

The returned record contains absolute paths to both files. `artifacts.apkPath` points to the nonempty APK in `build/app/outputs/flutter-apk`, named `app-release.apk` or `app-<lowercased-flavor>-release.apk`. `artifacts.aabPath` points to the single nonempty app bundle for the selected variant, as in `releaseAab()`. Pass `artifacts.apkPath` to `deployApkToFirebaseAppDistribution()` and `artifacts.aabPath` to `deployAabToPlayConsole()`.

Upload a built APK to Firebase App Distribution:

```dart
final testerUrl = await openCI.flutter.deployApkToFirebaseAppDistribution(
  apkPath: 'build/app/outputs/flutter-apk/app-release.apk',
  appId: '1:123456789:android:abcdef',
  serviceAccountJsonBase64: Secrets.firebaseServiceAccountJsonBase64.value,
  groups: ['qa-team'],
);
await openCI.pullRequest.postQrCode(url: testerUrl, lang: PostQrCodeLang.ja);
```

Pass the Android Firebase App ID from your Firebase project settings or the matching client's `client_info.mobilesdk_app_id` in `google-services.json`. Pass the Base64-encoded service account JSON key from your CI secrets; the account needs the [Firebase App Distribution Admin role](https://firebase.google.com/docs/app-distribution/authenticate-service-account?platform=android). Credentials stay in memory. Relative `apkPath` values use the workflow directory, or `dir` when specified.

The helper streams the APK to the [Firebase App Distribution REST API](https://firebase.google.com/docs/reference/app-distribution/rest/v1/upload.v1.projects.apps.releases/upload) and waits for processing to finish. Authentication is limited to 60 seconds, upload to 10 minutes, and processing to 5 minutes. Missing or empty APKs, invalid App IDs, authentication failures, and upload or processing errors fail the workflow.

For either APKs or AABs, pass Firebase group aliases in `groups`, individual email addresses in `testers`, or both. OpenCI distributes the release after Firebase finishes processing it. When both lists are empty, OpenCI only uploads the release.

The upload returns the release's Firebase tester URL as a `Uri`. The optional `postQrCode` call shares it with the PR. Testers still need access to the release in Firebase.

Upload a built Android App Bundle to Firebase App Distribution:

```dart
await openCI.flutter.deployAabToFirebaseAppDistribution(
  aabPath: 'build/app/outputs/bundle/release/app-release.aab',
  appId: '1:123456789:android:abcdef',
  serviceAccountJsonBase64: Secrets.firebaseServiceAccountJsonBase64.value,
  groups: ['qa-team'],
);
```

AAB uploads require the [Google Play integration](https://firebase.google.com/docs/app-distribution/android/distribute-cli?apptype=aab): link the Firebase project to Google Play, use the same package name for both apps, complete the Play app review, publish the app to a testing or production track, and accept the internal app sharing terms. An unreviewed internal-test release does not satisfy these requirements. The helper checks Firebase's AAB integration status before sending the file and reports setup problems. If Play's status is temporarily unavailable, it attempts the upload as the Firebase CLI does.

Pass the Android Firebase App ID and Base64-encoded service account JSON as in the APK example. Relative `aabPath` values use the workflow directory, or `dir` when specified. Authentication is limited to 60 seconds, the integration check to 30 seconds, upload to 10 minutes, and processing to 5 minutes.

Upload an AAB to Google Play Console:

```dart
await openCI.flutter.deployAabToPlayConsole(
  aabPath: 'build/app/outputs/bundle/release/app-release.aab',
  packageName: 'com.example.app',
  serviceAccountJsonBase64: Secrets.googlePlayServiceAccountJsonBase64.value,
);
```

Use the Android `applicationId` as `packageName`. Register `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_BASE64` in your team's CI secrets, generate its getter with `openci sync --secrets`, and import `generated/secrets.g.dart` in your workflow. [Enable the Google Play Developer API and grant the service account access in Play Console](https://developers.google.com/android-publisher/getting_started). The account needs permission to view the app and release to the selected track; Firebase permissions alone are insufficient. Set up the app and upload its first build through Play Console before using this API. Sign the AAB with the app's accepted upload key and use a new version code.

The helper defaults to `track: 'internal'` and a completed release. Pass another existing track ID to target a different track, or `draft: true` to save a draft, including for apps that are still in draft state. The selected track is updated with a single new AAB, replacing its previous release; staged rollouts are not supported. Relative paths use the workflow directory, or `dir` when specified. Credentials stay in memory and file uploads are streamed.

The helper creates a Google Play edit, uploads the artifact, updates the track, then commits the edit. Success means Google accepted the edit; it does not wait for app review or managed publishing, or guarantee the release is already available to testers. Commits use [`ERROR_IF_IN_REVIEW`](https://developers.google.com/android-publisher/api-ref/rest/v3/edits/commit) so an existing review is not cancelled. Failed operations attempt to discard their uncommitted edit. Authentication and metadata requests time out after 60 seconds; uploads after 10 minutes. If a commit times out or its response is lost, check Play Console before retrying, as Google may already have accepted it. Run one deployment per app at a time: [a new edit or a Play Console change can invalidate an in-progress edit](https://developers.google.com/android-publisher/edits).

Build a signed Ad Hoc IPA with App Store Connect credentials and a separate certificate private key:

```dart
final ipaPath = await openCI.flutter.buildIpa(
  distributionMethod: IosDistributionMethod.adHoc,
  ascKeys: AppStoreConnectKeys(
    issuerId: Secrets.openciGeneratedAscIssuerId.value,
    keyId: Secrets.openciGeneratedAscKeyId.value,
    privateKeyBase64: Secrets.openciGeneratedP8Base64.value,
  ),
  certificatePrivateKey: Secrets.openciGeneratedIosCertificatePrivateKey.value,
  flavor: 'dev',
  additionalArguments: ['--dart-define=SAMPLE=Hello World'],
);
```

Here, `Secrets` refers to your workflow's generated secret definitions. Pass the `.p8` file contents as Base64 and the certificate private key as PEM. Each `additionalArguments` item represents one argument, including any spaces in its value. Use build options shared by `flutter build ios` and `flutter build ipa`, such as `--target`, `--dart-define`, and `--build-number`. Signing and export options are managed by `buildIpa()`; do not pass `--no-codesign`, `--export-method`, or `--export-options-plist`.

Use `IosDistributionMethod.appStore` to export an IPA for App Store Connect, including TestFlight. This selects an App Store provisioning profile and generates the corresponding export options. Uploading the IPA to App Store Connect is a separate step.

`buildIpa()` prepares Flutter's release configuration, detects the app's Bundle ID, creates and unlocks a signing Keychain, fetches or creates signing certificates and provisioning profiles, imports the certificates, and applies the profiles to Xcode. It then builds the IPA using the generated ExportOptions.plist and returns the absolute path of the new, nonempty IPA. Missing exports and multiple new IPAs fail the workflow. The `flavor` argument and Flutter's default flavor are respected. Use `dir` to override the workflow's working directory for the whole operation.

Run this on a disposable macOS build VM with Flutter, Xcode and the required iOS components, Codemagic CLI tools, Ruby `xcodeproj`, and the project's CocoaPods dependencies available. This initial integration supports one iOS app project directly under `ios/`; additional app targets and extensions are not provisioned separately. Ad Hoc devices must already be registered in the Apple Developer team. Signing files and the Keychain remain until the VM is deleted. Uploading the IPA to Firebase App Distribution is a separate step.

Create a Shorebird iOS release with the same signing credentials:

```dart
if (Secrets.shorebirdToken.value.isEmpty) {
  throw StateError('SHOREBIRD_TOKEN must not be empty.');
}

final ipaPath = await openCI.shorebird.releaseIos(
  bundleId: 'org.example.app.prod',
  distributionMethod: IosDistributionMethod.appStore,
  ascKeys: AppStoreConnectKeys(
    issuerId: Secrets.openciGeneratedAscIssuerId.value,
    keyId: Secrets.openciGeneratedAscKeyId.value,
    privateKeyBase64: Secrets.openciGeneratedP8Base64.value,
  ),
  certificatePrivateKey: Secrets.openciGeneratedIosCertificatePrivateKey.value,
  flutterVersion: '3.47.7',
  flavor: 'prod',
  dartDefines: {'ENV': 'production'},
  additionalArguments: ['--build-number=42'],
);
```

Install the [Shorebird CLI](https://docs.shorebird.dev/code-push/ci/github/) on the disposable macOS VM and make it available on the workflow's noninteractive shell PATH. The same Xcode, Codemagic CLI tools, Ruby `xcodeproj`, CocoaPods, and single-app signing requirements as `buildIpa()` apply. Initialize the app with `shorebird init` beforehand and commit `shorebird.yaml`. When using flavors, configure the matching Shorebird apps and pass `flavor` explicitly. Set `bundleId` to the selected flavor's iOS app identifier so the helper can fetch its signing files before building.

Register a Shorebird API key as `SHOREBIRD_TOKEN` in OpenCI Secrets and run `openci sync --secrets` to generate its accessor. Reference `Secrets.shorebirdToken` in the workflow, as above: OpenCI only injects secrets referenced by the workflow, so registering the key alone is not enough. The worker supplies this environment variable to the CLI; the helper does not put its value in the command or require a token argument. Authentication is also required for dry runs.

`flutterVersion` is required: use a version or revision supported by Shorebird for your project. The helper runs `shorebird release ios`, which builds using its selected Flutter SDK; no separate system Flutter command runs beforehand. `dir` overrides the workflow directory. `dartDefines` and `additionalArguments` are passed to the release build. Each additional argument is one literal shell argument, forwarded to Flutter after `--`. The helper manages signing, export options, flavor, and release build mode, and rejects overrides of those options.

By default, this builds a signed IPA and [registers the release with Shorebird](https://docs.shorebird.dev/code-push/release/). Use a new app version/build number for each release. Set `dryRun: true` to build and validate without uploading to Shorebird. Dry runs also check for an existing release, so use an unused version/build number. The helper disables Xcode's automatic version/build-number management in ExportOptions.plist so the exported IPA matches the version recorded by Shorebird.

Success requires exactly one newly exported, nonempty IPA; its absolute path is returned. A nonzero CLI exit, failed export, or ambiguous IPA fails the workflow. If Shorebird registered the release before a later export/upload error, check the console before retrying the same version. Signing files and the Keychain remain until the VM is deleted. Uploading the IPA to TestFlight or Firebase App Distribution is a separate call.

To upload to TestFlight, build the IPA with `IosDistributionMethod.appStore`, then pass the returned path:

```dart
await openCI.flutter.deployIpaToTestFlight(
  ipaPath: ipaPath,
  ascKeys: AppStoreConnectKeys(
    issuerId: Secrets.openciGeneratedAscIssuerId.value,
    keyId: Secrets.openciGeneratedAscKeyId.value,
    privateKeyBase64: Secrets.openciGeneratedP8Base64.value,
  ),
);
```

The helper uses the [App Store Connect Build Upload API](https://developer.apple.com/documentation/appstoreconnectapi/build-uploads). Provide a team API key with access to the app and build uploads. It reads the Bundle ID, version, and build number from the IPA's app-level `Info.plist` using macOS `unzip` and `plutil`, and finds the matching App Store Connect app. Relative `ipaPath` values use the workflow directory, or `dir` when specified. Private keys and signed API tokens stay in memory.

The IPA is streamed in the byte ranges requested by Apple. API requests have a 60-second timeout, and binary transfer is limited to 20 minutes. After committing the uploaded file, the helper polls that specific build upload every 15 seconds until its state is `COMPLETE`. A successful file transfer alone does not finish the workflow. Failed processing, invalid responses, HTTP errors, and timeouts fail the workflow without logging tokens or signed upload URLs.

Processing is limited to 30 minutes by default; override `processingTimeout` for a longer wait. Timing out does not cancel Apple's processing, so check the existing upload before retrying. The helper does not assign tester groups or submit external beta review; existing automatic distribution settings in App Store Connect still apply. Export compliance and beta review may require further action before testers can install the build.

Apps that use standard encryption algorithms outside Apple's operating systems can supply their export compliance answers on deployment.

```dart
const exportCompliance = TestFlightExportCompliance.standardEncryption(
  appDescription: 'A sports coaching app for training plans and team messages.',
  availableOnFrenchStore: true,
);
await openCI.flutter.deployIpaToTestFlight(
  ipaPath: ipaPath,
  ascKeys: ascKeys,
  exportCompliance: exportCompliance,
);
```

Set `availableOnFrenchStore` to `true` for Yes or `false` for No. The answer records distribution intent on the encryption declaration. App Store availability is managed in App Store Connect. Supply your own app description and a team key with permission to manage app encryption declarations.

After Apple processes the upload, OpenCI reuses a declaration with matching answers or creates one for the app. It applies Apple's approval or exemption to the build from that upload. If Apple requires documentation or review, the workflow reports the declaration ID and build ID. Complete the requested steps in App Store Connect, then use the reported build ID to apply the answers to the existing build. [Apple’s documentation requirements](https://developer.apple.com/help/app-store-connect/reference/app-information/export-compliance-documentation-for-encryption/)

```dart
await openCI.flutter.applyTestFlightExportCompliance(
  buildId: buildId,
  ascKeys: ascKeys,
  exportCompliance: exportCompliance,
);
```

Upload the IPA to Firebase App Distribution:

```dart
final testerUrl = await openCI.flutter.deployIpaToFirebaseAppDistribution(
  ipaPath: ipaPath,
  serviceAccountJsonBase64: Secrets.firebaseServiceAccountJsonBase64.value,
);
await openCI.pullRequest.postQrCode(url: testerUrl, lang: PostQrCodeLang.ja);
```

Register `FIREBASE_SERVICE_ACCOUNT_JSON_BASE64` in your team's OpenCI secrets with the Base64-encoded contents of a service account JSON key, then run `openci sync --secrets` to generate its getter. The service account needs the [Firebase App Distribution Admin role](https://firebase.google.com/docs/app-distribution/authenticate-service-account?platform=ios) on the destination project. Dart uses the key in memory to obtain an OAuth token with `googleapis_auth`; credentials are never written to files or included in commands or logs.

The helper streams the IPA directly to the [Firebase App Distribution REST API](https://firebase.google.com/docs/reference/app-distribution/rest/v1/upload.v1.projects.apps.releases/upload), then polls the returned operation until Firebase finishes processing it. It does not require Node.js or the Firebase CLI. Upload requests time out after 10 minutes, and processing is limited to 5 minutes. Authentication, HTTP, and processing failures fail the workflow without logging raw responses or tokens.

The helper uses macOS `unzip` and `plutil` to read `GOOGLE_APP_ID` from the exported app's `GoogleService-Info.plist`. Pass `appId` explicitly if the IPA does not bundle that file. The project number comes from this Firebase App ID. Relative `ipaPath` values use the workflow directory, or `dir` when specified; the absolute path returned by `buildIpa()` works across working directories.

By default, this only uploads a release. Set `groups` (group aliases) or `testers` (email addresses) to distribute it to testers, and optionally provide `releaseNotes`. The Dashboard workflow only uploads. Actual upload validation requires Firebase credentials and a signed IPA.

The upload returns the release's Firebase tester URL as a `Uri`. The optional `postQrCode` call shares it with the PR. Testers still need access to the release in Firebase.

## Firebase Functions

```dart
await openCI.firebase.functions.deploy(
  projectId: 'my-firebase-project',
  codebase: 'api',
  firebaseConfigPath: 'firebase/firebase.json',
  serviceAccountJsonBase64: Secrets.firebaseServiceAccountJsonBase64.value,
);
```

The runner must provide `firebase` on `PATH` and a compatible Node.js runtime. The helper uses the installed CLI to run `firebase deploy --only functions:api --project my-firebase-project --non-interactive`. Omit `codebase` to deploy all Functions codebases in the config. `firebaseConfigPath` defaults to `firebase.json` and is relative to the workflow directory, or `dir` when supplied; absolute config paths are accepted.

Provide a service account JSON key as a Base64-encoded OpenCI secret, with permission to deploy Functions to the destination project. The helper creates a temporary key file, passes its path as `GOOGLE_APPLICATION_CREDENTIALS` ([ADC](https://firebase.google.com/docs/cli#use_the_cli_with_ci_systems)), isolates Firebase's saved login, and deletes the temporary files on success or failure. It does not change the workflow process's environment.

Install source dependencies and prepare the complete runtime environment files before calling. Firebase CLI executes the config's `predeploy` and `postdeploy` hooks. Logs stream to the workflow; a nonzero exit throws. The helper does not force deletions or retry partial deployments. Branch conditions, tests and deployment ordering belong in the workflow.

## Firebase Hosting

Deploy a built static site without installing Node.js or the Firebase CLI:

```dart
final url = await openCI.firebaseHosting.deploy(
  siteId: 'my-hosting-site',
  firebaseConfigPath: 'firebase.json',
  serviceAccountJsonBase64: Secrets.firebaseHostingServiceAccountJsonBase64.value,
);
```

The helper reads the `hosting` section of `firebase.json`, including `public`, `ignore`, headers, redirects, static destination rewrites, `cleanUrls`, `trailingSlash`, `i18n` and `appAssociation`. It converts the [Firebase configuration format](https://firebase.google.com/docs/hosting/full-config) to the REST API's [`ServingConfig`](https://firebase.google.com/docs/reference/hosting/rest/v1beta1/sites.versions#ServingConfig), so there is no need to duplicate routing or cache settings in Dart.

Create a dedicated service account with [Firebase Hosting Admin](https://docs.cloud.google.com/iam/docs/roles-permissions/firebasehosting) (`roles/firebasehosting.admin`) on the destination project. Enable the [Firebase Hosting API](https://firebase.google.com/docs/hosting/api-deploy) and set up the project's default Hosting site before using this helper; `siteId` can then identify any existing site in that project. Register its Base64-encoded JSON key as `FIREBASE_HOSTING_SERVICE_ACCOUNT_JSON_BASE64` in your team's secrets, run `openci sync --secrets`, and import the generated `Secrets` class. This is the same credential format as the FAD helpers. The key and OAuth token stay in memory.

`firebaseConfigPath` is relative to the workflow's `currentWorkingDirectory`, or to `dir` when supplied. `hosting.public` is relative to the JSON file's directory. You can override it with `publicDirectory`, which is relative to the workflow directory or `dir`. `dir` is relative to the workspace; `dir: ''` selects the workspace root. Absolute file and content paths are accepted.

For a Hosting array, the helper selects the entry whose `site` matches `siteId`. If entries use deploy targets, pass `target: 'website'` to select one. A single configuration without a `site` is accepted without `target`. The destination is always the explicit `siteId`; the helper does not resolve `.firebaserc` mappings. Missing, ambiguous and mismatched selections fail before authentication or publication.

Build the site before deploying: for example, Flutter web uses `build/web`, and Astro commonly uses `dist`. Firebase CLI `predeploy` and `postdeploy` hooks are not executed. Framework builds and backend rewrites (`function`, `run`, `dynamicLinks`) are not supported by the JSON reader and fail before remote changes.

The helper uploads a snapshot of the output, excluding hidden files/directories (except `.well-known`), `node_modules`, and `firebase.json`. `hosting.ignore` adds exclusions relative to that output; it supports `*`, `**`, `?`, character classes and brace alternatives, including directory exclusions. Negation and extglobs are rejected. For example, `**/.*` also excludes `.well-known`. Symlinks and output with no deployable files are rejected before any remote changes.

Existing calls with `publicDirectory` and an optional `config` still work without loading any JSON file. `config` uses REST `ServingConfig` names (for example, rewrites use `glob` and `path`). Do not combine a non-empty `config` with `firebaseConfigPath`.

### Short-lived PR previews

Use the same channel ID for every deployment of a PR. Include the repository and app name in that ID if multiple repositories or apps share a Hosting site. For example, this function accepts the current PR number from its caller:

```dart
Future<void> deployPrPreview(OpenCI openCI, int pullRequestNumber) async {
  final preview = await openCI.firebaseHosting.deployPreview(
    siteId: 'my-hosting-site',
    channelId: 'web-pr-$pullRequestNumber',
    firebaseConfigPath: 'firebase.json',
    serviceAccountJsonBase64: Secrets.firebaseHostingServiceAccountJsonBase64.value,
    expiresIn: const Duration(hours: 1), // Default; refreshed on each deploy.
    maxPreviewChannels: 20, // Default site-wide preview budget.
  );
  await openCI.pullRequest.postQrCode(
    url: preview.url,
    expiresAt: preview.expiresAt,
    lang: PostQrCodeLang.ja,
  );
}
```

`deployPreview()` returns `FirebaseHostingPreview` with `Uri url` and `DateTime expiresAt` in UTC. The expiry is Firebase's actual [`expireTime`](https://firebase.google.com/docs/reference/hosting/rest/v1beta1/sites.channels#Channel) from the final channel refresh before release, rather than a local estimate from `expiresIn`. If Firebase omits a valid expiration time, deployment fails before releasing the version. When migrating from the earlier `Uri` return type, use `preview.url` wherever the URL was used. Live `deploy()` still returns `Uri`.

The actual channel ID is prefixed with `openci-` (for example, `openci-web-pr-123`). The same channel keeps its URL while it exists. Redeploying refreshes the expiry, including just before publishing, instead of accepting Firebase's seven-day default. `expiresIn` accepts one minute through 30 days. Preview channels retain one previous release, the minimum supported by Firebase.

Before deploying a preview, the helper lists all channels, removes expired previews it owns, and evicts its least recently updated previews until the deployment fits `maxPreviewChannels` (1–100, default 20). The budget includes other tools' previews; the `live` channel is excluded. Ownership requires both the `openci-` prefix and the helper's `openci-workflow: preview` label. Eviction immediately deactivates old preview URLs. If unrelated channels fill the budget, the helper fails before deleting any previews. A colliding unowned channel is never adopted.

Serialize preview deployments to the same site: the budget check and cleanup are not a distributed lock, so concurrent runs or other deployment tools can still exhaust Firebase quotas. Firebase may take up to 24 hours to reclaim deleted channels' versions and storage. Expiry, bounded channels and release retention reduce accumulation; bandwidth, total storage and API request quotas remain project constraints. Preview URLs are publicly accessible to anyone who knows the URL. The helper does not add preview domains to Firebase Authentication; configure authorized domains separately if your app needs sign-in.

Uploads use gzipped content hashes and only send files Firebase requests, in batches of at most 1,000 file paths and at most four concurrent file uploads. Authentication and metadata requests time out after 60 seconds; each file upload after 10 minutes. Failures before releasing attempt to delete the unpublished version. If the release response is lost or times out, check Hosting before retrying: the release may already be live. Automated tests mock Google APIs; a real deployment additionally requires a configured site and a service account with access.

## Run locally

```sh
dart pub get
dart run openci/static_analysis.dart
```

Commands run sequentially when awaited. A failed command exits the workflow with the same exit code. Commands use `sh`, so the runtime needs a Unix shell and the tools called by the workflow.

Use `workingDirectory` to run a command relative to the repository root:

```dart
await openCI.run('flutter analyze', workingDirectory: 'apps/mobile');
```

## Build logs

Command output is printed to stdout and stderr. The Cloud Run executor captures these streams through Orchard and stores build logs in Firebase SQL Connect. Local execution prints to the terminal.
