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

## Run through MCP

1. Boot an iOS simulator running iOS 26 or later.
2. Call `devices` and select that simulator's ID.
3. Call `run` with the following arguments, replacing `IOS_SIMULATOR_ID`:

   ```json
   {
     "testFile": "patrol_test/smoke_test.dart",
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
dart run patrol_cli:main test --target patrol_test/smoke_test.dart --device IOS_SIMULATOR_ID
```

`smoke_test.dart` is a self-contained setup check: it taps a Flutter button,
opens the iOS home screen, returns to the app, and checks that state survived.
It does not sign in, call a backend, or cover dashboard business flows. Add
those scenarios as separate Patrol tests once this setup check passes.

The `RunnerUITests` target uses the app's existing Swift Package Manager
integration. Physical iOS devices additionally require signing configuration;
the initial verification uses a simulator.

Generated `test_bundle.dart` / `patrol_test_bundle.dart` files and local
`.patrol.env` files are ignored.

References: [Patrol setup](https://patrol.leancode.co/documentation#ios-setup)
and [Patrol MCP](https://pub.dev/packages/patrol_mcp).
