# Build the OpenCI macOS image

Packer and the Cirrus Labs Tart plugin create a stopped, tested candidate VM for
OpenCI. The source is Cirrus's **macOS Tahoe / Xcode 27.2** image, pinned by OCI
digest in `toolchain.json`. A build does not update the image used by workers.

This replaces SSH edits to `base-macos` with reviewed toolchain changes:

1. Clone the pinned Cirrus image into a new `base-macos-packer-*` VM.
2. Install the selected Flutter/FVM, Go, Temurin JDK, Python, Codemagic CLI and
   Shorebird versions; prepare Android SDK packages and non-login CLI paths.
3. Verify the toolchain, then run Flutter analysis/tests, a release APK build,
   an unsigned iOS build, and Go vet/tests/build inside the VM.
4. Remove build checkouts, shell history and SSH keys, then shut down the VM.
5. Write a local Packer manifest. Publishing and worker promotion are separate.

The host Mac's SSH/Orchard configuration belongs to Ansible. This directory
configures the disposable **guest image**. Cirrus supplies macOS, Xcode, simulator
runtimes, Homebrew, Ruby/CocoaPods and Node. No Apple account is copied into the
guest. Updating the source digest updates that foundation and requires repeating
the builds below.

## Requirements

- An Apple Silicon Mac compatible with the selected macOS guest, with Tart
  installed. Local validation uses Tart 2.40.1.
- Packer 1.16.2 (`.packer-version`), Bash, Python 3, make and ShellCheck.
- Enough storage for the 140 GB source disk, downloads and candidate writes;
  allow at least 200 GB free for the first build. Tart uses APFS clones.
- Internet access to GHCR and the tool/package registries.

Use an operator Mac or a dedicated image builder. A production Orchard worker
must be paused and drained before using it as a builder. Keep the same host and
VM licensing requirements as existing Tart usage.

## Build

From this directory:

```sh
make init
make check

# Read the source image's guest password without putting it in shell history.
read -rs PKR_VAR_ssh_password
export PKR_VAR_ssh_password
export PKR_VAR_candidate_name=base-macos-packer-20261101
make build
unset PKR_VAR_ssh_password
```

The password is for the disposable Cirrus guest's `admin` account, not the host
Mac. The upstream image documents its default guest credentials. Do not reuse a
host admin password. Packer treats this input as sensitive; keep debug logging
disabled when handling credentials.

`make check` uses a dummy password for static validation and does not boot a VM.
`make build` disables Tart's automatic pruning and never uses `--overwrite`.
Choose a fresh candidate name for each run. The name must start with
`base-macos-packer-`; `base-macos` is rejected. A failed build may leave a stopped
candidate for diagnosis, but it is not a release artifact. Keep the build logs
outside Git and require both `OPENCI_IMAGE_TOOLCHAIN_VERIFIED` and
`OPENCI_IMAGE_BUILD_VERIFIED` followed by Packer success.

The guest receives only these provisioning scripts, `toolchain.json` and the
explicit environment in the Packer template. Host directories, SSH agents,
GitHub/GCP credentials and team secrets are not forwarded. Known credential
files, Git authentication headers and signing identities fail verification.
The image's guest login credentials are not an isolation boundary; worker
networking and host authentication remain independently managed.

## Update tools

Edit `toolchain.json`, review the diff and build a new candidate. Go and Temurin
installers are checked against the recorded SHA-256. Flutter/FVM and Codemagic
use explicit package versions; Shorebird uses a Git commit. Python is installed
at an explicit version through the `mise` included in the pinned Cirrus image.
Android versioned SDK packages are installed only when missing. Command-line
tools and platform-tools are inherited from the pinned source and checked.

`source_tag` is an informational label. The build uses `source_image`, whose
digest must match the reviewed Cirrus release; do not replace it with `latest`.
When changing it, update the expected macOS/Xcode/SDK/runtime versions after
inspecting the new image. The default Flutter path remains
`/Users/admin/fvm/default`, as required by the Cloud Run Executor.

Version pins make changes reviewable; this is not a byte-for-byte reproducible
build. Package registries and transitive dependencies are still external inputs.
The VM retains the requested toolchain and resolved Codemagic dependencies under
`/usr/local/share/openci-image/`. The local manifest in `artifacts/` records the
candidate name, source digest and hash of the requested toolchain.

## Publish and promote

After Packer succeeds, boot a disposable clone of the candidate and confirm it
still starts after cleanup. Test the actual workflows that will use it, including
signing/distribution in an appropriate test environment. The bundled smoke app
checks basic Android/iOS toolchain compatibility; it does not verify a customer
app or an App Store upload.

Authenticate to GHCR on the operator Mac, select a **new** release tag, and push
the stopped candidate explicitly:

```sh
tart login ghcr.io
tart push base-macos-packer-20261101 ghcr.io/openci-org/base-macos:vNEXT
```

Replace `vNEXT` with an unused version. Preserve older tags and record the
published digest. Verify the registry manifest and a fresh pull before promotion.

For each worker, pause scheduling and wait until all assigned/running VMs are
gone. Pull the published digest and validate a disposable clone on that worker's
actual Tart/macOS version. Preserve its previous `base-macos` as a rollback image,
then replace that alias while paused. Verify a real Orchard build and cleanup
before resuming scheduling. Start with one worker; repeat for the remaining
workers after the canary passes. This repository does not automatically publish,
change `BASE_VM_NAME`, or replace worker images.

References: [Tart Packer plugin](https://github.com/cirruslabs/packer-plugin-tart),
[Cirrus image templates](https://github.com/cirruslabs/macos-image-templates),
[Xcode 27.2 images](https://github.com/cirruslabs/macos-image-templates/releases/tag/27.2).

## Reproduce the released OpenCI image

The `released/` profile targets the CI environment shipped in OpenCI `v0.1.7`.
Its default input is the digest of that release. This preserves macOS 26.5
(25F71), Xcode 26.6 (17F113) and Apple's system-managed time zone database
2026f.1.0. Packer applies the pinned Android and iOS SDKs, Android Studio, JDK,
Go, Codemagic, xcodeproj, standard Flutter 3.47.8 and the Shorebird fork of
3.47.8. It exercises both Flutter distributions on iOS and Android. The separate
`base-macos.pkr.hcl` above targets the newer Cirrus Xcode 27.2 foundation.

From `infra/macos-image`, use the pinned Packer version and the disposable
guest password described above. Choose a fresh candidate name on each run.

```sh
make init
export PKR_VAR_candidate_name=base-macos-packer-v017-first
# Export PKR_VAR_ssh_password for the disposable guest as in the Build section.
make build-released
```

The template mounts only the prepared installer directory, read-only. The
installer cache is under `infra/macos-image/artifacts/release-0.1.7-inputs`.
The preparation step checks the SHA-256 of each installer. If the host already
has Apple's iOS 26.5 (23F73) simulator installer, copy its DMG into that cache
as `iOS-26.5-23F73.dmg` before preparation. Otherwise Xcode obtains the runtime
in the guest. The simulator download and the SDK installation need network
access. Developer accounts, signing certificates and CI credentials are
provided by the workflow at job time.

To rebuild the toolchain starting from the original `v0.1.0` macOS/Xcode
foundation, set `PKR_VAR_foundation=initial`. This builds the same CI tools and
retains the initial image's Apple-managed OS data. On a host with the original
stopped Tart release named `base-macos-release-v0.1.0`, use
`PKR_VAR_foundation=local-initial` to verify and reuse its disk. The build
manifest records the foundation and target release digests. Boot a disposable
clone without the installer share to verify the finished candidate.
