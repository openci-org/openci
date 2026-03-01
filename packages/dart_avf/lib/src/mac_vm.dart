import 'dart:ffi' as ffi;
import 'dart:io';
import 'dart:math';

import 'package:objective_c/objective_c.dart' as objc;
import 'package:path/path.dart' as p;

import 'virtualization_bindings.dart';
import 'vm_config.dart';

/// A macOS virtual machine managed by Apple's Virtualization.Framework.
///
/// Use [MacVM.create] to create a new VM bundle, or [MacVM.open] to work
/// with an existing bundle.
///
/// ```dart
/// final vm = await MacVM.create(
///   bundlePath: 'my-vm.bundle',
///   ipswPath: 'macos.ipsw',
/// );
/// await vm.install();
/// await vm.start(gui: true);
/// ```
class MacVM {
  /// Path to the VM bundle directory.
  final String bundlePath;

  /// VM configuration.
  final VMConfig config;

  MacVM._({required this.bundlePath, this.config = const VMConfig()});

  /// Opens an existing VM bundle.
  ///
  /// Throws if the bundle doesn't exist or is missing required files.
  static MacVM open(String bundlePath, {VMConfig config = const VMConfig()}) {
    _validateBundle(bundlePath);
    return MacVM._(bundlePath: bundlePath, config: config);
  }

  /// Creates a new VM bundle from an IPSW image using the `vm_installer`
  /// native binary with the `setup` command.
  ///
  /// This creates the bundle directory, disk image, hardware model,
  /// machine identifier, and auxiliary storage, then installs macOS.
  static Future<MacVM> create({
    required String bundlePath,
    required String ipswPath,
    VMConfig config = const VMConfig(),
    void Function(String line)? onOutput,
  }) async {
    final installerPath = _findInstaller();

    final process = await Process.start(installerPath, [
      'setup',
      bundlePath,
      ipswPath,
      '${config.diskSizeGB}',
      '${config.cpuCount}',
      '${config.memoryGB}',
    ]);

    process.stderr.transform(const SystemEncoding().decoder).listen((data) {
      if (onOutput != null) {
        for (final line in data.split('\n').where((l) => l.isNotEmpty)) {
          onOutput(line);
        }
      }
    });

    _forwardSignals(process);

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('VM creation failed (exit code: $exitCode)');
    }

