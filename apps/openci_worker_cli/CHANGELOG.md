# Changelog

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
