GenuineCI command-line tools.

Run `genuineci dev start` from the OpenCI checkout to start local services and the
Mac Orchard worker. The existing Docker Compose credentials and `base-macos` VM
must be configured first.

The command starts Orchard Controller and the Mac worker first. When restarting,
it stops the old build-job-worker and waits for all running jobs to finish while
the server remains available for saving results and deleting their VMs. It then
rebuilds and starts the application containers.

The `/internal` seed and cleanup API is disabled by default. `genuineci dev start`
automatically enables it by passing `ENABLE_INTERNAL_API=true` to Docker Compose.

To also queue the default smoke-test build job:

```sh
genuineci dev start --seed
```

The server seeds `test-team` and one `macos-latest` job for
`openci-org/openci`'s `genuine_ci/worker_smoke.dart`, pinned to commit
`b6ab255a62ca0c5216ec67c4b251c7b1732bd290` on `test/build-job-worker-smoke`.
The workflow checks macOS and Flutter versions and runs the worker's unit tests.
It uses this fixed fixture, not uncommitted files in your local checkout.

The server resolves the installation ID using the GitHub App already configured
in Docker Compose. That App must have access to `openci-org/openci`.
Webhook reception and planning are separate from this smoke test.

Press Ctrl+C to stop the Mac Orchard worker. Docker containers keep running.

After seeding, log in from another terminal:

```sh
genuineci login --local
```

This reads the API key from the running `genuineci-server` container, authenticates
with `http://localhost:8080`, and selects `test-team`. After the server confirms
the team, it saves and activates the `local` credential profile. Failed login
attempts leave existing credentials unchanged.

Then generate typed secret definitions from your workflow project:

```sh
genuineci sync secrets
```

The command uses the active credential profile and finds the nearest ancestor
containing a `genuine_ci` directory, starting from the current directory. It
replaces `genuine_ci/secrets.g.dart` with getters that read environment variables
at workflow runtime. Secret values are never downloaded or written to this file.
Run it again after adding or removing secrets. Fetch or generation failures leave
the existing file unchanged.

Generate typed workspace paths without logging in or starting local services:

```sh
genuineci sync paths
```

Run this from your workflow project or one of its subdirectories. The command
reads the `workspace` list in the root `pubspec.yaml` and each listed package's
`name`, then writes `genuine_ci/paths.g.dart` following the directory hierarchy.
For example, `apps/build_job_worker` becomes
`WorkspacePaths.root.apps.buildJobWorker`. Directory names determine the getters;
package names are used to validate the workspace. Run it again after adding,
moving or renaming workspace directories. Read or generation failures preserve
the existing file.

Import the generated file in your workflow and run it from the repository root,
as the worker does, because these paths are relative to that root:

```dart
import 'paths.g.dart';

await FlutterCi.staticAnalysis(WorkspacePaths.root.apps.dashboard);
```

`WorkspacePaths.root` represents `.` and `WorkspacePaths.root.apps` represents
`apps`. Both can also be passed directly to methods accepting a `String` path.
