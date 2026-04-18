---
description: How to release a new version of the OpenCI Worker CLI (openci_worker_cli)
---

# Worker CLI Release Flow

This workflow covers the full release process for `openci_worker_cli`, including GitHub Release, Homebrew tap update, and Firestore auto-update trigger.

## Prerequisites

- Push access to `open-ci-io/openci` and `open-ci-io/homebrew-tap`
- `gh` CLI authenticated (`gh auth status`)
- Dart SDK installed

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

### 3. Commit & push

```bash
git add apps/openci_worker_cli/
git commit -m 'chore: release openci_worker_cli vX.Y.Z'
git push origin develop
```

### 4. Compile the binary

```bash
cd apps/openci_worker_cli
dart compile exe bin/openci_worker_cli.dart -o openci_worker
```

### 5. Create the release tarball

```bash
mkdir -p /tmp/openci-release
cp openci_worker /tmp/openci-release/openci-worker
cd /tmp/openci-release
tar czf openci-worker-vX.Y.Z-darwin-arm64.tar.gz openci-worker
shasum -a 256 openci-worker-vX.Y.Z-darwin-arm64.tar.gz
```

Save the sha256 hash — you'll need it for the Homebrew formula.

### 6. Create Git tag & GitHub Release

```bash
# From the repo root
git tag vX.Y.Z
git push origin vX.Y.Z

gh release create vX.Y.Z /tmp/openci-release/openci-worker-vX.Y.Z-darwin-arm64.tar.gz \
  --title "Worker CLI vX.Y.Z" \
  --notes "## What's New

- Description of changes"
```

### 7. Update Homebrew formula

Update `Formula/openci-worker.rb` in the `open-ci-io/homebrew-tap` repo:

- `version` → `"X.Y.Z"`
- `url` → `"https://github.com/open-ci-io/openci/releases/download/vX.Y.Z/openci-worker-vX.Y.Z-darwin-arm64.tar.gz"`
- `sha256` → the hash from step 5

This can be done via the GitHub API or by cloning the repo and pushing.

### 8. Firestore auto-update (automatic)

> ✅ This step is **automatic**. The GitHub webhook handler (`update_worker_cli_version.dart`) detects the new release, checks that the asset name starts with `openci-worker-`, and updates `config/workerCli.latestVersion` in Firestore automatically.

No manual action needed. Workers will pick up the new version on their next poll cycle.

## Verification

After completing all steps, verify:

1. GitHub Release exists: https://github.com/open-ci-io/openci/releases/tag/vX.Y.Z
2. Homebrew formula updated: `brew update && brew info openci-worker` shows new version
3. Firestore updated: check `config/workerCli` document in [Firebase Console](https://console.firebase.google.com/project/openci-b1b91/firestore/databases/-default-/data/~2Fconfig~2FworkerCli)
4. Running workers auto-update on next poll cycle (check worker logs for "New version available" message)

