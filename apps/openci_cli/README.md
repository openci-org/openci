# GenuineCI CLI

Command-line tools for OpenCI authentication, team switching, secrets, workflow
paths, and local development.

## Install

Install with Dart 3.11.5 or later:

```sh
dart install genuineci_cli
genuineci --help
```

If `genuineci` is not found, follow the [`dart install` PATH setup](https://dart.dev/tools/dart-install).
Run `genuineci update` to update to the latest stable version on pub.dev.

In an interactive terminal, commands check for a newer stable version and ask
`Update now? [y/N]`. Enter `y` or `yes` to install it, then rerun your original
command with the updated CLI. Enter `n`, `no`, or press Enter to continue without
updating. Updates use `dart install`, so the Dart SDK must be on `PATH`.

Automatic checks time out after two seconds and silently skip network errors.
They are skipped for help, version, and update commands, when `CI` is set, or
when stdin, stdout, or stderr is redirected. Use
`genuineci --no-check-updates <command>` to skip the check explicitly.
`genuineci update` also works in scripts
without confirmation and returns a nonzero exit code if checking or installing
fails.

The remote commands work from any directory. Local development commands require
an [OpenCI checkout](https://github.com/openci-org/openci) and the services
described below.

## Shell completion

Bash and Zsh completion is provided by `cli_completion`. Completion scripts are
installed automatically when running `genuineci --help` or another command in an
interactive terminal outside CI. Restart your shell afterwards, or install them
explicitly and follow the printed instructions:

```sh
genuineci install-completion-files
```

For Zsh, ensure `autoload -Uz compinit` and `compinit` run in `~/.zshrc` before
the completion script is sourced. Reload with `source ~/.zshrc`.

Press Tab to complete every command and subcommand, their options (including
global flags), and known argument values:

```text
genuineci reg<Tab>                      # register
genuineci register <Tab>                # secret, secretFile, options
genuineci setup <Tab>                   # asc-keys, options
genuineci sync <Tab>                    # paths, secrets, options
genuineci dev start --s<Tab>             # --seed
genuineci use <Tab>                     # japanese, english, options
genuineci help register <Tab>           # secret, secretFile, options
genuineci login --ser<Tab>              # --server
genuineci login --server <Tab>          # default and saved HTTPS servers
genuineci login --team-id <Tab>         # saved team IDs for the selected server
```

Login value completion reads local credential profiles only. `--firebase-api-key`
also suggests the default and saved Firebase Web API keys for the selected server.
New server URLs, team IDs, and Web API keys can still be entered directly.
Completion does not fetch team lists or refresh tokens. Completion requests and
completion setup commands skip automatic update checks.

Use `genuineci uninstall-completion-files` to remove the scripts.

## Usage

Log in to a remote server with the same email and password as the dashboard:

```sh
genuineci login
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
application config directory with owner-only permissions on macOS/Linux. If an
older development build stored your credentials in a `genuineci` configuration
directory, log in again; those credentials are not migrated.

Check the active profile, server, and current team:

```sh
genuineci status
```

```text
Profile: remote
Server: https://ci.example.com
Selected team ID: team-id
Team name: My team
```

The command fetches the current team name from the saved server using the active
profile's team ID. It works from any directory and supports redirected output.
It preserves the selected team and other profiles; expiring Firebase tokens are
refreshed automatically. The saved profile, server, and team ID are displayed
even if the team name cannot be fetched. If the selected team is no longer
available, run `genuineci switch team`. Errors go to stderr and return a nonzero
exit code. A fresh installation shows a login hint and exits successfully.

List all teams available to the active profile:

```sh
genuineci list teams
```

```text
  Alpha (team-a)
* OpenCI (team-b)
```

Each line shows a team name and ID, sorted by name and then ID. `*` marks the
selected team. Listing teams does not change the selected team or active profile;
expiring Firebase tokens are refreshed automatically. It works with redirected
output and does not require a selected team. An empty list shows a message and
exits successfully; authentication, connection, and invalid-response errors go
to stderr and return a nonzero exit code.

Switch the active profile's team without logging in again:

```sh
genuineci switch team
```

The CLI fetches your team memberships from the server saved in the active
credential profile. A `remote` profile uses the HTTPS URL saved by `genuineci login`,
including any `--server` override. A `local` profile created by
`genuineci login --local` uses `http://localhost:8080` and its saved Auth Emulator
settings. To activate the remote or local profile, run the corresponding login
command first.

The picker shows each team's name and ID, with `*` marking the saved current
team and `>` marking the highlighted choice. It starts on the current team if
that team is still available, otherwise on the first candidate.

- Use the up/down arrow keys to move; navigation wraps at either end.
- Press Enter to confirm, even if only one team is available.
- Press Esc or Ctrl+C, or end the input, to cancel.

Confirmation updates only the active profile's `teamId`. The `remote` and
`local` profiles each keep their own current team; selecting a team updates
the existing profile. Server and Auth Emulator settings, refreshed tokens, and
other profiles are preserved. Choosing the current team succeeds without a
write. Cancellation or a failed save preserves the previous selected team.
Expiring authentication tokens may still be refreshed before the picker opens.
If the active profile or its credentials change during selection, the CLI
refuses to overwrite them and asks you to run `genuineci switch team` again.

Subsequent `genuineci list secrets`, `genuineci register secret`,
`genuineci register secretFile`, and `genuineci sync --secrets` commands use the newly
selected team. Existing `openci/generated/secrets.g.dart` files are updated by running
`genuineci sync --secrets` in the workflow project.

Team switching requires interactive stdin and stdout with ANSI support. Run it
directly in a terminal, without piped input or redirected output. Success and
unchanged-selection messages go to stdout; errors and cancellations go to
stderr and return a nonzero exit code.

Troubleshooting team selection:

| Condition | What to check |
| --- | --- |
| Login required or HTTP 401/403 | Log in again for the intended server with `genuineci login` or `genuineci login --local`. |
| No team memberships | Create or join a team in the dashboard for that server. |
| Interactive terminal required | Use an ANSI-capable terminal with interactive stdin and stdout; remove pipes and output redirection. |
| HTTP error or connection failure | Check the active profile's server URL and network connection. For local development, check that `genuineci dev start` is running. |
| Invalid team list | Check that the saved server URL points to a compatible OpenCI API. |
| Changed profile or credentials | Run `genuineci switch team` again using the current authentication. |
| Save failure | Check the credentials file, its permissions, and available disk space. |

Choose English or Japanese messages with `genuineci use english` or
`genuineci use japanese`. The language setting is saved for future invocations.

List secret names for the active profile's team:

```sh
genuineci list secrets
```

Names are printed one per line, sorted by name, without secret values. If the
team has no secrets, the command prints a message and exits successfully. It
works from any directory, supports redirected output, and does not generate
workflow files. Control characters in names are displayed as escaped text.

Check App Store Connect API key setup and prepare asc for the active profile's team:

```sh
genuineci setup asc-keys
```

The command checks your GenuineCI login, verifies the selected team is
available, and displays its name and ID together with the saved server URL.
It checks for the `OPENCI_ASC_API_KEY` secret, reserved for a JSON bundle of
the ASC Key ID, Issuer ID, and private key. Only secret names are inspected;
secret values and Apple credentials are not downloaded or validated.

An existing secret returns exit code 0 without preparing asc. When the secret
is missing, the command automatically downloads the pinned
[asc 5.11.0](https://github.com/rorkai/App-Store-Connect-CLI/releases/tag/5.11.0)
binary for your OS and CPU, verifies its bundled SHA-256 checksum, and caches it.
The checksum is checked again before reuse; a corrupt cached binary is downloaded
again. Downloads are staged separately and installed only after verification.
The asc MIT license is saved beside the binary.

No prior asc installation is required. GenuineCI uses its own cache, independently
of any asc on `PATH`:

- macOS: `~/Library/Caches/genuineci/tools/asc/5.11.0/<target>/`
- Linux: `${XDG_CACHE_HOME:-~/.cache}/genuineci/tools/asc/5.11.0/<target>/`
- Windows: `%LOCALAPPDATA%\genuineci\tools\asc\5.11.0\<target>\`

Available binaries cover macOS and Linux on arm64/x64, and Windows on x64.
Other platforms return an error before downloading.

Apple sign-in, key issuance, and secret persistence are not implemented yet.
A missing secret still reports incomplete setup and returns 1 after preparing
asc; login, team, API, and asc preparation errors also return 1. Expiring Firebase
tokens are refreshed automatically. The command works without an interactive
terminal.

Register a secret for the active profile's team:

```sh
genuineci register secret
```

Enter the secret name (for example, `API_TOKEN`), then its value in an interactive
terminal. The value is hidden while typing. After you press Enter, the prompt
shows `******`, regardless of the value's length.

Registering an existing name updates its value. The CLI uses the dashboard's
existing API, which trims leading and trailing whitespace from values. Values
are not printed or saved locally. Firebase tokens are refreshed when needed.
After adding a secret, run `genuineci sync --secrets` from your workflow project
to update its generated secret definitions.

Register a file as a Base64 secret:

```sh
genuineci register secretFile
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
printed or saved locally. Run `genuineci sync --secrets` afterwards to update the
generated definitions.

Run `genuineci dev start` from the OpenCI checkout to start local services and the
Mac Orchard worker. Prepare the existing non-Firebase Docker Compose credentials
and `base-macos` VM first. Docker Compose 2.24.4 or later is required for the
local API override.

The command uses `docker-compose.yml`, `docker-compose.local.yml`, and
`docker-compose.local-api.yml` together. It starts the Firebase Auth Emulator
for project `demo-openci` and waits for its health check before starting Orchard
Controller, the Mac worker, and the local API. No production Firebase service
account is needed. The Auth endpoint is `http://127.0.0.1:9099` and the Emulator
UI is `http://127.0.0.1:4000/auth`. When restarting, the command stops the old
build-job-worker and waits for running jobs to finish while the server remains
available for saving results and deleting their VMs. It then rebuilds and
starts the application containers. See [the emulator setup](../../firebase/README.md)
for standalone start and stop commands.

The `/internal` seed and cleanup API is disabled by default. `genuineci dev start`
automatically enables it by passing `ENABLE_INTERNAL_API=true` to Docker Compose.
Requests also require `INTERNAL_API_KEY`. For `genuineci dev start --seed`, the CLI
always reads it from the checkout's `.env` file and only seeds a local server.
The dev command also excludes a shell-exported `INTERNAL_API_KEY` from Docker
Compose so the server and seed request use the same key.

To also prepare a development Auth user and queue the default smoke-test build job:

```sh
genuineci dev start --seed
```

The CLI first creates an email/password user in the local `demo-openci` Auth
Emulator and marks its email as verified:

- Email: `test@openci.org`
- Password: `123456`

These fixed credentials are only for local development. Repeated seeding reuses
the same user and sets `emailVerified=true` without resetting its password.
If the account already exists with a different password or is disabled, seeding
fails without changing it. Check the account in the
[Auth Emulator UI](http://127.0.0.1:4000/auth). An Auth failure stops seeding before
the team/job request. Emulator users are lost when the emulator restarts;
`--seed` creates the user again.

The local Compose override configures `test@openci.org` as the allowed email by
default. Set `LOCAL_ALLOWED_USER_EMAILS` in `.env` to use another comma-separated
allowlist; an empty value configures a deny-all policy. API enforcement is
tracked in [#2942](https://github.com/openci-org/openci/issues/2942).

The CLI sends that user's UID to the seed API, which registers it as a member
of `test-team` before queuing the smoke-test job. Repeated seeding preserves the
existing membership. If team or membership creation fails, the seed request
fails without queuing a job. Direct `/internal/seed` callers can omit `userId`
to seed only the team and job.

The server seeds `test-team` and one `macos-latest` job for
`openci-org/openci`'s `openci/worker_smoke.dart`, pinned to commit
`5cb05f76d8941ea1edc3593eb753ce808f0f290e` on
`test/build-job-worker-smoke-openci`.
The workflow checks macOS and Flutter versions and runs the worker's unit tests.
It uses this fixed fixture, not uncommitted files in your local checkout.

The server resolves the installation ID using the GitHub App already configured
in Docker Compose. That App must have access to `openci-org/openci`.
Webhook reception and planning are separate from this smoke test.

Press Ctrl+C to stop the Mac Orchard worker and the local Docker Compose stack.
The same shutdown also runs when the command exits or receives SIGTERM. Named
volumes and local data are kept.

To log in locally, keep `genuineci dev start --seed` running, then run:

```sh
genuineci login --local
```

Enter `test@openci.org` and `123456`, or the credentials of another user
you created in the Auth Emulator UI. The CLI signs in through the
fixed address `127.0.0.1:9099`, sends the resulting Firebase ID token to
`http://localhost:8080/teams`, and selects `test-team` only if the API returns it
among your memberships. `--seed` prepares this membership for `test@openci.org`;
you can use the same account in the local Dashboard. If `test-team` is missing,
check that seeding completed and that you are using the seeded account.

Successful login saves and activates the `local` Firebase profile, including
the refresh credentials and `firebase_auth_emulator_host`. Later token refreshes
use the same emulator. Failed or cancelled login preserves saved profiles and
never falls back to real Firebase. To replace an older `local` profile containing
an internal API key, run `genuineci login --local` again after preparing the user
and team; successful login replaces only that profile. The password is never
saved. The remote `--server`, `--team-id`, and `--firebase-api-key` options cannot
be combined with `--local`.

Local login does not read Docker's `INTERNAL_API_KEY`. Worker and seed operations
still use that key, and `--seed` does not require CLI login.

Run `genuineci sync` from your workflow project to generate both typed secret
definitions and workspace paths:

```sh
genuineci sync
```

The files are written to `openci/generated/secrets.g.dart` and
`openci/generated/paths.g.dart`. The `generated` directory is created if needed.
Use `--secrets` or `--paths` to generate only that file; passing both flags
generates both. Each selected generator runs even if the other fails, and the
command exits unsuccessfully if either selected generator fails.

With an authenticated credential profile, generate only secret definitions:

```sh
genuineci sync --secrets
```

The command uses the active credential profile and finds the nearest ancestor
containing an `openci` directory, starting from the current directory. It
replaces `openci/generated/secrets.g.dart` with getters that read environment variables
at workflow runtime. Secret values are never downloaded or written to this file.
Run it again after adding or removing secrets. Fetch or generation failures leave
the existing file unchanged.

Generate typed workspace paths without logging in or starting local services:

```sh
genuineci sync --paths
```

Run this from your workflow project or one of its subdirectories. The command
reads the `workspace` list in the root `pubspec.yaml` and each listed package's
`name`, recursively collects their subdirectories, then writes
`openci/generated/paths.g.dart` following the directory hierarchy. For example,
`apps/dashboard/android/app` becomes
`WorkspacePaths.root.apps.dashboard.android.app`. If `workspace` is absent, the
command treats the root package as a single-package project and collects its
subdirectories. For example, `android/app` becomes
`WorkspacePaths.root.android.app`, and `lib` becomes `WorkspacePaths.root.lib`.
An explicitly empty `workspace: []` still generates only the root accessor.
Hidden directories, symlinks, and generated or dependency directories (`build`,
`coverage`, `node_modules`, `Pods`, `ephemeral`, and `xcuserdata`) are excluded at
every level. `openci/generated` is also excluded so repeated syncs produce
stable paths. Directory names determine the getters; package names are used to
validate the workspace.
Dart keywords and `Object` member names get a trailing underscore: `switch`
becomes `switch_`, `class` becomes `class_`, and `hash_code` becomes `hashCode_`.
The directory paths themselves are preserved. Sibling names that map to the same
getter, such as `switch` and `switch_`, are rejected.
Run it again after adding, moving or renaming workspace directories. Read or
generation failures preserve the existing file.

The previous `sync secrets` and `sync paths` subcommands are replaced by these
flags. When upgrading existing workflows, change imports to
`generated/secrets.g.dart` and `generated/paths.g.dart`, then remove the old
files from `openci/` after updating their imports.

Import the generated file in your workflow and run it from the repository root,
as the worker does, because these paths are relative to that root:

```dart
import 'package:openci_workflow/openci_workflow.dart';

import 'generated/paths.g.dart';

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

## Code generation

Run these commands from `apps/openci_cli`:

```sh
dart run slang
dart run build_runner build
```

Translations use `slang.yaml` through the Slang CLI. `build_runner` generates
the Freezed and JSON models.
