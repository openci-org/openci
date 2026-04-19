---
description: How to release a new version of the OpenCI Worker CLI (openci_worker_cli)
---

# Worker CLI Release Flow

This workflow covers the full release process for `openci_worker_cli`, including GitHub Release and Firestore auto-update trigger.

## Prerequisites

- Push access to `open-ci-io/openci`
- Dart SDK installed
- SSH access to Hetzner VM (`ssh root@46.225.152.106`)

## Steps

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

### 5. Compile the macOS binary (local)

```bash
cd apps/openci_worker_cli
dart compile exe bin/openci_worker_cli.dart -o openci_worker
```

### 6. Create the macOS release tarball

```bash
mkdir -p /tmp/openci-release
cp openci_worker /tmp/openci-release/openci-worker
cd /tmp/openci-release
tar czf openci-worker-vX.Y.Z-darwin-arm64.tar.gz openci-worker
shasum -a 256 openci-worker-vX.Y.Z-darwin-arm64.tar.gz
```

### 7. Compile the Linux binary (Hetzner VM)

SSH into the Hetzner VM and build from the same tag:

```bash
ssh root@46.225.152.106

# On the VM:
export PATH=/opt/dart-sdk/bin:$PATH
cd /opt/openci-repo
git fetch --tags origin
git checkout vX.Y.Z

# Remove Flutter-dependent packages from workspace for dart-only build
cp pubspec.yaml pubspec.yaml.bak
sed -i '/apps\/dashboard/d; /apps\/landing_page/d' pubspec.yaml
dart pub get

# Compile
cd apps/openci_worker_cli
dart compile exe bin/openci_worker_cli.dart -o /tmp/openci-worker

# Restore pubspec
cd /opt/openci-repo
mv pubspec.yaml.bak pubspec.yaml

# Create tarball
cd /tmp
tar czf openci-worker-vX.Y.Z-linux-x64.tar.gz openci-worker
sha256sum openci-worker-vX.Y.Z-linux-x64.tar.gz
```

### 8. Download Linux tarball to local

```bash
scp root@46.225.152.106:/tmp/openci-worker-vX.Y.Z-linux-x64.tar.gz /tmp/openci-release/
```

### 9. Create Git tag & GitHub Release

```bash
# From the repo root
git tag vX.Y.Z
git push origin vX.Y.Z

gh release create vX.Y.Z \
  /tmp/openci-release/openci-worker-vX.Y.Z-darwin-arm64.tar.gz \
  /tmp/openci-release/openci-worker-vX.Y.Z-linux-x64.tar.gz \
  --title "Worker CLI vX.Y.Z" \
  --notes "## What's New

- Description of changes"
```

> 💡 If `gh` is not in PATH, use `eval "$(/opt/homebrew/bin/brew shellenv)"` first.

### 10. Firestore auto-update (automatic)

> ✅ This step is **automatic**. The GitHub webhook handler (`update_worker_cli_version.dart`) detects the new release, checks that the asset name starts with `openci-worker-`, and updates `config/workerCli.latestVersion` in Firestore automatically.

No manual action needed. Workers will pick up the new version on their next poll cycle (every 1 minute).

## Worker Binary Locations

| Platform | Host | Binary Path | Worker IDs |
|----------|------|-------------|------------|
| macOS (Lume) | Local Mac | `~/bin/openci-worker` | worker-1, worker-2 |
| Linux (Docker) | Hetzner VM `46.225.152.106` | `/usr/local/bin/openci-worker` | ubuntu-1 ~ ubuntu-4 |

The supervisor auto-updater downloads new versions from GitHub Releases (`.tar.gz` archives) and swaps the binary in-place.

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

1. GitHub Release exists with **both** macOS and Linux assets: https://github.com/open-ci-io/openci/releases/tag/vX.Y.Z
2. Firestore updated: check `config/workerCli` document in [Firebase Console](https://console.firebase.google.com/project/openci-b1b91/firestore/databases/-default-/data/~2Fconfig~2FworkerCli)
3. Running workers auto-update on next poll cycle (check worker logs for "New version available" message)
4. Hetzner VM workers: `ssh root@46.225.152.106 "tail -5 /var/log/openci-worker-{1..4}.log"`
