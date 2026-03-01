import 'dart:io';

import 'package:dart_avf/dart_avf.dart';

import 'github.dart';
import 'ssh_exec.dart';
import 'supabase_client.dart';

class BuildExecutor {
  final String goldenImagePath;
  final String vmStoragePath;
  final String sshUser;
  final String sshPassword;
  final String workerId;
  final SupabaseWorkerClient supabase;

  BuildExecutor({
    required this.goldenImagePath,
    required this.vmStoragePath,
    required this.workerId,
    required this.supabase,
    this.sshUser = 'admin',
    this.sshPassword = 'admin',
  });

  Future<String> execute(Build build, {void Function(String)? onLog}) async {
    final vmId = 'openci-vm-$workerId-${build.id.substring(0, 8)}';
    final bundlePath = '$vmStoragePath/$vmId.bundle';

    final log = onLog ?? print;
    final buildRunId = await supabase.createBuildRun(build.id);

    void addLog(String message, {String level = 'info'}) {
      log(message);
      if (buildRunId != null) {
        supabase
            .insertLog(buildRunId, build.id, message, level)
            .catchError((_) {});
      }
    }

    Process? vmProcess;

    try {
      await updateCheckRunStatus(build, status: 'in_progress');

      addLog('Worker: $workerId on ${Platform.localHostname}');

      final golden = MacVM.open(goldenImagePath);
      addLog('Cloning VM → $vmId');
      final vm = await golden.clone(bundlePath);

      addLog('Starting VM (headless)...');
      vmProcess = await vm.start(onOutput: (line) => addLog('  $line'));

      addLog('Waiting for VM to boot...');
      String? vmIP;
      for (var i = 0; i < 60; i++) {
        vmIP = await vm.discoverIP();
        if (vmIP != null) break;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      if (vmIP == null) throw Exception('VM boot timeout: IP not discovered');
      addLog('VM ready: $vmIP');

      addLog('Waiting for SSH...');
      final ssh = SSHExec(host: vmIP, user: sshUser, password: sshPassword);
      await ssh.waitForReady();
      addLog('SSH ready');

      final owner = build.githubOwner;
      final repo = build.githubRepo;
      final commitSha = build.commitSha;
      final token = build.installationToken;

      final cloneUrl = token != null
          ? 'https://x-access-token:$token@github.com/$owner/$repo.git'
          : 'https://github.com/$owner/$repo.git';

      addLog('Cloning $owner/$repo...');
      await ssh.run('git clone --depth 1 $cloneUrl');

      if (commitSha != null) {
        addLog('Checking out $commitSha...');
        final fetchResult = await ssh.run(
          'cd $repo && git fetch --depth 1 origin $commitSha && git checkout $commitSha',
        );
        if (fetchResult.exitCode != 0 && build.pullRequestNumber != null) {
          addLog('Direct fetch failed, trying PR ref...');
          await ssh.run(
            'cd $repo && git fetch origin pull/${build.pullRequestNumber}/head && git checkout FETCH_HEAD',
          );
        }
      }

      final yamlDef = build.yamlDefinition;
      if (yamlDef == null) throw Exception('No workflow YAML found');

      addLog('Writing workflow YAML...');
      final escapedYaml = yamlDef.replaceAll("'", "'\\''");
      await ssh.run(
        "mkdir -p $repo/.github/workflows && echo '$escapedYaml' > $repo/.github/workflows/openci.yaml",
      );

      addLog('Installing act...');
      await ssh.run('which act || brew install act');

      addLog('Running workflow with act...');
      final actResult = await ssh.run(
        'cd $repo && act push -P macos-latest=-self-hosted 2>&1',
        timeoutSeconds: 1800,
      );

      if (actResult.stdout.isNotEmpty) addLog(actResult.stdout);
      if (actResult.exitCode != 0) {
        throw Exception('act failed with exit code ${actResult.exitCode}');
      }

      addLog('Build completed successfully!');
      await supabase.updateBuildStatus(build.id, 'success');
      if (buildRunId != null) {
        await supabase.completeBuildRun(buildRunId, 'success');
      }
      await updateCheckRunStatus(
        build,
        status: 'completed',
        conclusion: 'success',
        summary: 'All steps passed.',
      );
      return 'success';
    } catch (e) {
      final message = e.toString();
      addLog('Build failed: $message', level: 'error');
      await supabase.updateBuildStatus(build.id, 'failure');
      if (buildRunId != null) {
        await supabase.completeBuildRun(buildRunId, 'failure');
      }
      await updateCheckRunStatus(
        build,
        status: 'completed',
        conclusion: 'failure',
        summary: message,
      );
      return 'failure';
    } finally {
      addLog('Cleaning up VM...');
      vmProcess?.kill(ProcessSignal.sigterm);
      await vmProcess?.exitCode.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          vmProcess?.kill(ProcessSignal.sigkill);
          return -1;
        },
      );
      try {
        final dir = Directory(bundlePath);
        if (dir.existsSync()) await dir.delete(recursive: true);
      } catch (_) {}
    }
  }

  Future<List<String>> cleanupOrphanedVMs() async {
    final cleaned = <String>[];
    final storageDir = Directory(vmStoragePath);
    if (!storageDir.existsSync()) return cleaned;

    final prefix = 'openci-vm-$workerId-';
    for (final entity in storageDir.listSync()) {
      if (entity is Directory) {
        final name = entity.path.split('/').last;
        if (name.startsWith(prefix)) {
          await entity.delete(recursive: true);
          cleaned.add(name);
        }
      }
    }
    return cleaned;
  }
}
