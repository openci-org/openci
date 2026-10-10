# OpenCI Workflow

Write OpenCI workflows in Dart. Define branch triggers, run shell commands, and stream command output to OpenCI's build logs.

## Install

Add the SDK to your repository's root package:

```sh
dart pub add --dev openci_workflow
```

For a Flutter repository, use `flutter pub add --dev openci_workflow`.

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

OpenCI discovers Dart files in `openci/` and matches their declared triggers to GitHub events. Keep workflow names and trigger branches as string literals so the planner can read them without executing the workflow.

For Flutter analysis, use `await openCI.flutter.staticAnalysis()` or pass your preferred `flutter analyze` flags to `openCI.run()`.

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

Build a signed Ad Hoc IPA with App Store Connect credentials and a separate certificate private key:

```dart
final ipaPath = await openCI.flutter.buildIpa(
  distributionMethod: IosDistributionMethod.adHoc,
  ascKeys: AppStoreConnectKeys(
    issuerId: Secrets.openciGeneratedAscIssuerId,
    keyId: Secrets.openciGeneratedAscKeyId,
    privateKeyBase64: Secrets.openciGeneratedP8Base64,
  ),
  certificatePrivateKey: Secrets.openciGeneratedIosCertificatePrivateKey,
  flavor: 'dev',
  additionalArguments: ['--dart-define=SAMPLE=Hello World'],
);
```

Here, `Secrets` refers to your workflow's generated secret definitions. Pass the `.p8` file contents as Base64 and the certificate private key as PEM. Each `additionalArguments` item represents one argument, including any spaces in its value. Use build options shared by `flutter build ios` and `flutter build ipa`, such as `--target`, `--dart-define`, and `--build-number`. Signing and export options are managed by `buildIpa()`; do not pass `--no-codesign`, `--export-method`, or `--export-options-plist`.

Use `IosDistributionMethod.appStore` to export an IPA for App Store Connect, including TestFlight. This selects an App Store provisioning profile and generates the corresponding export options. Uploading the IPA to App Store Connect is a separate step.

`buildIpa()` prepares Flutter's release configuration, detects the app's Bundle ID, creates and unlocks a signing Keychain, fetches or creates signing certificates and provisioning profiles, imports the certificates, and applies the profiles to Xcode. It then builds the IPA using the generated ExportOptions.plist and returns the absolute path of the new, nonempty IPA. Missing exports and multiple new IPAs fail the workflow. The `flavor` argument and Flutter's default flavor are respected. Use `dir` to override the workflow's working directory for the whole operation.

Run this on a disposable macOS build VM with Flutter, Xcode and the required iOS components, Codemagic CLI tools, Ruby `xcodeproj`, and the project's CocoaPods dependencies available. This initial integration supports one iOS app project directly under `ios/`; additional app targets and extensions are not provisioned separately. Ad Hoc devices must already be registered in the Apple Developer team. Signing files and the Keychain remain until the VM is deleted. Uploading the IPA to Firebase App Distribution is a separate step.

Upload the IPA to Firebase App Distribution:

```dart
await openCI.flutter.deployIpaToFirebaseAppDistribution(
  ipaPath: ipaPath,
  serviceAccountJsonBase64: Secrets.firebaseServiceAccountJsonBase64,
);
```

Register `FIREBASE_SERVICE_ACCOUNT_JSON_BASE64` in your team's OpenCI secrets with the Base64-encoded contents of a service account JSON key, then run `genuineci sync --secrets` to generate its getter. The service account needs the [Firebase App Distribution Admin role](https://firebase.google.com/docs/app-distribution/authenticate-service-account?platform=ios) on the destination project. Dart uses the key in memory to obtain an OAuth token with `googleapis_auth`; credentials are never written to files or included in commands or logs.

The helper streams the IPA directly to the [Firebase App Distribution REST API](https://firebase.google.com/docs/reference/app-distribution/rest/v1/upload.v1.projects.apps.releases/upload), then polls the returned operation until Firebase finishes processing it. It does not require Node.js or the Firebase CLI. Upload requests time out after 10 minutes, and processing is limited to 5 minutes. Authentication, HTTP, and processing failures fail the workflow without logging raw responses or tokens.

The helper uses macOS `unzip` and `plutil` to read `GOOGLE_APP_ID` from the exported app's `GoogleService-Info.plist`. Pass `appId` explicitly if the IPA does not bundle that file. The project number comes from this Firebase App ID. Relative `ipaPath` values use the workflow directory, or `dir` when specified; the absolute path returned by `buildIpa()` works across working directories.

By default, this only uploads a release. Set `groups` (group aliases) or `testers` (email addresses) to distribute it to testers, and optionally provide `releaseNotes`. The Dashboard workflow only uploads. Actual upload validation requires Firebase credentials and a signed IPA.

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

Command output is always printed to stdout and stderr. OpenCI workers provide `LOKI_URL`, `OPENCI_RUN_ID`, and `OPENCI_BUILD_JOB_ID` to also send structured build logs to Loki. Without `LOKI_URL`, local execution only prints to the terminal.

Log forwarding failures produce a warning and do not change the command's exit status.
