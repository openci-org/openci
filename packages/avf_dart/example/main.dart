import 'package:avf_dart/avf_dart.dart';

void main() async {
  const vmName = 'my-alpine-vm';

  // 1. Clone the VM from the 'example' template
  await VirtualMachine.clone(sourceName: 'example', targetName: vmName);

  // 2. Boot the VM using the cloned VM name
  final vm = await VirtualMachine.boot(name: vmName);

  // 3. Let it run for a few seconds and stop the VM
  await Future<void>.delayed(const Duration(seconds: 10));

  // 4. Stop the VM
  await vm.stop();

  // 4. Delete the cloned VM
  await VirtualMachine.delete(vmName);
}
