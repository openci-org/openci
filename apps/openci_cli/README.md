OpenCI command-line tools.

Log in to a remote server with the same email and password as the dashboard:

```sh
openci login
```

The default server is `https://openci-worker-01.tail4beb18.ts.net`.
To connect to another server, pass the optional `--server <url>` option.

Enter your email and password at the prompts. The password is hidden and is only
sent to Firebase Authentication; it is never saved. After the server confirms
your team membership, the CLI saves and activates the `remote` credential
profile, keeping the `local` profile. Failed login attempts preserve existing
credentials.

If you belong to multiple teams, specify `--team-id <id>` using the displayed
list. For a self-hosted Firebase project, also pass its Web API key with
`--firebase-api-key <key>`; the default is the dashboard's `openci-b1b91` project.
The remote server URL must use HTTPS.

Secret commands use this profile and automatically refresh expiring Firebase ID
tokens. Credentials, including the refresh token, are stored in the `openci`
application config directory with owner-only permissions on macOS/Linux. If you
previously used `genuineci`, log in again; its credentials are not migrated.

List secret names for the active profile's team:

```sh
openci list secrets
```

Names are printed one per line, sorted by name, without secret values. If the
team has no secrets, the command prints a message and exits successfully. It
works from any directory, supports redirected output, and does not generate
workflow files. Control characters in names are displayed as escaped text.

Register a secret for the active profile's team:

```sh
openci register secret
```

Enter the secret name (for example, `API_TOKEN`), then its value in an interactive
terminal. The value is hidden while typing. After you press Enter, the prompt
shows `******`, regardless of the value's length.

Registering an existing name updates its value. The CLI uses the dashboard's
existing API, which trims leading and trailing whitespace from values. Values
are not printed or saved locally. Firebase tokens are refreshed when needed.
After adding a secret, run `openci sync secrets` from your workflow project
to update its generated secret definitions.

Register a file as a Base64 secret:

```sh
openci register secretFile
```

Type a file path to filter the displayed candidates. Press Tab or the up/down
arrow keys to complete a candidate, then Enter to enter a folder or select a
file. Relative paths, absolute paths, `~/`, spaces, and Unicode filenames are
supported. Type `.` to include hidden files such as `.env`. Press Esc or Ctrl+C
to cancel. The picker requires an interactive terminal with ANSI support.

The selected file is read as bytes and Base64-encoded. Its basename, including
the extension, is uppercased, runs of characters other than letters, digits and
underscores become `_`, and `_BASE64` is appended. Names beginning with a digit
are prefixed with `_`. For example, `google-services.json` becomes
`GOOGLE_SERVICES_JSON_BASE64`. Selecting an existing name updates that secret.
Empty files are rejected. Neither the file contents nor the encoded value is
printed or saved locally. Run `openci sync secrets` afterwards to update the
generated definitions.

Run `openci dev start` from the OpenCI checkout to start local services and the
Mac Orchard worker. The existing Docker Compose credentials and `base-macos` VM
must be configured first.

The command starts Orchard Controller and the Mac worker first. When restarting,
it stops the old build-job-worker and waits for all running jobs to finish while
the server remains available for saving results and deleting their VMs. It then
rebuilds and starts the application containers.

The `/internal` seed and cleanup API is disabled by default. `openci dev start`
automatically enables it by passing `ENABLE_INTERNAL_API=true` to Docker Compose.
Requests also require `INTERNAL_API_KEY`. Export the same key configured for the
server before using `--seed` or the seed/cleanup scripts in `tool/`; a key stored
only in Docker Compose's `.env` file is not available to these local processes.

To also queue the default smoke-test build job:

```sh
openci dev start --seed
```

The server seeds `test-team` and one `macos-latest` job for
`openci-org/openci`'s `openci/worker_smoke.dart`, pinned to commit
`5cb05f76d8941ea1edc3593eb753ce808f0f290e` on
`test/build-job-worker-smoke-openci`.
The workflow checks macOS and Flutter versions and runs the worker's unit tests.
It uses this fixed fixture, not uncommitted files in your local checkout.

The server resolves the installation ID using the GitHub App already configured
in Docker Compose. That App must have access to `openci-org/openci`.
Webhook reception and planning are separate from this smoke test.

Press Ctrl+C to stop the Mac Orchard worker. Docker containers keep running.

After seeding, log in from another terminal:

```sh
openci login --local
```

This reads the API key from the running `openci-server` container, authenticates
with `http://localhost:8080`, and selects `test-team`. After the server confirms
the team, it saves and activates the `local` credential profile. Failed login
attempts leave existing credentials unchanged.

Then generate typed secret definitions from your workflow project:

```sh
openci sync secrets
```

The command uses the active credential profile and finds the nearest ancestor
containing an `openci` directory, starting from the current directory. It
replaces `openci/secrets.g.dart` with getters that read environment variables
at workflow runtime. Secret values are never downloaded or written to this file.
Run it again after adding or removing secrets. Fetch or generation failures leave
the existing file unchanged.

Generate typed workspace paths without logging in or starting local services:

```sh
openci sync paths
```

Run this from your workflow project or one of its subdirectories. The command
reads the `workspace` list in the root `pubspec.yaml` and each listed package's
`name`, then writes `openci/paths.g.dart` following the directory hierarchy.
For example, `apps/build_job_worker` becomes
`WorkspacePaths.root.apps.buildJobWorker`. Directory names determine the getters;
package names are used to validate the workspace. Run it again after adding,
moving or renaming workspace directories. Read or generation failures preserve
the existing file.

Import the generated file in your workflow and run it from the repository root,
as the worker does, because these paths are relative to that root:

```dart
import 'package:openci_workflow/openci_workflow.dart';

import 'paths.g.dart';

final openCI = await OpenCI.init(
  workflowName: 'Dashboard CI',
  ciTriggers: [CITrigger.push(branch: 'develop')],
  currentWorkingDirectory: WorkspacePaths.root.apps.dashboard,
);

await openCI.flutter.staticAnalysis();
await openCI.flutter.unitTests();
```

`openCI.flutter` uses the same working directory as `openCI.run()`.
It resolves `currentWorkingDirectory` relative to the workspace root, or uses
the workspace root when no directory is configured. Both Flutter methods also
accept `dir`, for example
`await openCI.flutter.unitTests(dir: WorkspacePaths.root.apps.dashboard);`.
The override is relative to the workspace root and applies only to that call;
later calls without `dir` continue to use the configured working directory.

`WorkspacePaths.root` represents `.` and `WorkspacePaths.root.apps` represents
`apps`. Both can also be passed directly to methods accepting a `String` path.
