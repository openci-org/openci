# dart_avf

[![pub package](https://img.shields.io/pub/v/dart_avf.svg)](https://pub.dev/packages/dart_avf)

Dart bindings for Apple's [Virtualization.Framework](https://developer.apple.com/documentation/virtualization). Create, install, clone, and run macOS virtual machines programmatically.

> **Platform:** macOS only (Apple Silicon required)

## Features

- **Create** macOS VMs from IPSW restore images
- **Install** macOS into VM bundles
- **Start** VMs in headless or GUI mode
- **Clone** VMs instantly via APFS copy-on-write
- **Discover** VM IP addresses for SSH access
- **Download** the latest macOS IPSW from Apple's CDN

## Quick Start

```dart
import 'package:dart_avf/dart_avf.dart';

void main() async {
  // Download latest macOS IPSW
  final ipsw = await MacOSRestoreImage.fetchLatest(
    destPath: 'macos.ipsw',
    onProgress: (p) => print('Download: ${(p * 100).toStringAsFixed(1)}%'),
  );

  // Create and install VM
  final vm = await MacVM.create(
    bundlePath: 'my-vm.bundle',
    ipswPath: ipsw.path,
    config: VMConfig(cpuCount: 4, memoryGB: 8, diskSizeGB: 64),
    onOutput: print,
  );

  // Start with GUI
  final process = await vm.start(gui: true, onOutput: print);

  // Discover IP for SSH
  final ip = await vm.discoverIP();
  if (ip != null) {
    print('SSH: ssh user@$ip');
  }

  // Clone for CI jobs (instant on APFS)
  final clone = await vm.clone('job-vm.bundle');
  final cloneProcess = await clone.start(onOutput: print);

  // Cleanup
  await clone.delete();
}
```

## Setup

### 1. Build the native helper binary

```bash
cd native/
swiftc -O -parse-as-library \
  -o vm_installer \
  -framework Virtualization \
  -framework AppKit \
  vm_installer.swift
```

### 2. Sign with entitlements

Create `entitlements.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.virtualization</key>
    <true/>
</dict>
</plist>
```

```bash
codesign --entitlements entitlements.plist --force -s - vm_installer
```

### 3. Place the binary

The `vm_installer` binary must be in the same directory as your compiled Dart executable.

## Architecture

```
dart_avf (Dart package)
├── MacVM          → High-level VM management API
├── VMConfig       → CPU, memory, disk configuration
├── MacOSRestoreImage → IPSW download & management
└── vm_installer   → Native Swift binary (Virtualization.Framework)
```

The native Swift binary handles operations that require main thread execution (`VZMacOSInstaller`, `VZVirtualMachine.start()`), which cannot be called directly from Dart's FFI due to threading constraints.

## API Reference

### MacVM

| Method | Description |
|--------|-------------|
| `MacVM.create()` | Create a new VM from IPSW |
| `MacVM.open()` | Open an existing VM bundle |
| `vm.install()` | Install macOS into the bundle |
| `vm.start()` | Start the VM (headless or GUI) |
| `vm.clone()` | APFS copy-on-write clone |
| `vm.discoverIP()` | Find VM's IP via ARP |
| `vm.delete()` | Delete the VM bundle |

### MacOSRestoreImage

| Method | Description |
|--------|-------------|
| `MacOSRestoreImage.fetchLatest()` | Download latest macOS IPSW |

## Requirements

- macOS 13+ (Ventura or later)
- Apple Silicon (M1/M2/M3/M4)
- Virtualization.Framework entitlements

## License

Apache-2.0 — see [LICENSE](LICENSE)
