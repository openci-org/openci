import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_firebase_admin/firestore.dart';
import 'package:googleapis/secretmanager/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:openci_worker_cli/constants.dart';
import 'package:openci_worker_cli/logger.dart';
import 'package:openci_worker_cli/run_manager.dart';
import 'package:openci_worker_cli/vm.dart';

Future<BuildJob?> claimBuildJob(Firestore firestore) async {
  final querySnapshot = await firestore
      .collection(buildJobsCollection)
      .where('status', WhereFilter.equal, 'queued')
      .orderBy('createdAt')
      .limit(1)
      .get();

  if (querySnapshot.docs.isEmpty) return null;

  final buildJobId = querySnapshot.docs.first.id;
  final jobRef = firestore.collection(buildJobsCollection).doc(buildJobId);

  final claimedData = await firestore.runTransaction((transaction) async {
    final snapshot = await transaction.get(jobRef);
    if (!snapshot.exists) return null;

    final data = snapshot.data();
    if (data == null || data['status'] != 'queued') return null;

    transaction.update(jobRef, {'status': 'in_progress'});
    return data;
  });

  if (claimedData == null) return null;

  final buildJob = BuildJob.fromJson({...claimedData, 'id': buildJobId});

  if (buildJob.commitSha == null || buildJob.commitSha!.isEmpty) {
    throw Exception('commitSha is missing in build job data');
  }

  return buildJob;
}

