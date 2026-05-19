# Flutter Pub Cache

GitHub Action for restoring and saving Flutter pub cache archives in Firebase Storage or Google Cloud Storage.

This action is useful when GitHub Actions cache storage is not a good fit, for example when cache size, retention, or cross-runner behavior needs to be controlled by your own storage bucket.

## Usage

```yaml
- uses: actions/checkout@v4

- name: Restore Flutter pub cache
  uses: ./actions/flutter-pub-cache
  with:
    action: restore
    service-account: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
    storage-bucket: my-project.firebasestorage.app

- run: flutter pub get
  working-directory: apps/dashboard

- name: Save Flutter pub cache
  if: always()
  uses: ./actions/flutter-pub-cache
  with:
    action: save
    service-account: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
    storage-bucket: my-project.firebasestorage.app
```

From another public repository, use the subdirectory action path and pin an
OpenCI commit SHA:

```yaml
- name: Restore Flutter pub cache
  uses: openci-org/openci/actions/flutter-pub-cache@<commit-sha>
  with:
    action: restore
    service-account: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
    storage-bucket: my-project.firebasestorage.app
```

You can also read the bucket from a Firebase options file instead of passing `storage-bucket` directly.

```yaml
with:
  action: restore
  service-account: ${{ secrets.FIREBASE_SERVICE_ACCOUNT }}
  firebase-options-path: apps/dashboard/lib/firebase_options.dart
```

## Inputs

| Input                   | Default                     | Description                                                                                                                                                 |
| ----------------------- | --------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `action`                | required                    | `restore` or `save`.                                                                                                                                        |
| `service-account`       | empty                       | Google service account JSON. Falls back to `FIREBASE_SERVICE_ACCOUNT`.                                                                                      |
| `storage-bucket`        | empty                       | Bucket name. If omitted, `storageBucket` is read from `firebase-options-path`.                                                                              |
| `firebase-options-path` | `lib/firebase_options.dart` | Firebase options file containing `storageBucket`.                                                                                                           |
| `cache-path`            | `~/.pub-cache`              | Pub cache directory to archive.                                                                                                                             |
| `key-prefix`            | `caches/flutter-pub`        | Storage object prefix.                                                                                                                                      |
| `dependency-paths`      | auto-detect                 | Optional newline-delimited file or glob patterns used to compute the dependency hash. When omitted, the action scans for `pubspec.yaml` and `pubspec.lock`. |
| `working-directory`     | `.`                         | Base directory for dependency paths and `firebase-options-path`.                                                                                            |
| `repository`            | current repository          | Repository component used in the storage object name.                                                                                                       |
| `fail-on-error`         | `false`                     | Fail the workflow when restore or save fails. Usage errors still fail regardless of this setting.                                                           |

## Outputs

| Output        | Description                                            |
| ------------- | ------------------------------------------------------ |
| `cache-hit`   | `true` when restore downloaded an archive.             |
| `cache-saved` | `true` when save uploaded a new archive.               |
| `object-name` | Google Cloud Storage object name used for the archive. |

## Cache Key

The object name is built from:

- `key-prefix`
- repository
- host OS and architecture
- Flutter and Dart SDK versions
- a dependency hash from auto-detected `pubspec.yaml` and `pubspec.lock` files, or from `dependency-paths` when provided
- archive extension, preferring zstd when available

Existing cache objects are immutable. `save` skips upload when the object already exists.

## Permissions

The service account needs permission to read and write objects in the selected bucket.