    return MacVM._(bundlePath: bundlePath, config: config);
  }

  /// Creates a VM bundle directory from an IPSW using ObjC FFI.
  ///
  /// This only creates the bundle (disk, hardware model, machine identifier,
  /// auxiliary storage) without installing macOS. Use [install] after this.
  static Future<MacVM> createBundle({
    required String bundlePath,
    required String ipswPath,
    VMConfig config = const VMConfig(),
  }) async {
    _loadVirtualizationFramework();

    if (Directory(bundlePath).existsSync()) {
      throw Exception('Bundle already exists: $bundlePath');
    }

    Directory(bundlePath).createSync(recursive: true);

    final restoreImage = await _loadRestoreImage(ipswPath);

    final requirements = restoreImage.mostFeaturefulSupportedConfiguration!;
    final hardwareModel = requirements.hardwareModel;

    if (!hardwareModel.isSupported) {
      throw Exception('Hardware model not supported on this Mac.');
    }
    hardwareModel.dataRepresentation.writeToFile(
      objc.NSString('$bundlePath/HardwareModel'),
      atomically: true,
    );

    final machineIdentifier = VZMacMachineIdentifier();
    machineIdentifier.dataRepresentation.writeToFile(
      objc.NSString('$bundlePath/MachineIdentifier'),
      atomically: true,
    );

    VZMacAuxiliaryStorage.alloc().initCreatingStorageAtURL(
      objc.NSURL.fileURLWithPath(objc.NSString('$bundlePath/AuxiliaryStorage')),
      hardwareModel: hardwareModel,
      options: VZMacAuxiliaryStorageInitializationOptions
          .VZMacAuxiliaryStorageInitializationOptionAllowOverwrite,
    );

    final result = Process.runSync('dd', [
      'if=/dev/zero',
      'of=$bundlePath/Disk.img',
      'bs=1',
      'count=0',
      'seek=${config.diskSizeGB}g',
    ]);
    if (result.exitCode != 0) {
      throw Exception('Failed to create disk image: ${result.stderr}');
    }

    return MacVM._(bundlePath: bundlePath, config: config);
  }

  /// Installs macOS into an existing bundle.
  ///
  /// The bundle must have been created with [create] or [createBundle].
  Future<void> install({
    required String ipswPath,
    void Function(String line)? onOutput,
  }) async {
    _validateBundle(bundlePath);
    final installerPath = _findInstaller();

    final process = await Process.start(installerPath, [
      'install',
      bundlePath,
      ipswPath,
      '${config.cpuCount}',
      '${config.memoryGB}',
    ]);

    process.stderr.transform(const SystemEncoding().decoder).listen((data) {
      if (onOutput != null) {
        for (final line in data.split('\n').where((l) => l.isNotEmpty)) {
          onOutput(line);
        }
      }
    });

    _forwardSignals(process);

    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw Exception('macOS installation failed (exit code: $exitCode)');
    }
  }

  /// Starts the VM.
  ///
  /// If [gui] is true, a native macOS window with VZVirtualMachineView
  /// is shown. Otherwise the VM runs headless.
  ///
  /// Returns the running [Process]. Use [stop] for graceful shutdown.
  Future<Process> start({
    bool gui = false,
    void Function(String line)? onOutput,
  }) async {
    _validateBundle(bundlePath);
    final installerPath = _findInstaller();

    final process = await Process.start(installerPath, [
      'start',
      if (gui) '--gui',
      bundlePath,
      '${config.cpuCount}',
      '${config.memoryGB}',
    ]);

    process.stderr.transform(const SystemEncoding().decoder).listen((data) {
      if (onOutput != null) {
        for (final line in data.split('\n').where((l) => l.isNotEmpty)) {
          onOutput(line);
        }
      }
    });

    _forwardSignals(process);

    return process;
  }

  /// Creates a copy-on-write clone of this VM bundle.
  ///
  /// On APFS, this is nearly instant regardless of disk size.
  /// Each clone gets a unique MachineIdentifier and MAC address.
  Future<MacVM> clone(String destPath, {VMConfig? config}) async {
    _validateBundle(bundlePath);

    if (Directory(destPath).existsSync()) {
      throw Exception('Destination already exists: $destPath');
    }

    final cpResult = await Process.run('cp', [
      '-c',
      '-r',
      bundlePath,
      destPath,
    ]);
    if (cpResult.exitCode != 0) {
      final cpFallback = await Process.run('cp', ['-r', bundlePath, destPath]);
      if (cpFallback.exitCode != 0) {
        throw Exception('Clone failed: ${cpFallback.stderr}');
      }
    }

    final rng = Random.secure();
    final macBytes = List.generate(6, (_) => rng.nextInt(256));
    macBytes[0] = (macBytes[0] | 0x02) & 0xFE;
    final macStr = macBytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(':');
    File(p.join(destPath, 'MACAddress')).writeAsStringSync(macStr);

    return MacVM._(bundlePath: destPath, config: config ?? this.config);
  }

  /// Discovers the VM's IP address from the ARP table using its MAC address.
  ///
  /// Returns `null` if the IP cannot be found (VM might not be running
  /// or network not yet initialized).
  Future<String?> discoverIP() async {
    final macFile = File(p.join(bundlePath, 'MACAddress'));
    if (!macFile.existsSync()) return null;

    final mac = macFile.readAsStringSync().trim().toLowerCase();
    final result = await Process.run('/usr/sbin/arp', ['-an']);
    if (result.exitCode != 0) return null;

    for (final line in (result.stdout as String).split('\n')) {
      if (line.toLowerCase().contains(mac)) {
        final match = RegExp(
          r'\(([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)\)',
        ).firstMatch(line);
        if (match != null) return match.group(1);
      }
    }
    return null;
  }

  /// The MAC address of the VM, if available.
  String? get macAddress {
    final file = File(p.join(bundlePath, 'MACAddress'));
    return file.existsSync() ? file.readAsStringSync().trim() : null;
  }

  /// Deletes the VM bundle from disk.
  Future<void> delete() async {
    final dir = Directory(bundlePath);
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  }

  static void _validateBundle(String bundlePath) {
    const requiredFiles = [
      'AuxiliaryStorage',
      'Disk.img',
      'HardwareModel',
      'MachineIdentifier',
    ];

    if (!Directory(bundlePath).existsSync()) {
      throw Exception('Bundle not found: $bundlePath');
    }

    for (final file in requiredFiles) {
      if (!File(p.join(bundlePath, file)).existsSync()) {
        throw Exception('Missing file in bundle: $file');
      }
    }
  }

  static String _findInstaller() {
    final script = Platform.script;
    final scriptDir = script.scheme == 'file'
        ? File.fromUri(script).parent.path
        : Directory.current.path;
    final installerPath = p.join(scriptDir, 'vm_installer');

    if (!File(installerPath).existsSync()) {
      throw Exception(
        'vm_installer binary not found at: $installerPath\n'
        'Build it with: swiftc -O -parse-as-library -o vm_installer '
        '-framework Virtualization -framework AppKit vm_installer.swift',
      );
    }

    return installerPath;
  }

  static void _loadVirtualizationFramework() {
    ffi.DynamicLibrary.open(
      '/System/Library/Frameworks/Virtualization.framework/Virtualization',
    );
  }

  static Future<VZMacOSRestoreImage> _loadRestoreImage(String path) async {
    VZMacOSRestoreImage? loadedImage;
    var completed = false;

    final url = objc.NSURL.fileURLWithPath(objc.NSString(path));

    VZMacOSRestoreImage.loadFileURL(
      url,
      completionHandler: ObjCBlock_ffiVoid_VZMacOSRestoreImage_NSError.listener(
        (VZMacOSRestoreImage? image, objc.NSError? error) {
          if (error != null) {
            throw Exception(
              'Failed to load IPSW: ${error.localizedDescription}',
            );
          }
          loadedImage = image;
          completed = true;
        },
      ),
    );

    while (!completed) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    return loadedImage!;
  }

  static void _forwardSignals(Process process) {
    ProcessSignal.sigint.watch().listen((_) {
      process.kill(ProcessSignal.sigint);
    });
    ProcessSignal.sigterm.watch().listen((_) {
      process.kill(ProcessSignal.sigterm);
    });
  }
}
