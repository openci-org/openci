import 'dart:io';
import 'package:avf_dart/avf_dart.dart';

void main() async {
  const sourceName = 'tahoe-base_v1.1.1';
  const targetName = 'tahoe-test-lifecycle-check';

  print('1. Cloning $sourceName to $targetName...');
  try {
    // 既存のテストVMがあれば削除しておく
    try {
      await VirtualMachine.delete(targetName);
      print('Deleted existing test VM.');
    } catch (_) {}

    await VirtualMachine.clone(sourceName: sourceName, targetName: targetName);
    print('Clone success.');

    print('2. Booting $targetName...');
    final vm = await VirtualMachine.boot(name: targetName);
    print('Boot success! Guest IP: ${vm.ipAddress}');

    print('3. Running check command via SSH...');
    final exitStatus = await vm.executeStream(
      'uname -a && uptime',
      username: 'admin',
      password: 'admin',
      onStdout: (data) => stdout.write(data),
      onStderr: (data) => stderr.write(data),
    );
    print('\nCommand finished with exit code: $exitStatus');

    print('4. Stopping VM...');
    await vm.stop();
    print('VM stopped.');

    print('5. Deleting VM...');
    await VirtualMachine.delete(targetName);
    print('VM deleted.');
    print('SUCCESS: VM Lifecycle test completed successfully.');
  } catch (e) {
    print('ERROR: Test failed: $e');
    // クリーンアップ
    try {
      await VirtualMachine.delete(targetName);
    } catch (_) {}
    exit(1);
  }
}
