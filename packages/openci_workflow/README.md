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

Build Android APKs and app bundles with an optional product flavor:

```dart
await openCI.flutter.buildApk(flavor: 'staging');
await openCI.flutter.buildAab(flavor: 'production');
```

The `flavor` argument is passed to Flutter's `--flavor` option. Omit it to keep Flutter's default flavor selection. Both methods also accept `dir` to override the workflow's working directory for that call.

Build a signed Ad Hoc IPA with App Store Connect credentials and a separate certificate private key:

```dart
await openCI.flutter.buildIpa(
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

`buildIpa()` prepares Flutter's release configuration, detects the app's Bundle ID, creates and unlocks a signing Keychain, fetches or creates signing certificates and provisioning profiles, imports the certificates, and applies the profiles to Xcode. It then builds the IPA using the generated ExportOptions.plist and checks that a new IPA was exported. The `flavor` argument and Flutter's default flavor are respected. Use `dir` to override the workflow's working directory for the whole operation.

Run this on a disposable macOS build VM with Flutter, Xcode and the required iOS components, Codemagic CLI tools, Ruby `xcodeproj`, and the project's CocoaPods dependencies available. This initial integration supports one iOS app project directly under `ios/`; additional app targets and extensions are not provisioned separately. Ad Hoc devices must already be registered in the Apple Developer team. Signing files and the Keychain remain until the VM is deleted. Uploading the IPA to Firebase App Distribution is a separate step.

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
