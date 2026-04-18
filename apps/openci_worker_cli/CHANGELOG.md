# Changelog

## 0.9.2
- Extract AI failure summary into standalone Cloud Function (`generate-failure-summary`)
- Worker now calls `generate-failure-summary` independently after build failures
- Fix: AI summaries were not generated due to `unawaited` fire-and-forget in previous architecture

## 0.9.1
- Implement supervisor architecture for auto-updates and crash recovery
- Add `--supervised` flag for process supervisor mode
- Unify auto-updater for macOS/Linux via GitHub Releases
- Add semver comparison to prevent downgrades
