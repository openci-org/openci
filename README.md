# OpenCI

[![codecov](https://codecov.io/gh/openci-org/openci/graph/badge.svg?token=RAJBUMJU3O)](https://codecov.io/gh/openci-org/openci)

Open this repository in VS Code with `openci.code-workspace`. The root
`pubspec.yaml` lists the Dart workspace packages, including the `openci_cli`,
`openci_server`, and `openci_workflow` packages. Repository workflow definitions
live in `openci/`; the CLI discovers the same directory in user projects.

Install dependencies and run the workspace checks from the repository root:

```sh
flutter pub get
vp i --frozen-lockfile
vp run -r check
vp run -r fmt:check
git ls-files -z '*.dart' | xargs -0 dart format --output=none --set-exit-if-changed
```

Run `dart analyze` and `dart test` from each Dart package directory. For the
Dashboard and other Flutter packages, use `flutter analyze` and `flutter test`.
The worker sets `OPENCI_RUN_ID` and `OPENCI_BUILD_JOB_ID` for workflow processes;
the workflow SDK also reads `OPENCI_STEP_ID` when a step supplies one.

For workflow authoring and local development commands, see the
[CLI guide](apps/openci_cli/README.md).