Future<bool> processJob(
  Firestore firestore,
  String projectId,
  String serviceAccountPath,
  String workerId, {
  void Function()? onJobFound,
}) async {
  final buildJob = await claimBuildJob(firestore);
  if (buildJob == null) return false;

  onJobFound?.call();

  final buildJobId = buildJob.id;
  final token = buildJob.installationToken!;
  final owner = buildJob.owner;
  final repo = buildJob.repo;
  final commitSha = buildJob.commitSha!;

  final runId = await initializeRun(firestore, buildJobId);

  final vmName = currentVmName(workerId: workerId, buildJobId: buildJobId);

  await logInfo(
    firestore,
    buildJobId,
    runId,
    'Processing job: $buildJobId for $owner/$repo',
  );

  await cloneVm(
    baseVmName: baseVmName,
    vmName: vmName,
    buildJobId: buildJobId,
    runId: runId,
    firestore: firestore,
  );

  Future<void> execCommand(String command) => execVmCommand(
    vmName: vmName,
    command: command,
    firestore: firestore,
    buildJobId: buildJobId,
    runId: runId,
    token: token,
  );

  Future<bool> isCancelled() async {
    try {
      final doc = await firestore
          .collection(buildJobsCollection)
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
    final workflowFileName = buildJob.workflowFileName;
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
      runVm(vmName).catchError((e) {
        vmStartError = e;
      }),
    );

    await logInfo(
      firestore,
      buildJobId,
      runId,
      'Waiting for VM to be ready...',
    );
    await waitForVmReady(vmName, vmStartError: () => vmStartError);
    await setupDirectSsh(vmName);
    final vmIp = await getVmIp(vmName);
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

    final pullRequestNumber = buildJob.pullRequestNumber;

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

    final envVars = await buildEnvVars(
      firestore: firestore,
      buildJob: buildJob,
      projectId: projectId,
      buildJobId: buildJobId,
      runId: runId,
    );

    final secretVars = await buildSecretVars(
      firestore: firestore,
      serviceAccountPath: serviceAccountPath,
      token: token,
      buildJobId: buildJobId,
      runId: runId,
      teamId: buildJob.teamId,
    );

    final envFileLines = <String>[];
    final secretFileLines = <String>[];

    for (final entry in envVars.entries) {
      final escaped = entry.value.replaceAll('\n', '\\n');
      envFileLines.add('${entry.key}=$escaped');
    }
    for (final entry in secretVars.entries) {
      final escaped = entry.value.replaceAll('\n', '\\n');
      secretFileLines.add('${entry.key}=$escaped');
    }

    final envFileContent = envFileLines.join('\n');
    final secretFileContent = secretFileLines.join('\n');

    await writeFileToVm(vmName, '/tmp/openci-env', envFileContent);
    await writeFileToVm(vmName, '/tmp/openci-secrets', secretFileContent);
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

    await writeFileToVm(vmName, '/tmp/openci-act.sh', actScript);
    await execCommand('chmod +x /tmp/openci-act.sh');

    await execCommandStreaming(
      ['/bin/zsh', '-l', '/tmp/openci-act.sh'],
      vmIp,
      firestore,
      buildJobId,
      runId,
      token,
      isCancelled: isCancelled,
    );

    await Future.delayed(const Duration(seconds: 5));

    await logInfo(firestore, buildJobId, runId, 'Build completed successfully');
    await updateRunStatus(
      firestore,
      buildJobId,
      runId,
      'completed',
      conclusion: 'success',
    );

    await firestore.collection(buildJobsCollection).doc(buildJobId).update({
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
    await updateRunStatus(
      firestore,
      buildJobId,
      runId,
      'completed',
      conclusion: 'failure',
    );

    await firestore.collection(buildJobsCollection).doc(buildJobId).update({
      'status': 'failure',
    });
    rethrow;
  } finally {
    await flushRemainingLogs();
    try {
      await stopVm(vmName);
    } catch (e) {
      await logWarning(firestore, buildJobId, runId, 'Error stopping VM: $e');
    }
    try {
      await deleteVm(vmName);
    } catch (e) {
      await logWarning(firestore, buildJobId, runId, 'Error deleting VM: $e');
    }
    await flushRemainingLogs();
    await pruneStaleVms(firestore, buildJobId, runId, workerId: workerId);
  }

  return true;
}

Future<Map<String, String>> buildEnvVars({
  required Firestore firestore,
  required BuildJob buildJob,
  required String projectId,
  required String buildJobId,
  required String runId,
}) async {
  final tagName = buildJob.tagName;
  final tagVersion = tagName != null && tagName.isNotEmpty
      ? (tagName.startsWith('v') || tagName.startsWith('V')
            ? tagName.substring(1)
            : tagName)
      : null;

  final teamId = buildJob.teamId;

  final envVars = <String, String>{
    'LANG': 'en_US.UTF-8',
    'OPENCI_PROJECT_ID': projectId,
    if (tagName != null && tagName.isNotEmpty) 'OPENCI_TAG': tagName,
    'OPENCI_TAG_VERSION': ?tagVersion,
    'OPENCI_TEAM_ID': ?teamId,
  };

  if (teamId != null) {
    final envVarsSnapshot = await firestore
        .collection(environmentVariablesCollection)
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

  return envVars;
}

Future<Map<String, String>> buildSecretVars({
  required Firestore firestore,
  required String serviceAccountPath,
  required String token,
  required String buildJobId,
  required String runId,
  String? teamId,
}) async {
  final saJsonCompact = jsonEncode(
    jsonDecode(File(serviceAccountPath).readAsStringSync()),
  );

  final secrets = <String, String>{
    'OPENCI_GCP_SA_JSON': saJsonCompact,
    'GITHUB_TOKEN': token,
  };

  if (teamId == null) return secrets;

  final secretsSnapshot = await firestore
      .collection(secretsCollection)
      .where('teamId', WhereFilter.equal, teamId)
      .get();

  if (secretsSnapshot.docs.isEmpty) return secrets;

  await logInfo(
    firestore,
    buildJobId,
    runId,
    'Loading ${secretsSnapshot.docs.length} secret(s) from Secret Manager...',
  );

  final saJson = jsonDecode(File(serviceAccountPath).readAsStringSync())
      as Map<String, dynamic>;
  final credentials = ServiceAccountCredentials.fromJson(saJson);
  final httpClient = await clientViaServiceAccount(
    credentials,
    [SecretManagerApi.cloudPlatformScope],
  );

  try {
    final smApi = SecretManagerApi(httpClient);

    for (final doc in secretsSnapshot.docs) {
      final data = doc.data();
      final name = data['name'] as String;
      final pathToSecret = data['pathToSecret'] as String?;
      if (pathToSecret == null) continue;

      try {
        final response = await smApi.projects.secrets.versions.access(
          '$pathToSecret/versions/latest',
        );
        final payload = response.payload?.data;
        if (payload != null) {
          secrets[name] = utf8.decode(base64Decode(payload));
        }
      } catch (e) {
        await logWarning(
          firestore,
          buildJobId,
          runId,
          'Failed to load secret "$name": $e',
        );
      }
    }
  } finally {
    httpClient.close();
  }

  await logInfo(
    firestore,
    buildJobId,
    runId,
    'Loaded ${secretsSnapshot.docs.length} secret(s)',
  );

  return secrets;
}
