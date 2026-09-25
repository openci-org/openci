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

## v2.0.0 device enrollment

Automatic iOS device enrollment is disabled for both Cloud and self-hosted
deployments. `GET` and `POST /devices/mobile-config` return `410 Gone`, including
callbacks from previously downloaded profiles. Dashboard Hosting no longer
forwards `/enroll-udid` or `/register-device` to enrollment functions.

Existing authenticated device listing and deletion remain available. Enrollment
can be re-enabled after user/team authorization and a server-issued callback
credential bound to each enrollment are implemented.
