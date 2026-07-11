# lume_dart

A Dart wrapper package for [Lume](https://github.com/trycua/lume), a CLI tool for managing macOS and Linux virtual machines on Apple Silicon. Easily control Lume VMs (start, list, clone, stop, delete) from Dart applications.

## Features

- 💻 **List VMs**: Fetch detailed metadata of VMs, including execution status, IP address, and SSH availability.
- 🚀 **VM Operations**: Start (with background execution support), clone, stop, and delete VMs.
- 🛡️ **Robust Process Management**: Prevents process hangs caused by pipe buffer overflow during background execution.

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  lume_dart: ^1.0.5
```

Or run:

```bash
dart pub add lume_dart
```

_Note: The `lume` CLI must be pre-installed on the host machine and available in your PATH._

## Usage

### Importing the library

```dart
import 'package:lume_dart/lume_dart.dart' as lume;
```

### List VMs (`ls`)

```dart
void main() async {
  // Get status of all VMs
  final List<lume.LumeVM> vms = await lume.ls(showLogs: false);

  for (final vm in vms) {
    print('VM Name: ${vm.name}');
    print('Status: ${vm.status}'); // e.g. 'running', 'stopped'
    print('IP Address: ${vm.ipAddress}');
    print('SSH Available: ${vm.sshAvailable}');
    print('---');
  }
}
```

### Start VM (`run`)

```dart
void main() async {
  // Start VM in background
  // When showLogs is false, stdout/stderr streams are automatically drained internally to prevent pipe buffer overflows
  final Process process = await lume.run(
    name: 'my-macos-vm',
    noDisplay: true,
    showLogs: false,
  );

  print('VM started with PID: ${process.pid}');
}
```

### Clone VM (`clone`)

```dart
void main() async {
  // Duplicate a new VM from a source image
  await lume.clone(
    source: 'macos-base-image',
    target: 'my-new-vm',
  );
  print('Clone completed.');
}
```

### Stop & Delete VM (`stop`, `delete`)

```dart
void main() async {
  // Stop VM
  await lume.stop(name: 'my-new-vm');

  // Delete VM
  await lume.delete(name: 'my-new-vm');
}
```
