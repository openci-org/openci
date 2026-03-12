import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_firebase_admin/firestore.dart';
import 'package:openci_worker_cli/constants.dart';
import 'package:openci_worker_cli/logger.dart';
import 'package:openci_worker_cli/run_manager.dart';
import 'package:openci_worker_cli/vm.dart';
import 'package:process_run/process_run.dart';

Future<bool> processJob(
  Firestore firestore,
  String projectId,
  String serviceAccountPath,
  String workerId,
  String buildJobId,
) async {
  final jobRef = firestore.collection('build_jobs_v0').doc(buildJobId);
  final snapshot = await jobRef.get();

  if (!snapshot.exists) return false;

  final data = snapshot.data();
  if (data == null || data['status'] != 'queued') {
    return false;
  }

  await jobRef.update({'status': 'in_progress'});

  final token = data['installationToken'] as String;
  final owner = data['owner'] as String;
  final repo = data['repo'] as String;
  final commitSha = data['commitSha'] as String?;

  if (commitSha == null || commitSha.isEmpty) {
    throw Exception('commitSha is missing in build job data');
  }

  final runDocRef = firestore
      .collection('build_jobs_v0')
      .doc(buildJobId)
      .collection('runs')
      .doc();
  final runId = runDocRef.id;
  final runManager = RunManager(firestore, buildJobId, runId);
  await runManager.initialize();

  await logInfo(
    firestore,
    buildJobId,
    runId,
    'Processing job: $buildJobId for $owner/$repo',
  );

  final currentVmName = 'openci-vm-$workerId-$buildJobId';
  await logInfo(
    firestore,
    buildJobId,
    runId,
    'Cloning VM $baseVmName to $currentVmName...',
  );
  await Shell().run('lume clone $baseVmName $currentVmName');

  Future<void> execCommand(String command) async {
    var shell = Shell(verbose: true, throwOnError: false);
    final results = await shell.run(
      "lume ssh $currentVmName --user $sshUser --password $sshPassword --timeout 0 -- $command",
    );

    for (final result in results) {
      final stdout = result.stdout?.toString().trim();
      final stderr = result.stderr?.toString().trim();

      if (stdout != null && stdout.isNotEmpty) {
        final maskedOutput = stdout.replaceAll(token, '***');
        await logInfo(firestore, buildJobId, runId, maskedOutput);
      }
      if (stderr != null && stderr.isNotEmpty) {
        final maskedOutput = stderr.replaceAll(token, '***');
        await logInfo(firestore, buildJobId, runId, maskedOutput);
      }

      if (result.exitCode != 0) {
        throw Exception('Command failed with exit code ${result.exitCode}');
      }
    }
  }

  Future<bool> isCancelled() async {
    try {
      final doc = await firestore
          .collection('build_jobs_v0')
          .doc(buildJobId)
          .get();
      if (!doc.exists) return false;
      final data = doc.data();
      return data?['status'] == 'cancelled';
    } catch (_) {
      return false;
    }
  }

  try {
    final workflowFileName = data['workflowFileName'] as String?;
    if (workflowFileName == null || workflowFileName.isEmpty) {
      await logError(
        firestore,
        buildJobId,
        runId,
        'workflowFileName is missing in build job data',
      );
      throw Exception('workflowFileName is missing');
    }

    await logInfo(firestore, buildJobId, runId, 'Workflow: $workflowFileName');

    Object? vmStartError;
    unawaited(
      runVm(currentVmName).catchError((e) {
        vmStartError = e;
      }),
    );

    await logInfo(
      firestore,
      buildJobId,
      runId,
      'Waiting for VM to be ready...',
    );
    await waitForVmReady(currentVmName, vmStartError: () => vmStartError);
    await logInfo(firestore, buildJobId, runId, 'VM is ready!');

    await logInfo(
      firestore,
      buildJobId,
      runId,
      'Cloning repository $owner/$repo...',
    );
    final cloneUrl =
        'https://x-access-token:$token@github.com/$owner/$repo.git';

    await execCommand('git clone --depth 1 --no-checkout $cloneUrl');

    final pullRequestNumber = data['pullRequestNumber'] as int?;

    await logInfo(
      firestore,
      buildJobId,
      runId,
      'Fetching commit $commitSha...',
    );
    try {
      await execCommand('git -C $repo fetch --depth 1 origin $commitSha');
    } catch (_) {
      if (pullRequestNumber != null) {
        await logInfo(
          firestore,
          buildJobId,
          runId,
          'Direct fetch failed, trying PR ref pull/$pullRequestNumber/head...',
        );
        await execCommand(
          'git -C $repo fetch --depth 1 origin pull/$pullRequestNumber/head',
        );
      } else {
        rethrow;
      }
    }

    await logInfo(
      firestore,
      buildJobId,
      runId,
      'Checking out commit $commitSha...',
    );
    await execCommand('git -C $repo checkout $commitSha');

    await logInfo(
      firestore,
      buildJobId,
      runId,
      'Repository cloned successfully',
    );

    await logInfo(firestore, buildJobId, runId, 'Setting up environment...');

    final tagName = data['tagName'] as String?;
    final tagVersion = tagName != null && tagName.isNotEmpty
        ? (tagName.startsWith('v') || tagName.startsWith('V')
              ? tagName.substring(1)
              : tagName)
        : null;

    final teamId = data['teamId'] as String?;

    final envVars = <String, String>{
      'LANG': 'en_US.UTF-8',
      'OPENCI_PROJECT_ID': projectId,
      if (tagName != null && tagName.isNotEmpty) 'OPENCI_TAG': tagName,
      'OPENCI_TAG_VERSION': ?tagVersion,
      'OPENCI_TEAM_ID': ?teamId,
    };

    final saJsonCompact = jsonEncode(
      jsonDecode(File(serviceAccountPath).readAsStringSync()),
    );

    final secretVars = <String, String>{
      'OPENCI_GCP_SA_JSON': saJsonCompact,
      'GITHUB_TOKEN': token,
    };

    if (teamId != null) {
      final envVarsSnapshot = await firestore
          .collection('environment_variables_v0')
          .where('teamId', WhereFilter.equal, teamId)
          .get();

      for (final envVarDoc in envVarsSnapshot.docs) {
        final envVarData = envVarDoc.data();
        final key = envVarData['key'] as String;
        var value = envVarData['value'] as String;
        final autoIncrement = envVarData['autoIncrement'] as bool? ?? false;

        if (autoIncrement) {
          final docRef = firestore.doc(
            'environment_variables_v0/${envVarDoc.id}',
          );
          await firestore.runTransaction((transaction) async {
            final freshDoc = await transaction.get(docRef);
            final currentValue = freshDoc.data()!['value'] as String;
            value = currentValue;
            final numValue = int.tryParse(currentValue);
            if (numValue != null) {
              transaction.update(docRef, {'value': '${numValue + 1}'});
            }
          });
          await logInfo(
            firestore,
            buildJobId,
            runId,
            'Auto-incremented $key: $value → ${int.parse(value) + 1}',
          );
        }

        envVars[key] = value;
      }

      if (envVarsSnapshot.docs.isNotEmpty) {
        await logInfo(
          firestore,
          buildJobId,
          runId,
          'Loaded ${envVarsSnapshot.docs.length} environment variable(s)',
        );
      }
    }

    if (tagName != null && tagName.isNotEmpty) {
      await logInfo(
        firestore,
        buildJobId,
        runId,
        'Tag: $tagName (available as \$OPENCI_TAG)',
      );
    }

    final envFileLines = <String>[];
    final secretFileLines = <String>[];

    for (final entry in envVars.entries) {
      envFileLines.add('${entry.key}=${entry.value}');
    }
    for (final entry in secretVars.entries) {
      secretFileLines.add('${entry.key}=${entry.value}');
    }

    final envFileContent = envFileLines.join('\n');
    final secretFileContent = secretFileLines.join('\n');

    await writeFileToVm(currentVmName, '/tmp/openci-env', envFileContent);
    await writeFileToVm(
      currentVmName,
      '/tmp/openci-secrets',
      secretFileContent,
    );
    await logInfo(
      firestore,
      buildJobId,
      runId,
      'Environment variables written',
    );

    await logInfo(firestore, buildJobId, runId, 'Running workflow with act...');

    final actScript = [
      'set -e',
      'export PATH="/Users/admin/flutter/bin:/opt/homebrew/bin:\$PATH"',
      'cd $repo',
      'act -W .openci/$workflowFileName '
          '-P macos-latest=-self-hosted '
          '-P macos-14=-self-hosted '
          '-P macos-15=-self-hosted '
          '-P ubuntu-latest=-self-hosted '
          '--env-file /tmp/openci-env '
          '--secret-file /tmp/openci-secrets '
          '--detect-event',
    ].join('\n');

    await writeFileToVm(currentVmName, '/tmp/openci-act.sh', actScript);
    await execCommand('chmod +x /tmp/openci-act.sh');

    await execCommandStreaming(
      ['/bin/zsh', '-l', '/tmp/openci-act.sh'],
      currentVmName,
      firestore,
      buildJobId,
      runId,
      token,
      isCancelled: isCancelled,
    );

    await Future.delayed(const Duration(seconds: 5));

    await logInfo(firestore, buildJobId, runId, 'Build completed successfully');
    await runManager.updateStatus('completed', conclusion: 'success');

    await firestore.collection('build_jobs_v0').doc(buildJobId).update({
      'status': 'success',
    });
  } catch (e, s) {
    await logError(
      firestore,
      buildJobId,
      runId,
      'Job failed: $e',
      stackTrace: s.toString(),
    );
    await runManager.updateStatus('completed', conclusion: 'failure');

    await firestore.collection('build_jobs_v0').doc(buildJobId).update({
      'status': 'failure',
    });
    rethrow;
  } finally {
    try {
      await stopVm(currentVmName);
    } catch (e) {
      await logWarning(firestore, buildJobId, runId, 'Error stopping VM: $e');
    }
    try {
      await deleteVm(currentVmName);
    } catch (e) {
      await logWarning(firestore, buildJobId, runId, 'Error deleting VM: $e');
    }
    await pruneStaleVms(firestore, buildJobId, runId, workerId: workerId);
  }

  return true;
}
