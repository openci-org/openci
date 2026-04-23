---
description: How to release a new version of the OpenCI Worker CLI (openci_worker_cli)
---

# Worker CLI Release Flow

This workflow covers the full release process for `openci_worker_cli` via pub.dev automated publishing using OpenCI.

## Prerequisites

- Push access to `openci-org/openci`
- Dart SDK installed
- `PUB_CREDENTIALS` secret registered in GCP Secret Manager (already done)

## Release Steps

### 1. Bump version numbers

Update the version in **both** files:

- `apps/openci_worker_cli/pubspec.yaml` → `version: X.Y.Z`
- `apps/openci_worker_cli/lib/constants.dart` → `const version = 'X.Y.Z';`

> ⚠️ These two must always match. `pubspec.yaml` is used by pub.dev, `constants.dart` is used at runtime for the auto-update check.

### 2. Update CHANGELOG.md

Add a new entry at the top of `apps/openci_worker_cli/CHANGELOG.md`:

```markdown
## X.Y.Z
- Description of changes
```

### 3. Analyze

```bash
// turbo
cd apps/openci_worker_cli
dart analyze
```

### 4. Commit & push

```bash
git add apps/openci_worker_cli/
git commit -m 'chore: release openci_worker_cli vX.Y.Z'
git push origin develop
```

### 5. Create Git tag & push

```bash
git tag worker-vX.Y.Z
git push origin worker-vX.Y.Z
```

This triggers the OpenCI workflow `.openci/publish-worker-cli.yaml`, which:
1. Restores `PUB_CREDENTIALS` from Secret Manager
2. Sets up `~/.config/dart/pub-credentials.json`
3. Runs `dart pub publish --force`

### 6. Create GitHub Release (optional)

```bash
gh release create worker-vX.Y.Z \
  --title "Worker CLI vX.Y.Z" \
  --notes "## What's New

- Description of changes"
```

> 💡 If `gh` is not in PATH, use `eval "$(/opt/homebrew/bin/brew shellenv)"` first.

### 7. Verify publication

1. Check OpenCI dashboard for build status
2. Check pub.dev: https://pub.dev/packages/openci_worker_cli
3. Running workers will auto-update via `dart pub global activate` on next poll cycle (every 1 minute)

## Releasing openci_shared

If `openci_shared` needs to be updated:

1. Bump version in `packages/openci_shared/pubspec.yaml`
2. Update `packages/openci_shared/CHANGELOG.md`
3. **Also update** `openci_worker_cli/pubspec.yaml` to reference the new version: `openci_shared: ^X.Y.Z`
4. Commit & push
5. Tag & push: `git tag shared-vX.Y.Z && git push origin shared-vX.Y.Z`
6. Wait for pub.dev to index the new version before publishing worker CLI

## Worker Installation

Workers are now installed and updated via `dart pub global activate`:

```bash
# Install
dart pub global activate openci_worker_cli

# Run
openci-worker --project-id=<ID> --service-account=<path>
```

## Worker Locations

| Platform | Host | How to run | Worker IDs |
|----------|------|------------|------------|
| macOS (Lume) | Local Mac | `dart pub global activate openci_worker_cli` | worker-1, worker-2 |
| Linux (Docker) | Hetzner VM `46.225.152.106` | `dart pub global activate openci_worker_cli` | ubuntu-1 ~ ubuntu-4 |

The supervisor monitors the worker process and restarts it after `dart pub global activate` updates the package.

## Hetzner VM Access

```bash
# SSH
ssh root@46.225.152.106

# View workers
tmux attach -t openci-workers

# View logs
tail -f /var/log/openci-worker-1.log

# Service account location
/etc/openci/sa.json

# Docker image
openci-ubuntu:latest  (Dockerfile at /opt/openci/Dockerfile)

# Dart SDK
/opt/dart-sdk/bin/dart
```

## Verification

After completing all steps, verify:

1. OpenCI build succeeded on the dashboard
2. Package published on pub.dev: https://pub.dev/packages/openci_worker_cli/versions
3. Running workers auto-update on next poll cycle (check worker logs for "Update installed" message)
4. Hetzner VM workers: `ssh root@46.225.152.106 "tail -5 /var/log/openci-worker-{1..4}.log"`
