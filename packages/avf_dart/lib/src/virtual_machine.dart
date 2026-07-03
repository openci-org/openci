import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'avf_boot.dart';
import 'local_vm.dart';
import 'transfer_progress.dart';
import 'virtual_machine_manager.dart';
import 'virtual_machine_ssh.dart';
import 'virtual_machine_transfer.dart';

class VirtualMachine {
  final Process _process;
  final String name;
  final String? ipAddress;

  VirtualMachine._(this._process, this.name, this.ipAddress);

  /// Default directory where Virtual Machines are stored.
  /// Standard path on macOS: `~/Library/Application Support/avf_dart/vms`
  static String get defaultVmsDir {
    final home = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        Directory.systemTemp.path;
    if (Platform.isMacOS) {
      return '$home/Library/Application Support/avf_dart/vms';
    }
    return '$home/.local/share/avf_dart/vms';
  }

  /// Launches the macOS virtualization helper for the VM with the given [name].
  ///
  /// Under the hood, this resolves the VM directory, reads the machine metadata,
  /// and executes the helper binary.
  /// If [showLogs] is true, VM status updates and output logs will be printed to stdout.
  static Future<VirtualMachine> boot({
    required String name,
    String? customVmsDir,
    bool showLogs = true,
  }) async {
    if (showLogs) {
      print('Booting macOS VM "$name"...');
    }

    final vmsDir = customVmsDir ?? defaultVmsDir;
    final vmDir = '$vmsDir/$name';
    final Process process;
    try {
      process = await AppleVirtualization.bootFromDirectory(vmDir);
    } catch (e) {
      if (showLogs) {
        print('Failed to boot VM: $e');
      }
      rethrow;
    }

    final bootCompleter = Completer<void>();
    final errorSb = StringBuffer();
    String? resolvedIp;

    // Handle OS signals (SIGINT/SIGTERM) to shut down VM process gracefully
    late final StreamSubscription<ProcessSignal> sigintSub;
    late final StreamSubscription<ProcessSignal> sigtermSub;

    void cleanupSignals() {
      try {
        sigintSub.cancel();
        sigtermSub.cancel();
      } catch (_) {}
    }

    sigintSub = ProcessSignal.sigint.watch().listen((signal) async {
      if (showLogs) {
        print('\nReceived SIGINT. Stopping VM gracefully...');
      }
      process.kill(ProcessSignal.sigterm);
      cleanupSignals();
      await process.exitCode;
      exit(0);
    });

    sigtermSub = ProcessSignal.sigterm.watch().listen((signal) async {
      if (showLogs) {
        print('\nReceived SIGTERM. Stopping VM gracefully...');
      }
      process.kill(ProcessSignal.sigterm);
      cleanupSignals();
      await process.exitCode;
      exit(0);
    });

    // Monitor stdout line by line
    final stdoutSubscription = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      if (showLogs) {
        print(line);
      }
      if (!bootCompleter.isCompleted) {
        final ipMatch = RegExp(r'VM started successfully! IP:\s+([0-9.]+)')
            .firstMatch(line);
        if (ipMatch != null) {
          resolvedIp = ipMatch.group(1);
          bootCompleter.complete();
        } else if (line.contains('VM started successfully!')) {
          bootCompleter.complete();
        } else if (line.contains('Error:')) {
          bootCompleter.completeError(StateError(line));
        }
      }
    });

    // Monitor stderr
    final stderrSubscription =
        process.stderr.transform(utf8.decoder).listen((data) {
      if (showLogs) {
        stderr.write(data);
      }
      errorSb.write(data);
      if (!bootCompleter.isCompleted && errorSb.toString().contains('Error:')) {
        final lines = errorSb.toString().split('\n');
        final errorLine = lines.firstWhere((l) => l.contains('Error:'),
            orElse: () => errorSb.toString());
        bootCompleter.completeError(StateError(errorLine.trim()));
      }
    });

    // Monitor process exit in case it terminates before boot success
    process.exitCode.then((code) {
      cleanupSignals();
      if (showLogs) {
        print('\nVM "$name" exited with code $code');
      }
      if (!bootCompleter.isCompleted) {
        final errMessage = errorSb.isNotEmpty
            ? errorSb.toString().trim()
            : 'VM process exited prematurely with code $code';
        bootCompleter.completeError(StateError(errMessage));
      }
    });

    try {
      await bootCompleter.future;
    } catch (e) {
      cleanupSignals();
      await stdoutSubscription.cancel();
      await stderrSubscription.cancel();
      process.kill(ProcessSignal.sigterm);
      await process.exitCode;
      rethrow;
    }

    if (resolvedIp != null) {
      if (showLogs) {
        print(
            'Guest IP allocated: $resolvedIp. Checking SSH readiness (Dart)...');
      }
      final portOpen = await _waitForSshPort(resolvedIp!,
          timeout: const Duration(minutes: 5), showLogs: showLogs);
      if (!portOpen) {
        cleanupSignals();
        await stdoutSubscription.cancel();
        await stderrSubscription.cancel();
        process.kill(ProcessSignal.sigterm);
        await process.exitCode;
        throw StateError('Error: Timeout waiting for SSH port to open (Dart).');
      }
    }

    cleanupSignals();
    return VirtualMachine._(process, name, resolvedIp);
  }

  static Future<bool> _waitForSshPort(String ip,
      {required Duration timeout, required bool showLogs}) async {
    final stopTime = DateTime.now().add(timeout);

    if (showLogs) {
      print('Debug: Waiting for guest OS network to respond via ping...');
    }

    // Phase 1: Wait for ping to succeed (resolves ARP and ensures routing is active)
    bool pingSuccess = false;
    while (DateTime.now().isBefore(stopTime)) {
      try {
        final res = await Process.run('/sbin/ping', ['-c', '1', '-t', '1', ip])
            .timeout(const Duration(seconds: 2));
        if (res.exitCode == 0) {
          pingSuccess = true;
          if (showLogs) {
            print('Debug: Guest OS network responded to ping successfully!');
          }
          break;
        } else {
          if (showLogs) {
            print(
                'Debug: Guest OS network not responding to ping yet (exitCode: ${res.exitCode})');
          }
        }
      } catch (e) {
        if (showLogs) {
          print('Debug: Ping execution failed: $e');
        }
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }

    if (!pingSuccess) {
      if (showLogs) {
        print(
            'Debug: Timeout waiting for guest OS network to respond to ping.');
      }
      return false;
    }

    // Phase 2: Ping succeeded, now wait for SSH port 22 to open.
    if (showLogs) {
      print('Debug: Guest network is up. Waiting for SSH port 22 to open on $ip...');
    }

    while (DateTime.now().isBefore(stopTime)) {
      try {
        final res = await Process.run(
          '/usr/bin/nc',
          ['-z', '-G', '5', '-w', '5', ip, '22'],
        ).timeout(const Duration(seconds: 8));
        if (res.exitCode == 0) {
          return true;
        }
        if (showLogs) {
          print(
              'Debug: SSH port 22 not open yet for $ip (nc exit ${res.exitCode})');
        }
      } catch (e) {
        if (showLogs) {
          print('Debug: SSH port probe failed for $ip: $e');
        }
      }
      await Future<void>.delayed(const Duration(seconds: 5));
    }
    return false;
  }

  /// Stops the VM process gracefully (sends SIGTERM).
  Future<void> stop() async {
    _process.kill(ProcessSignal.sigterm);
    await _process.exitCode;
  }

  /// Returns the future that completes when the VM process terminates.
  Future<int> get exitCode => _process.exitCode;

  /// Starts a new macOS VM installation using the provided IPSW image file.
  ///
  /// This creates the installation directory under [customVmsDir] (or [defaultVmsDir]),
  /// allocates a blank disk image, and runs the macOS installer.
  /// The progress update (0.0 to 1.0) is notified via the [onProgress] callback.
  static Future<void> install({
    required String name,
    required String ipswPath,
    String? customVmsDir,
    void Function(double progress)? onProgress,
  }) async {
    await VirtualMachineManager.install(
      name: name,
      ipswPath: ipswPath,
      customVmsDir: customVmsDir,
      onProgress: onProgress,
    );
  }

  /// Clones the VM assets from [sourceName] to [targetName].
  ///
  /// It clones the config.json, disk.img, and nvram.bin from the existing VM directory
  /// under [customVmsDir] (or [defaultVmsDir]).
  /// If [showLogs] is true, status updates will be printed.
  static Future<void> clone({
    required String sourceName,
    required String targetName,
    String? customVmsDir,
    bool showLogs = true,
  }) async {
    await VirtualMachineManager.clone(
      sourceName: sourceName,
      targetName: targetName,
      customVmsDir: customVmsDir,
      showLogs: showLogs,
    );
  }

  /// Deletes the VM directory with the given [name] under [customVmsDir] (or [defaultVmsDir]).
  ///
  /// If [showLogs] is true, status updates will be printed.
  static Future<void> delete(
    String name, {
    String? customVmsDir,
    bool showLogs = true,
  }) async {
    await VirtualMachineManager.delete(
      name,
      customVmsDir: customVmsDir,
      showLogs: showLogs,
    );
  }

  /// Downloads a file from the given [uri] to [savePath] with progress notifications.
  /// Supports parallel connections and resuming from partial download state.
  ///
  /// The progress (0.0 to 1.0) is notified via the [onProgress] callback.
  static Future<void> downloadIpsw({
    required Uri uri,
    required String savePath,
    int concurrency = 8,
    bool force = false,
    void Function(TransferProgress progress)? onProgress,
  }) async {
    await VirtualMachineTransfer.downloadIpsw(
      uri: uri,
      savePath: savePath,
      concurrency: concurrency,
      force: force,
      onProgress: onProgress,
    );
  }

  /// Lists all local Virtual Machines available in the VM directory.
  static Future<List<LocalVM>> list({String? customVmsDir}) async {
    return VirtualMachineManager.list(customVmsDir: customVmsDir);
  }

  /// Compresses the VM directory and uploads it to Firebase Storage (Google Cloud Storage) via Pure Dart.
  ///
  /// Uses macOS standard `tar -czf` and Google Cloud Storage Resumable Upload protocol.
  static Future<void> push({
    required String name,
    required String bucket,
    required String accessToken,
    String? customVmsDir,
    void Function(String log)? onLog,
    void Function(TransferProgress progress)? onProgress,
  }) async {
    await VirtualMachineTransfer.push(
      name: name,
      bucket: bucket,
      accessToken: accessToken,
      customVmsDir: customVmsDir,
      onLog: onLog,
      onProgress: onProgress,
    );
  }

  /// Executes a [command] on the guest VM via SSH, streaming standard output
  /// and standard error to the optional [onStdout] and [onStderr] callbacks.
  ///
  /// Returns the exit code of the command when it finishes.
  Future<int> executeStream(
    String command, {
    String username = 'admin',
    String? password,
    String? privateKeyPath,
    int port = 22,
    void Function(String data)? onStdout,
    void Function(String data)? onStderr,
  }) async {
    return VirtualMachineSsh.executeStream(
      command,
      ipAddress: ipAddress,
      username: username,
      password: password,
      privateKeyPath: privateKeyPath,
      port: port,
      onStdout: onStdout,
      onStderr: onStderr,
    );
  }

  /// Downloads a VM archive from Firebase Storage and decompresses it locally via Pure Dart.
  ///
  /// Uses HTTP Range requests for resume capability and macOS standard `tar -xzf`.
  static Future<void> pull({
    required String name,
    required String bucket,
    required String accessToken,
    String? customVmsDir,
    void Function(String log)? onLog,
    void Function(TransferProgress progress)? onProgress,
  }) async {
    await VirtualMachineTransfer.pull(
      name: name,
      bucket: bucket,
      accessToken: accessToken,
      customVmsDir: customVmsDir,
      onLog: onLog,
      onProgress: onProgress,
    );
  }
}
