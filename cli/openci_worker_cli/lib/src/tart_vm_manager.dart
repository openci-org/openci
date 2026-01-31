import 'package:process_run/process_run.dart';

/// Abstract class for running shell commands.
/// This allows for easy mocking in tests.
abstract class ShellRunner {
  Future<List<ProcessResult>> run(String command);
}

/// Default implementation of [ShellRunner] using process_run package.
class DefaultShellRunner implements ShellRunner {
  final bool throwOnError;

  DefaultShellRunner({this.throwOnError = false});

  @override
  Future<List<ProcessResult>> run(String command) async {
    var shell = Shell(throwOnError: throwOnError);
    return await shell.run(command);
  }
}

/// Manages tart VM operations including stop, delete, and cleanup.
class TartVmManager {
  final ShellRunner _shellRunner;

  TartVmManager({ShellRunner? shellRunner})
      : _shellRunner = shellRunner ?? DefaultShellRunner();

  /// Stops a VM using tart command.
  /// Returns true if the VM was stopped successfully, false otherwise.
  Future<bool> stopVm(String vmName) async {
    final results = await _shellRunner.run('tart stop $vmName');
    final exitCode = results.isNotEmpty ? results.first.exitCode : -1;
    return exitCode == 0;
  }

  /// Deletes a VM using tart command.
  /// Returns true if the VM was deleted successfully, false otherwise.
  Future<bool> deleteVm(String vmName) async {
    final results = await _shellRunner.run('tart delete $vmName');
    final exitCode = results.isNotEmpty ? results.first.exitCode : -1;
    return exitCode == 0;
  }

  /// Cleans up a VM by stopping and deleting it.
  /// Returns a [CleanupResult] containing the results of both operations.
  Future<CleanupResult> cleanupVm(String vmName) async {
    final stopResult = await stopVm(vmName);

    // Wait a moment for the VM to fully stop before deletion
    await Future.delayed(const Duration(seconds: 2));

    final deleteResult = await deleteVm(vmName);

    return CleanupResult(
      vmName: vmName,
      stopSucceeded: stopResult,
      deleteSucceeded: deleteResult,
    );
  }
}

/// Result of a VM cleanup operation.
class CleanupResult {
  final String vmName;
  final bool stopSucceeded;
  final bool deleteSucceeded;

  CleanupResult({
    required this.vmName,
    required this.stopSucceeded,
    required this.deleteSucceeded,
  });

  /// Returns true if both stop and delete operations succeeded.
  bool get isFullyCleanedUp => stopSucceeded && deleteSucceeded;
}
