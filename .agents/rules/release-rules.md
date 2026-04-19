---
globs:
alwaysApply: true
---

# GitHub Release Rules

## Release Title Format

All GitHub releases MUST follow a consistent naming convention:

<Component Name> v<version>

Examples:

- Worker CLI v0.9.9
- Dashboard v1.5.0
- Web v0.4.0
- Firebase Functions v1.0.0

Do NOT use bare version tags like v0.7.16 as the release title.

## Release Notes Format

Release notes MUST include a ## What's New section with a bulleted list of changes.

## Tag Naming

- Worker CLI: worker-v<version> (e.g., worker-v0.9.9) — triggers OpenCI publish to pub.dev
- Shared Package: shared-v<version> (e.g., shared-v0.1.1) — triggers OpenCI publish to pub.dev
- Dashboard: dashboard/v<version> (e.g., dashboard/v1.5.0)
- Web: web/v<version> (e.g., web/v0.4.0)
- Firebase Functions: functions/v<version> (e.g., functions/v1.0.0)

## Worker CLI Release Checklist

1. Update version in apps/openci_worker_cli/pubspec.yaml
2. Update version constant in apps/openci_worker_cli/lib/constants.dart
3. Update CHANGELOG.md
4. Run dart analyze on the worker CLI
5. Commit and push to develop
6. Tag with `worker-vX.Y.Z` and push — OpenCI auto-publishes to pub.dev
7. (Optional) Create GitHub Release for changelog visibility
