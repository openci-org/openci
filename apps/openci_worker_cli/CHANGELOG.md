# Changelog

## 2.3.4

- Feature: Configure Docker container CPU (default: 4) and Memory (default: 4g) limits via env (OPENCI_DOCKER_CPUS / OPENCI_DOCKER_MEMORY) to prevent host OOM crashes.

## 2.3.3

- Fix: Update default base VM name to tahoe-base_v1.2.3 to match the current setup script image version, resolving clone VM failures.

## 2.3.2

- Fix: Bump lume_dart to 1.0.1 to address strict SDK constraint issues, resolving the auto-update failures on build machines.

## 2.3.1

- Fix: Relax Dart SDK version constraints to allow newer Dart SDK versions (e.g. 3.12.x), resolving auto-update failures on build machines.

## 2.3.0

- Feature: Migrate VM execution and lifecycle management from avf_dart to lume_dart (Lume CLI).
- Feature: Replace OS-level process killing with safe zombie VM detection, stopping, and deleting using lume.ls.

## 2.2.0

- Feature: Support build cancellation

## 2.1.0

- Add: One hour timeout

## 2.0.3

- Fix dependency issues with openci_shared.

## 2.0.2

- Fix auto_updater

## 2.0.1

- Auto increment `OPENCI_RUN_NUMBER`

## 0.10.50

- Feature: Migrate environment variables to secrets (`OPENCI_BUILD_NUMBER`), removing old Firestore/Functions environment variables API.

## 0.10.49

- Fix: Implement retry logic with exponential backoff delay for `git clone` and `git fetch` operations in both VM and Docker executors, addressing transient network connection issues during environment initialization.

## 0.10.48

- Fix: Force Firebase ID Token refresh before long build executions, preventing 401 Unauthorized errors during artifact uploads inside VMs.

## 0.10.47

- Fix: Inject `OPENCI_BUILD_JOB_ID` and `OPENCI_SERVER_URL` into the build execution environment variables map, resolving OTA distribution issues.

## 0.10.46

- Feature: Inject the worker's Firebase ID Token as `OPENCI_ID_TOKEN` into the build job environment, enabling secure API interactions without exposing Firebase service accounts.

## 0.10.45

- Fix: Reset worker status to 'idle' when recovering from polling errors, preventing status from getting stuck in 'error' after temporary API offline periods.

## 0.10.44

- Feature: Migrate worker heartbeat to PostgreSQL (`openci_server`), removing Firestore and Firebase Cloud Functions dependencies, and streamlining tracked fields.

## 0.10.43

- Feature: Retrieve secrets exclusively from `openci_server`, removing Firebase Cloud Functions fallback.

## 0.10.42

- Fix: Prevent `PathExistsException` (errno = 17) during auto-update by pre-deleting the existing execution symlink/binary before running `dart install`.
- Fix: Prevent child worker processes from becoming orphaned zombies by forwarding SIGTERM and SIGINT signals from the supervisor to the child process.

## 0.10.41

- bump version to 0.10.41

## 0.10.40

- Feature: Support connecting directly to `openci_server` (via `OPENCI_SERVER_URL`) for claiming jobs, resolving installation tokens, and managing run/job statuses.

## 0.10.39

- Fix: Bump avf_dart to 0.1.26 to resolve the issue where the worker immediately terminates the VM boot sequence on encountering a temporary missing DHCP leases file during startup.

## 0.10.38

- Fix: Retrieve Firebase ID Token from `ApiClient`'s `AuthManager` and pass it in the `Authorization` header when sending build logs to `openci_server` to resolve the `401 Unauthorized` errors.

## 0.10.37

- Fix: Add a 10-second timeout to the POST request in `sendToServer` within `build_job_logger.dart` to prevent indefinite hangs and match `finalizeBuildLog` timeout duration.

## 0.10.36

- Fix: Change `pruneStaleVms` log output from build log (logInfo/logWarning) to local logger (\_log) to prevent errors when trying to write logs after `finalizeBuildLog` has been called.

## 0.10.35

- Feature: Shorten build log `[Workflow/Job]` prefixes to a shorter `[Job]` format for better mobile visibility.

## 0.10.34

- Fix: Avoid reporting worker status as error when a build job (CI run) fails (e.g. test failures). The worker now intercepts act execution failures, marks the job as failed, and returns to idle state, preventing normal CI failures from surfacing as worker infrastructure errors in the dashboard.

## 0.10.33

- Release 0.10.33

## 0.10.32

- Release 0.10.32

## 0.10.31

- Test auto-update logic with a minor version bump.

## 0.10.30

- Fix: Scope `_killZombieAvfProcesses` to the worker's own `openci-vm-<workerId>-` VMs. With two workers per host, one worker's pre-job cleanup was killing the sibling worker's actively-booting VM (SIGTERM → "VM process exited prematurely with code -15"), because the zombie check was unscoped and mis-parsed the VM path (the path contains a space in "Application Support"). Now it matches the VM-name token and only kills genuinely-orphaned VMs belonging to this worker.

## 0.10.29

