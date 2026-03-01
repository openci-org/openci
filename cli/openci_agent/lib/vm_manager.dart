import 'dart:io';
import 'dart:math';

import 'package:dart_avf/dart_avf.dart';

import 'models/vm_instance.dart';
import 'ssh_client.dart';

class VMManager {
  final String goldenImagePath;
  final String vmStoragePath;
  final String sshUser;
  final String sshPassword;
  final VMConfig defaultConfig;

  final Map<String, VMInstance> _vms = {};

  VMManager({
    required this.goldenImagePath,
    required this.vmStoragePath,
    this.sshUser = 'admin',
    this.sshPassword = 'admin',
    this.defaultConfig = const VMConfig(),
  });

  List<VMInstance> get allVMs => _vms.values.toList();

  VMInstance? getVM(String id) => _vms[id];

  Future<VMInstance> createVM({VMConfig? config}) async {
    final id = _generateId();
    final bundlePath = '$vmStoragePath/$id.bundle';
    final vmConfig = config ?? defaultConfig;

    final instance = VMInstance(id: id, bundlePath: bundlePath);
    _vms[id] = instance;

    try {
      final golden = MacVM.open(goldenImagePath);
      final clone = await golden.clone(bundlePath, config: vmConfig);

      instance.macAddress = clone.macAddress;
      instance.status = VMStatus.running;

      final process = await clone.start(
        onOutput: (line) => stderr.writeln('[$id] $line'),
      );
      instance.process = process;

      process.exitCode.then((_) {
        if (instance.status == VMStatus.running) {
          instance.status = VMStatus.stopped;
        }
      });

      await _waitForIP(instance, clone);
    } catch (e) {
      instance.status = VMStatus.error;
      rethrow;
    }

    return instance;
  }

  Future<SSHResult> execCommand(String vmId, String command) async {
    final instance = _vms[vmId];
    if (instance == null) throw Exception('VM not found: $vmId');
    if (instance.status != VMStatus.running) {
      throw Exception('VM is not running: ${instance.status.name}');
    }
    if (instance.ip == null) throw Exception('VM IP not yet discovered');

    final ssh = SSHClient(
      host: instance.ip!,
      user: sshUser,
      password: sshPassword,
    );

    return ssh.exec(command);
  }

  Future<void> deleteVM(String id) async {
    final instance = _vms[id];
    if (instance == null) throw Exception('VM not found: $id');

    instance.status = VMStatus.stopping;

    instance.process?.kill(ProcessSignal.sigterm);
    await instance.process?.exitCode.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        instance.process?.kill(ProcessSignal.sigkill);
        return -1;
      },
    );

    final vm = MacVM.open(instance.bundlePath);
    await vm.delete();

    instance.status = VMStatus.stopped;
    _vms.remove(id);
  }

  Future<void> shutdown() async {
    final ids = _vms.keys.toList();
    for (final id in ids) {
      try {
        await deleteVM(id);
      } catch (e) {
        stderr.writeln('Failed to delete VM $id: $e');
      }
    }
  }

  Future<void> _waitForIP(VMInstance instance, MacVM clone) async {
    for (var i = 0; i < 60; i++) {
      await Future<void>.delayed(const Duration(seconds: 1));
      final ip = await clone.discoverIP();
      if (ip != null) {
        instance.ip = ip;
        return;
      }
    }
  }

  String _generateId() {
    final rng = Random.secure();
    final bytes = List.generate(4, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
