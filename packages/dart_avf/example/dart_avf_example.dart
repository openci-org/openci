import 'package:dart_avf/dart_avf.dart';

void main() async {
  // Create and install a macOS VM
  final vm = await MacVM.create(
    bundlePath: '/tmp/example-vm.bundle',
    ipswPath: '/tmp/macos.ipsw',
    config: const VMConfig(cpuCount: 4, memoryGB: 8, diskSizeGB: 64),
    onOutput: print,
  );

  // Start with GUI window
  final process = await vm.start(gui: true, onOutput: print);

  // Discover IP for SSH access
  await Future<void>.delayed(const Duration(seconds: 10));
  final ip = await vm.discoverIP();
  if (ip != null) {
    print('VM is reachable at: $ip');
    print('SSH: ssh admin@$ip');
  }

  // Clone for ephemeral CI jobs (instant on APFS)
  final clone = await vm.clone('/tmp/ci-job-vm.bundle');
  print('Clone MAC: ${clone.macAddress}');

  // Cleanup
  await clone.delete();
  await process.exitCode;
}
