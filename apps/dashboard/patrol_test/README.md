# Dashboard Patrol tests (iOS)

Patrol MCP is configured for Codex in the repository's `.codex/config.toml` as
`patrol_dashboard`. Open this repository (or `apps/dashboard`) as the Codex
project and reload its MCP servers after fetching dependencies:

```sh
cd apps/dashboard
flutter pub get
```

The server resolves the dashboard directory from the current Git checkout, so
the same configuration works in a worktree. It uses `dart` and `flutter` from
your PATH. The startup timeout is 60 seconds and the tool timeout is 30 minutes
to allow the initial iOS build.

The app startup test also requires the normal Dashboard Firebase client
configuration: `lib/firebase_options.dart` and `ios/Runner/GoogleService-Info.plist`.
Provision these as for a regular Dashboard iOS build; they stay outside Git.

## Run through MCP

1. Boot an iOS simulator running iOS 26 or later.
2. Call `devices` and select that simulator's ID.
3. Call `run` with the following arguments, replacing `IOS_SIMULATOR_ID`:

   ```json
   {
     "testFile": "patrol_test/app_startup_test.dart",
     "device": "IOS_SIMULATOR_ID",
     "timeoutMinutes": 20
   }
   ```

4. Inspect the result with `screenshot`, `native-tree`, or `status` as needed.
5. Call `quit` to close the develop session.

Always pass an iOS device ID: MCP otherwise prefers attached Android devices,
and this project currently configures Patrol's native test runner only for iOS.
The MCP `run` timeout defaults to five minutes; use the longer timeout above
for the first build.

## Run without MCP

From `apps/dashboard`, use the CLI resolved alongside `patrol_mcp`:

```sh
dart run patrol_cli:main doctor
dart run patrol_cli:main test --target patrol_test/app_startup_test.dart --device IOS_SIMULATOR_ID
```

## Pull request CI

The `Dashboard iOS Patrol` workflow in `openci/dashboard_ios_patrol_ci.dart`
runs on pull requests targeting any branch when Dashboard or its dependencies
change. It supplies the existing Firebase client configuration from OpenCI
secrets and uses `ci.launchIosSimulator()` from `openci_workflow` on a macOS worker.

The workflow uses the API to create a fresh iPhone 17 Pro simulator with the newest
compatible installed iOS runtime (iOS 26 or later), waits up to ten minutes for its
first boot, then runs `app_startup_test.dart` with `patrol test`. Test failures fail
the CI job. The simulator is shut down and deleted in `finally`, including after
a test failure.
Patrol CLI comes from the project's resolved dependencies.

To run the complete workflow locally, supply the same Firebase client files as
Base64 in `FIREBASE_OPTIONS_DART_BASE64` and
`GOOGLE_SERVICE_INFO_PLIST_BASE64`, then run this from the repository root with
Flutter 3.47.8's Dart on `PATH`:

```sh
dart run openci/dashboard_ios_patrol_ci.dart
```

## Test coverage

`app_startup_test.dart` calls the real Dashboard `main()` entrypoint, including
preferences, localization, Firebase Auth initialization, and routing. It checks
that the signed-out app renders the login form with an enabled sign-in button,
then goes to the iOS home screen and returns to the same login screen. No app
widgets, providers, or platform plugins are mocked.

Run it on a dedicated, newly created iOS simulator, or one where Dashboard is
signed out with the Cloud connection selected. The test does not clear saved
preferences or sign out an existing session. A reused authenticated or
self-hosted session can therefore prevent the expected login screen from
appearing. No credentials or local emulators are needed; successful sign-in and
authenticated dashboard pages are outside this test's scope.

`smoke_test.dart` remains a self-contained Patrol setup check: it taps a Flutter
button, opens the iOS home screen, returns to the app, and checks that state
survived.
Run it by selecting `patrol_test/smoke_test.dart` instead. It does not start
Dashboard or cover its business flows.

The `RunnerUITests` target uses the app's existing Swift Package Manager
integration. Physical iOS devices additionally require signing configuration;
the initial verification uses a simulator.

Generated `test_bundle.dart` / `patrol_test_bundle.dart` files and local
`.patrol.env` files are ignored.

References: [Patrol setup](https://patrol.leancode.co/documentation#ios-setup)
and [Patrol MCP](https://pub.dev/packages/patrol_mcp).
