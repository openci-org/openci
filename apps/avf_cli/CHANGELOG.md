# Changelog

## 0.1.11

- Update `avf_dart` to `0.1.25` for VM signal handling and automatic MAC address generation.

## 0.1.10

- Update `avf_dart` to `0.1.24` to resolve thread-safety crash on macOS installation completion callback.

## 0.1.9

- Update `avf_dart` to `0.1.23` to resolve macOS installer crash on headless environments.

## 0.1.8

- Maintenance: Bump version for synchronization and integration verification.

## 0.1.7

- Maintenance: Bump version for release verification.

## 0.1.6

- Feature: Integrate Native Assets build hooks (`hook/build.dart`) to automatically generate `lib/src/version.dart` from the version defined in `pubspec.yaml`, ensuring CLI version sync without manual updates.

## 0.1.5

- Update `avf_dart` to `0.1.21` to use chunk-file sequential writes and merging for robust high-speed downloads without OS disk freezes.

## 0.1.4

- Update `avf_dart` to `0.1.20` to restore parallel downloads with a watchdog timer to resolve freezing issues.

## 0.1.3

- Feature: Add `version` command to print the CLI tool version.
- Update `avf_dart` to `0.1.19` to resolve download freezes.

## 0.1.2

- Update `avf_dart` to `0.1.18` to resolve download freezes.
- Change: Reduce default download concurrency to 4 in `download-ipsw`.

## 0.1.1

- Update `avf_dart` to `0.1.17` to fix `PathNotFoundException` in `download-ipsw` when the target download directory does not exist.

## 0.1.0

- Initial release.
- Provides CLI tool `avf` (or `avf_cli` executable) to manage local Apple Virtualization.framework macOS VMs, wraping `avf_dart` functionalities:
  - `list`: Show all local virtual machines.
  - `boot <name>`: Boot a local VM and wait for SSH readiness.
  - `install <name> --ipsw <path>`: Create a new VM from an IPSW image.
  - `delete <name>`: Delete a local VM.
  - `clone <source> <target>`: Clone VM configurations and disk images.
  - `pull <name> --bucket <bucket>`: Retrieve VM archives from Google Cloud Storage.
  - `push <name> --bucket <bucket>`: Upload VM archives to Google Cloud Storage.
  - `download-ipsw`: Fetch and download macOS IPSW files directly from Apple.
