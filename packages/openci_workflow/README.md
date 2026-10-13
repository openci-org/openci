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

Create a Shorebird Android release and receive its App Bundle path:

```dart
if (Secrets.shorebirdToken.isEmpty) {
  throw StateError('SHOREBIRD_TOKEN must not be empty.');
}

final aabPath = await openCI.shorebird.releaseAab(
  flutterVersion: '3.47.7',
  flavor: 'production',
  dartDefines: {'ENV': 'production'},
  additionalArguments: ['--build-number=42'],
);
```

Install the [Shorebird CLI](https://docs.shorebird.dev/code-push/ci/github/), Java, and the Android SDK on the build machine. Initialize the app with `shorebird init` and commit `shorebird.yaml`. Register `SHOREBIRD_TOKEN` in OpenCI Secrets, run `genuineci sync --secrets`, and reference `Secrets.shorebirdToken` in the workflow so the worker injects it. Configure Android release signing in Gradle and restore its keystore and properties from your secrets before calling the helper, as with `buildAab()`. The project's Gradle configuration determines the signing identity.

`releaseAab()` runs `shorebird release android --artifact aab` with the required `flutterVersion`. Pass `flavor` explicitly for flavored Shorebird apps. `dir` overrides the workflow directory. `dartDefines` and each literal argument in `additionalArguments` are forwarded to Flutter after `--`; artifact type, flavor, and release build mode are managed by the helper.

The returned path is the single nonempty `.aab` in `build/app/outputs/bundle/release`, or `build/app/outputs/bundle/<flavor>Release` when a flavor is supplied. This follows Shorebird's standard Android output layout. A successful incremental Gradle build may reuse an existing bundle. A failed command, missing bundle, or multiple nonempty bundles fails the workflow.

By default, the command [registers the release with Shorebird](https://docs.shorebird.dev/code-push/release/). Set `dryRun: true` to build and validate without registering it. Authentication and an unused version/build number are required even for dry runs. Pass the returned `aabPath` to `deployAabToPlayConsole()` or `deployAabToFirebaseAppDistribution()` when ready to upload it.

Create a Shorebird Android release and receive its APK path:

```dart
if (Secrets.shorebirdToken.isEmpty) {
  throw StateError('SHOREBIRD_TOKEN must not be empty.');
}

final apkPath = await openCI.shorebird.releaseApk(
  flutterVersion: '3.47.7',
  flavor: 'production',
  dartDefines: {'ENV': 'production'},
  additionalArguments: ['--build-number=42'],
);
```

Use the same CLI, Android SDK, token, and Gradle release-signing setup as `releaseAab()`. `releaseApk()` runs `shorebird release android --artifact apk`, which builds both an AAB and a universal APK. `flutterVersion`, `dir`, `flavor`, `dartDefines`, `additionalArguments`, and `dryRun` work as in `releaseAab()`. Shorebird does not support `--split-per-abi`, so the helper rejects it.

The returned absolute path is `build/app/outputs/flutter-apk/app-release.apk`, or `app-<lowercased-flavor>-release.apk` in that directory when a flavor is supplied. The helper requires this standard filename and a nonempty APK after a successful command; it does not select APKs from other flavors or build modes. A successful incremental Gradle build may reuse an existing APK. Set `dryRun: true` with an unused version/build number to build without registering a release. Pass the returned `apkPath` to `deployApkToFirebaseAppDistribution()` when ready to upload it.

Upload a built APK to Firebase App Distribution:

```dart
await openCI.flutter.deployApkToFirebaseAppDistribution(
  apkPath: 'build/app/outputs/flutter-apk/app-release.apk',
  appId: '1:123456789:android:abcdef',
  serviceAccountJsonBase64: Secrets.firebaseServiceAccountJsonBase64,
);
```

Pass the Android Firebase App ID from your Firebase project settings or the matching client's `client_info.mobilesdk_app_id` in `google-services.json`. Pass the Base64-encoded service account JSON key from your CI secrets; the account needs the [Firebase App Distribution Admin role](https://firebase.google.com/docs/app-distribution/authenticate-service-account?platform=android). Credentials stay in memory. Relative `apkPath` values use the workflow directory, or `dir` when specified.

The helper streams the APK to the [Firebase App Distribution REST API](https://firebase.google.com/docs/reference/app-distribution/rest/v1/upload.v1.projects.apps.releases/upload) and waits for processing to finish. Authentication is limited to 60 seconds, upload to 10 minutes, and processing to 5 minutes. Missing or empty APKs, invalid App IDs, authentication failures, and upload or processing errors fail the workflow. This API uploads the release without distributing it to testers.

Upload a built Android App Bundle to Firebase App Distribution:

```dart
await openCI.flutter.deployAabToFirebaseAppDistribution(
  aabPath: 'build/app/outputs/bundle/release/app-release.aab',
  appId: '1:123456789:android:abcdef',
  serviceAccountJsonBase64: Secrets.firebaseServiceAccountJsonBase64,
);
```

AAB uploads require the [Google Play integration](https://firebase.google.com/docs/app-distribution/android/distribute-cli?apptype=aab): link the Firebase project to Google Play, use the same package name for both apps, complete the Play app review, publish the app to a testing or production track, and accept the internal app sharing terms. An unreviewed internal-test release does not satisfy these requirements. The helper checks Firebase's AAB integration status before sending the file and reports setup problems. If Play's status is temporarily unavailable, it attempts the upload as the Firebase CLI does.

Pass the Android Firebase App ID and Base64-encoded service account JSON as in the APK example. Relative `aabPath` values use the workflow directory, or `dir` when specified. Authentication is limited to 60 seconds, the integration check to 30 seconds, upload to 10 minutes, and processing to 5 minutes. The helper streams the AAB, waits for processing to complete, and uploads the release without distributing it to testers.

Upload an AAB to Google Play Console:

```dart
await openCI.flutter.deployAabToPlayConsole(
  aabPath: 'build/app/outputs/bundle/release/app-release.aab',
  packageName: 'com.example.app',
  serviceAccountJsonBase64: Secrets.googlePlayServiceAccountJsonBase64,
);
```

Use the Android `applicationId` as `packageName`. Register `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON_BASE64` in your team's CI secrets, generate its getter with `genuineci sync --secrets`, and import `generated/secrets.g.dart` in your workflow. [Enable the Google Play Developer API and grant the service account access in Play Console](https://developers.google.com/android-publisher/getting_started). The account needs permission to view the app and release to the selected track; Firebase permissions alone are insufficient. Set up the app and upload its first build through Play Console before using this API. Sign the AAB with the app's accepted upload key and use a new version code.

The helper defaults to `track: 'internal'` and a completed release. Pass another existing track ID to target a different track, or `draft: true` to save a draft, including for apps that are still in draft state. The selected track is updated with a single new AAB, replacing its previous release; staged rollouts are not supported. Relative paths use the workflow directory, or `dir` when specified. Credentials stay in memory and file uploads are streamed.

The helper creates a Google Play edit, uploads the artifact, updates the track, then commits the edit. Success means Google accepted the edit; it does not wait for app review or managed publishing, or guarantee the release is already available to testers. Commits use [`ERROR_IF_IN_REVIEW`](https://developers.google.com/android-publisher/api-ref/rest/v3/edits/commit) so an existing review is not cancelled. Failed operations attempt to discard their uncommitted edit. Authentication and metadata requests time out after 60 seconds; uploads after 10 minutes. If a commit times out or its response is lost, check Play Console before retrying, as Google may already have accepted it. Run one deployment per app at a time: [a new edit or a Play Console change can invalidate an in-progress edit](https://developers.google.com/android-publisher/edits).

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

Create a Shorebird iOS release with the same signing credentials:

```dart
if (Secrets.shorebirdToken.isEmpty) {
  throw StateError('SHOREBIRD_TOKEN must not be empty.');
}

final ipaPath = await openCI.shorebird.releaseIos(
  bundleId: 'org.example.app.prod',
  distributionMethod: IosDistributionMethod.appStore,
  ascKeys: AppStoreConnectKeys(
    issuerId: Secrets.openciGeneratedAscIssuerId,
    keyId: Secrets.openciGeneratedAscKeyId,
    privateKeyBase64: Secrets.openciGeneratedP8Base64,
  ),
  certificatePrivateKey: Secrets.openciGeneratedIosCertificatePrivateKey,
  flutterVersion: '3.47.7',
  flavor: 'prod',
  dartDefines: {'ENV': 'production'},
  additionalArguments: ['--build-number=42'],
);
```

Install the [Shorebird CLI](https://docs.shorebird.dev/code-push/ci/github/) on the disposable macOS VM and make it available on the workflow's noninteractive shell PATH. The same Xcode, Codemagic CLI tools, Ruby `xcodeproj`, CocoaPods, and single-app signing requirements as `buildIpa()` apply. Initialize the app with `shorebird init` beforehand and commit `shorebird.yaml`. When using flavors, configure the matching Shorebird apps and pass `flavor` explicitly. Set `bundleId` to the selected flavor's iOS app identifier so the helper can fetch its signing files before building.

Register a Shorebird API key as `SHOREBIRD_TOKEN` in OpenCI Secrets and run `genuineci sync --secrets` to generate its accessor. Reference `Secrets.shorebirdToken` in the workflow, as above: OpenCI only injects secrets referenced by the workflow, so registering the key alone is not enough. The worker supplies this environment variable to the CLI; the helper does not put its value in the command or require a token argument. Authentication is also required for dry runs.

`flutterVersion` is required: use a version or revision supported by Shorebird for your project. The helper runs `shorebird release ios`, which builds using its selected Flutter SDK; no separate system Flutter command runs beforehand. `dir` overrides the workflow directory. `dartDefines` and `additionalArguments` are passed to the release build. Each additional argument is one literal shell argument, forwarded to Flutter after `--`. The helper manages signing, export options, flavor, and release build mode, and rejects overrides of those options.

By default, this builds a signed IPA and [registers the release with Shorebird](https://docs.shorebird.dev/code-push/release/). Use a new app version/build number for each release. Set `dryRun: true` to build and validate without uploading to Shorebird. Dry runs also check for an existing release, so use an unused version/build number. The helper disables Xcode's automatic version/build-number management in ExportOptions.plist so the exported IPA matches the version recorded by Shorebird.

Success requires exactly one newly exported, nonempty IPA; its absolute path is returned. A nonzero CLI exit, failed export, or ambiguous IPA fails the workflow. If Shorebird registered the release before a later export/upload error, check the console before retrying the same version. Signing files and the Keychain remain until the VM is deleted. Uploading the IPA to TestFlight or Firebase App Distribution is a separate call.

To upload to TestFlight, build the IPA with `IosDistributionMethod.appStore`, then pass the returned path:

```dart
await openCI.flutter.deployIpaToTestFlight(
  ipaPath: ipaPath,
  ascKeys: AppStoreConnectKeys(
    issuerId: Secrets.openciGeneratedAscIssuerId,
    keyId: Secrets.openciGeneratedAscKeyId,
    privateKeyBase64: Secrets.openciGeneratedP8Base64,
  ),
);
```

The helper uses the [App Store Connect Build Upload API](https://developer.apple.com/documentation/appstoreconnectapi/build-uploads). Provide a team API key with access to the app and build uploads. It reads the Bundle ID, version, and build number from the IPA's app-level `Info.plist` using macOS `unzip` and `plutil`, and finds the matching App Store Connect app. Relative `ipaPath` values use the workflow directory, or `dir` when specified. Private keys and signed API tokens stay in memory.

The IPA is streamed in the byte ranges requested by Apple. API requests have a 60-second timeout, and binary transfer is limited to 20 minutes. After committing the uploaded file, the helper polls that specific build upload every 15 seconds until its state is `COMPLETE`. A successful file transfer alone does not finish the workflow. Failed processing, invalid responses, HTTP errors, and timeouts fail the workflow without logging tokens or signed upload URLs.

Processing is limited to 30 minutes by default; override `processingTimeout` for a longer wait. Timing out does not cancel Apple's processing, so check the existing upload before retrying. The helper does not assign tester groups or submit external beta review; existing automatic distribution settings in App Store Connect still apply. Export compliance and beta review may require further action before testers can install the build.

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
