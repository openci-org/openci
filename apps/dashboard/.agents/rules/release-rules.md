---
trigger: always_on
---

# GitHub Release Rules

## Release Title Format

All GitHub releases MUST follow a consistent naming convention:

<Component Name> v<version>

Examples:

- Worker CLI v0.7.16
- Dashboard v1.5.0
- Web v0.4.0
- Firebase Functions v1.0.0

Do NOT use bare version tags like v0.7.16 as the release title.

## Release Notes Format

Release notes MUST include a ## What's New section with a bulleted list of changes.

## Tag Naming

- Worker CLI: worker-node-v<version> (e.g., worker-node-v0.1.14)
- Dashboard: dashboard/v<version> (e.g., dashboard/v1.5.0)
- Web: web/v<version> (e.g., web/v0.4.0)
- Firebase Functions: functions/v<version> (e.g., functions/v1.0.0)

## Worker CLI Release Checklist

1. Update version in `apps/worker_cli_node/package.json` and `apps/worker_cli_node/package-lock.json` (prefer `npm version X.Y.Z --no-git-tag-version` from `apps/worker_cli_node`).
2. Run `npm run check`, `npm run build`, and `npm run pack:dry-run` in `apps/worker_cli_node`.
3. Commit and push to develop.
4. Publish from `apps/worker_cli_node` with `npm publish`.
5. Tag with `worker-node-vX.Y.Z` and push for release traceability.
6. (Optional) Create GitHub Release for changelog visibility.
