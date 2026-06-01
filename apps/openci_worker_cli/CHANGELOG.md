# Changelog

## 0.10.9
- Fix: Check both `~/.local/state` and `~/.local/share` directories for the AOT binary in supervisor.dart on Linux. This resolves the issue where Linux workers failed to reload after an auto-update because `dart install` placed the binary under the `state` directory while supervisor only looked in `share`.

## 0.10.8
- Fix: Add automatic cleanup of zombie `com.apple.Virtualization.VirtualMachine` processes holding locks on macOS VM nvram/disk files, preventing startup timeouts.

## 0.10.7
- Feature: Map ubuntu-latest to the dockerImage in docker_job_executor.dart to run each matrix job in an individual container instead of self-hosted, resolving parallel file write conflicts.

## 0.10.6
- Fix: Dynamically inject env.HOME path based on matrix.name in actions-ci.yaml before running act to prevent parallel write conflicts on self-hosted matrix jobs.

## 0.10.5
- Fix: Export unique HOME directory for each act run to prevent parallel write conflicts on Vite+ installations.

## 0.10.4
- Fix: Mount host's docker.sock inside the runner container in docker_runner.dart to allow 'act' to run jobs in sibling docker containers.

## 0.10.3
- Fix: Prioritize running the AOT binary installed via 'dart install' in supervisor.dart to resolve the old version loading issue on Linux workers.

## 0.10.2
- Fix: Bump avf_dart to 0.1.1 to resolve the native assets (avf_helper) loading failure on AOT-compiled global packages.

## 0.10.1
- Feature: Migrate from 'dart pub global activate' to 'dart install' to support native assets (build hooks) compilation on macOS global installations.

## 0.10.0
- Feature: Unified auto-updater on Mac and Linux via global Dart packages (dart pub global activate)
- Fix: Await _installUpdate call to catch process exceptions properly

## 0.9.22
- Fix: Bump openci_shared to 1.0.1 to resolve strict SDK constraint (allowing execution on Dart SDK >= 3.12)

## 0.9.21
- Fix: Add await to _installUpdate call to properly catch ProcessException inside try-catch

## 0.9.20
- Fix: Resolve version constants to match pubspec.yaml to prevent redundant auto-updates
- Fix: Ensure non-interactive ssh compatibility for worker launch scripts

## 0.9.19
- Ported Node.js worker CLI to Dart
- Migrated from direct Firestore operations to Firebase Functions API (fully removed Firestore dependency)
- Added Firebase Auth credentials support (`--email` and `--password`) to deprecate Google Service Account keys
- Integrated `avf_dart` for macOS Apple Virtualization Framework support

## 0.9.18
- Pass a GitHub event payload to `act` via `-e /tmp/openci-event.json` so workflow expressions like `${{ github.event.pull_request.number }}` resolve correctly (enables Firebase Hosting preview channel deploys on PRs)

## 0.9.17
- Migrate Firestore to Enterprise Edition (`openci-enterprise` database)

## 0.9.16
- Fix: update `openci_shared` dependency to 0.1.1 for `githubBaseUrl` / `githubApiBaseUrl` fields (GitHub Enterprise support)

## 0.9.15
- Fix poison queue: automatically mark jobs with missing `runsOn` as failure instead of silently skipping them, preventing queue blockage

## 0.9.14
- Update base VM image to tahoe-base v1.1.1

## 0.9.13
- Verify auto-update across all environments (Hetzner + macOS)

## 0.9.12
- Verify auto-update via pub.dev in supervised mode

## 0.9.11
- Fix supervisor: detect pub global execution and use `dart pub global run` to spawn child worker, preventing `--service-account` from being misinterpreted as Dart VM flags

## 0.9.10
- Verify automated pub.dev publishing pipeline

## 0.9.9
- Migrate auto-updater from GitHub Releases binary swap to pub.dev `dart pub global activate`
- Simplify supervisor: remove binary swap logic, restart-only
- Add OpenCI CI/CD workflow for automated pub.dev publishing

## 0.9.8
- Require explicit `runs-on` in workflow: macOS worker only processes `macos-*` jobs, no longer claims jobs without `runsOn`

## 0.9.7
- Fix: Ensure Cloud Function notifications complete before rethrowing exceptions in error handler

## 0.9.6
- Fix: Skip dependent jobs when parent job fails (cascade skip via Cloud Function)

## 0.9.5
- Add Worker CLI version to job processing log

## 0.9.3
- Fix: Kill zombie lume VM processes from any worker ID on startup
- Prevents VM slot exhaustion when orphaned processes outlive their worker

## 0.9.2
- Extract AI failure summary into standalone Cloud Function (`generate-failure-summary`)
- Worker now calls `generate-failure-summary` independently after build failures
- Fix: AI summaries were not generated due to `unawaited` fire-and-forget in previous architecture

## 0.9.1
- Implement supervisor architecture for auto-updates and crash recovery
- Add `--supervised` flag for process supervisor mode
- Unify auto-updater for macOS/Linux via GitHub Releases
- Add semver comparison to prevent downgrades