- Fix: Run `act` with `HOME=/Users/admin` instead of a unique `/tmp/openci-home-<uuid>` directory. On macOS 26 (Tahoe) a code-signing keychain created under a non-standard home (e.g. `/tmp/.../Library/Keychains`) is not honored by `security find-identity -v -p codesigning` (0 valid identities), breaking iOS/macOS signing. The per-run unique HOME is unnecessary now that each build runs in its own fresh VM. This also keeps the stable build workspace path consistent.

## 0.10.28

- Change: Bump avf_dart to 0.1.16 to boot macOS VMs with 8 GB of memory (was 4 GB), giving Flutter/Xcode/iOS builds enough headroom (4 GB caused in-guest memory pressure and SSH drops / `act exited with code 255`).

## 0.10.27

- Feature: Assign each worker a distinct, stable MAC address for its cloned VM (derived from the worker number, keeping the validated da:d7:a6:2d:e9 prefix). This lets two workers run on the same physical host without their VMs colliding on the shared vmnet bridge (same MAC previously meant the same DHCP IP/ARP entry). Enables the 2-workers-per-host deployment.

## 0.10.26

- Fix: Communicate with the guest VM exclusively through the macOS system binaries `/usr/bin/ssh` and `/usr/bin/scp` (and `/sbin/ping`, `/usr/bin/nc`) instead of in-process Dart sockets (dartssh2). On macOS 15+/26, Local Network privacy blocks in-process sockets of a non-exempt process (such as the worker running as a LaunchAgent) from reaching the VM's local network address, surfacing as a persistent `No route to host` (EHOSTUNREACH), while Apple's system binaries remain exempt. `setupDirectSsh` now uses `ssh` with `SSH_ASKPASS` for the one-time password auth, and file uploads use `scp`. Intended to run as a LaunchAgent in the GUI session (see scripts/openci-worker LaunchAgent).

## 0.10.25

- Fix: Stop `_isActError` from flagging a successful run as failed when the workflow output contains a decorative zero-count summary line such as Patrol's `❌ Failed: 0`. A `❌` with an explicit zero failure/error count is now treated as benign.

## 0.10.24

- Fix: Bump avf_dart to 0.1.15 to probe the SSH port with a fresh `nc` subprocess instead of an in-process `Socket.connect`. This fixes long-running workers getting stuck on a permanent `No route to host` for a VM whose SSH port is actually reachable (confirmed: a fresh process/`nc`/`ssh` connect fine while the worker keeps failing).

## 0.10.23

- Fix: Bump avf_dart to 0.1.14 to use a two-phase check (ping then socket connect) to avoid socket resolution error caching issues.

## 0.10.22

- Fix: Bump avf_dart to 0.1.13 to recreate InternetAddress instance on every SSH connection attempt.

## 0.10.21

- Fix: Bump avf_dart to 0.1.12 to use explicit InternetAddress with InternetAddressType.IPv4 and absolute path /sbin/ping for the force-ARP workaround.

## 0.10.20

- Fix: Bump avf_dart to 0.1.11 to connect directly to the IP address string in SSH port checking, bypassing potential `InternetAddress.lookup` resolution/mapping bugs.

## 0.10.19

- Fix: Bump avf_dart to 0.1.10 to prevent VM boot timeouts caused by picking up stale DHCP lease records on startup.

## 0.10.18

- Fix: Bump avf_dart to 0.1.9 to remove MAC address randomization. Restores the fixed original MAC address to prevent guest macOS network device (en0) from breaking and failing DHCP lease allocation.

## 0.10.17

- Fix: Bump avf_dart to 0.1.8 to resolve Dart VM socket connection caching issues when checking SSH port availability. This prevents VM boot timeouts by checking IP resolution and using a longer retry interval (5s) for port connectivity checks.

## 0.10.16

- Fix: Bump avf_dart to 0.1.7 to dynamically generate a unique random MAC address during VM cloning. This resolves MAC address and IP address conflicts when multiple matrix worker jobs run concurrently on the same host machine.

## 0.10.15

- Fix: Bump avf_dart to 0.1.6 to restore virtual graphics, keyboard, and pointing devices to macOS VM configurations. These virtual devices are required for macOS guest OS to complete initialization and open SSH port under headless execution mode.

## 0.10.14

- Fix: Bump avf_dart to 0.1.5 to configure macOS VM to run in fully headless mode, avoiding AppKit/NSApplication window system deadlocks on headless host machines.

## 0.10.13

- Fix: Bump avf_dart to 0.1.4 to migrate the SSH port checking logic from Swift (NWConnection) to Dart (Socket.connect), resolving VM startup timeouts caused by unstable virtual network path resolution in Swift.

## 0.10.12

- Fix: Bump avf_dart to 0.1.3 to improve avf_helper search resolution order, prioritizing pub-cache and latest version over installer cache directories to fix VM startup timeout issues.

## 0.10.11

- Fix: Proactively run VM cleanup and kill zombie virtualization helper processes before and after every build job on macOS. This ensures that memory held by orphaned VM helper processes is fully released, preventing subsequent jobs from failing with VM boot timeouts.

## 0.10.10

