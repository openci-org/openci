# OpenCI

[![codecov](https://codecov.io/gh/openci-org/openci/graph/badge.svg?token=RAJBUMJU3O)](https://codecov.io/gh/openci-org/openci)

## Dart formatting CI

The `Dart Format Check` workflow runs on pull requests to any branch and pushes
to `develop` when Dart files or formatting-related configuration changes. It
uses Flutter 3.44.8 / Dart 3.12.2 so formatter output stays consistent.

The workflow calls `openCI.dart.checkFormat()` to check tracked and non-ignored
new Dart files throughout the repository without rewriting them. Formatting
differences fail the check; ignored build outputs and downloaded packages are
excluded.

Run it locally from the repository root with the same Flutter release:

```sh
flutter pub get
dart run openci/dart_format_check.dart
```

Use `dart format <file paths>` to fix any reported formatting differences.