- Fix: Bump SSH and guest IP allocation timeout limits from 120 seconds to 300 seconds (5 minutes) in avf_dart's virtual machine boot helper to prevent VM startup timeouts on heavily-loaded macOS workers.

## 0.10.9

- Fix: Check both `~/.local/state` and `~/.local/share` directories for the AOT binary in supervisor.dart on Linux. This resolves the issue where Linux workers failed to reload after an auto-update because `dart install` placed the binary under the `state` directory while supervisor only looked in `share`.

## 0.10.8

- Fix: Add automatic cleanup of zombie `com.apple.Virtualization.VirtualMachine` processes holding locks on macOS VM nvram/disk files, preventing startup timeouts.

## 0.10.7

- Feature: Map ubuntu-latest to the dockerImage in docker_job_executor.dart to run each matrix job in an individual container instead of self-hosted, resolving parallel file write conflicts.

## 0.10.6

- Fix: Dynamically inject env.HOME path based on matrix.name in actions-ci.yaml before running act to prevent parallel write conflicts on self-hosted matrix jobs.

## 0.10.5

- Fix: Export unique HOME directory for each act run to prevent parallel write conflicts on Vite+ installations.

## 0.10.4

- Fix: Mount host's docker.sock inside the runner container in docker_runner.dart to allow 'act' to run jobs in sibling docker containers.

## 0.10.3

- Fix: Prioritize running the AOT binary installed via 'dart install' in supervisor.dart to resolve the old version loading issue on Linux workers.

## 0.10.2

- Fix: Bump avf_dart to 0.1.1 to resolve the native assets (avf_helper) loading failure on AOT-compiled global packages.

## 0.10.1

- Feature: Migrate from 'dart pub global activate' to 'dart install' to support native assets (build hooks) compilation on macOS global installations.

## 0.10.0

- Feature: Unified auto-updater on Mac and Linux via global Dart packages (dart pub global activate)
- Fix: Await \_installUpdate call to catch process exceptions properly

## 0.9.22

- Fix: Bump openci_shared to 1.0.1 to resolve strict SDK constraint (allowing execution on Dart SDK >= 3.12)

## 0.9.21

- Fix: Add await to \_installUpdate call to properly catch ProcessException inside try-catch

## 0.9.20

- Fix: Resolve version constants to match pubspec.yaml to prevent redundant auto-updates
- Fix: Ensure non-interactive ssh compatibility for worker launch scripts

## 0.9.19

- Ported Node.js worker CLI to Dart
- Migrated from direct Firestore operations to Firebase Functions API (fully removed Firestore dependency)
- Added Firebase Auth credentials support (`--email` and `--password`) to deprecate Google Service Account keys
- Integrated `avf_dart` for macOS Apple Virtualization Framework support

## 0.9.18

- Pass a GitHub event payload to `act` via `-e /tmp/openci-event.json` so workflow expressions like `${{ github.event.pull_request.number }}` resolve correctly (enables Firebase Hosting preview channel deploys on PRs)

## 0.9.17

- Migrate Firestore to Enterprise Edition (`openci-enterprise` database)

## 0.9.16

- Fix: update `openci_shared` dependency to 0.1.1 for `githubBaseUrl` / `githubApiBaseUrl` fields (GitHub Enterprise support)

## 0.9.15

- Fix poison queue: automatically mark jobs with missing `runsOn` as failure instead of silently skipping them, preventing queue blockage

## 0.9.14

- Update base VM image to tahoe-base v1.1.1

## 0.9.13

- Verify auto-update across all environments (Hetzner + macOS)

## 0.9.12

- Verify auto-update via pub.dev in supervised mode

## 0.9.11

- Fix supervisor: detect pub global execution and use `dart pub global run` to spawn child worker, preventing `--service-account` from being misinterpreted as Dart VM flags

## 0.9.10

- Verify automated pub.dev publishing pipeline

## 0.9.9

- Migrate auto-updater from GitHub Releases binary swap to pub.dev `dart pub global activate`
- Simplify supervisor: remove binary swap logic, restart-only
- Add OpenCI CI/CD workflow for automated pub.dev publishing

## 0.9.8

- Require explicit `runs-on` in workflow: macOS worker only processes `macos-*` jobs, no longer claims jobs without `runsOn`

## 0.9.7

- Fix: Ensure Cloud Function notifications complete before rethrowing exceptions in error handler

## 0.9.6

- Fix: Skip dependent jobs when parent job fails (cascade skip via Cloud Function)

## 0.9.5

- Add Worker CLI version to job processing log

## 0.9.3

- Fix: Kill zombie lume VM processes from any worker ID on startup
- Prevents VM slot exhaustion when orphaned processes outlive their worker

## 0.9.2

- Extract AI failure summary into standalone Cloud Function (`generate-failure-summary`)
- Worker now calls `generate-failure-summary` independently after build failures
- Fix: AI summaries were not generated due to `unawaited` fire-and-forget in previous architecture

## 0.9.1

- Implement supervisor architecture for auto-updates and crash recovery
- Add `--supervised` flag for process supervisor mode
- Unify auto-updater for macOS/Linux via GitHub Releases
- Add semver comparison to prevent downgrades
