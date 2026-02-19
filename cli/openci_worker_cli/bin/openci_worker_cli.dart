import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_firebase_admin/dart_firebase_admin.dart';
import 'package:dart_firebase_admin/firestore.dart';
import 'package:googleapis/secretmanager/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:process_run/process_run.dart';
import 'package:uuid/uuid.dart';

const String version = '0.4.31';

enum LogLevel { info, warning, error }

class CancelledException implements Exception {
  final String message;
  CancelledException([this.message = 'Build was cancelled']);

  @override
  String toString() => message;
}

class BuildLogger {
  final Firestore _firestore;
  final String _buildJobId;
  final String _runId;

  BuildLogger(this._firestore, this._buildJobId, this._runId);

  String get runId => _runId;

  Future<void> _writeToFirestore(
    String message,
    LogLevel level, {
    String? stackTrace,
  }) async {
    try {
      final logRef = _firestore
          .collection('build_jobs_v0')
          .doc(_buildJobId)
          .collection('runs')
          .doc(_runId)
          .collection('logs')
          .doc();

      await logRef.set({
        'message': message,
        'level': level.name,
        'timestamp': FieldValue.serverTimestamp,
        'stackTrace': ?stackTrace,
      });
    } catch (e) {
      print('[BuildLogger] Failed to write log to Firestore: $e');
    }
  }

  Future<void> info(String message) async {
    print('[INFO] $message');
    await _writeToFirestore(message, LogLevel.info);
  }

  Future<void> warning(String message) async {
    print('[WARNING] $message');
    await _writeToFirestore(message, LogLevel.warning);
  }

  Future<void> error(String message, {String? stackTrace}) async {
    print('[ERROR] $message');
    if (stackTrace != null) {
      print('[ERROR] Stack trace: $stackTrace');
    }
    await _writeToFirestore(message, LogLevel.error, stackTrace: stackTrace);
  }

  Future<void> updateRunStatus(String status, {String? conclusion}) async {
    try {
      await _firestore
          .collection('build_jobs_v0')
          .doc(_buildJobId)
          .collection('runs')
          .doc(_runId)
          .update({
            'status': status,
            'updatedAt': FieldValue.serverTimestamp,
            'conclusion': ?conclusion,
          });
    } catch (e) {
      print('[BuildLogger] Failed to update run status: $e');
    }
  }

  Future<void> initializeRun() async {
    try {
      await _firestore
          .collection('build_jobs_v0')
          .doc(_buildJobId)
          .collection('runs')
          .doc(_runId)
          .set({
            'id': _runId,
            'createdAt': FieldValue.serverTimestamp,
            'status': 'in_progress',
          });

      await _firestore.collection('build_jobs_v0').doc(_buildJobId).update({
        'latestRunId': _runId,
        'runCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('[BuildLogger] Failed to initialize run: $e');
    }
  }
}

ArgParser buildParser() {
  return ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    )
    ..addFlag('version', negatable: false, help: 'Print the tool version.')
    ..addFlag(
      'update',
      abbr: 'u',
      negatable: false,
      help: 'Update to the latest version.',
    )
    ..addOption(
      'service-account',
      help: 'The path to the service account JSON file.',
    )
    ..addOption(
      'worker-id',
      help: 'Unique ID for this worker (e.g., worker-1, worker-2).',
    );
}

void printUsage(ArgParser argParser) {
  print('Usage: openci_worker <flags> [arguments]');
  print(argParser.usage);
}

Future<void> main(List<String> arguments) async {
  final argParser = buildParser();

  try {
    final results = argParser.parse(arguments);

    if (results.flag('help')) {
      printUsage(argParser);
      return;
    }
    if (results.flag('version')) {
      print('openci_worker version: $version');
      return;
    }
    if (results.flag('update')) {
      print('Updating openci_worker...');
      final shell = Shell(verbose: true);
      await shell.run('dart pub global activate openci_worker_cli');
      print('Updated successfully!');
      return;
    }

    final String? serviceAccountPath = results['service-account'];
    final String? workerId = results['worker-id'];

    if (serviceAccountPath == null || workerId == null) {
      print('Error: --service-account and --worker-id are required.');
      printUsage(argParser);
      return;
    }

    final serviceAccountFile = File(serviceAccountPath);
    if (!serviceAccountFile.existsSync()) {
      print('Error: Service account file not found: $serviceAccountPath');
      return;
    }

    final serviceAccountJson =
        jsonDecode(serviceAccountFile.readAsStringSync())
            as Map<String, dynamic>;
    final projectId = serviceAccountJson['project_id'] as String?;
    if (projectId == null || projectId.isEmpty) {
      print('Error: project_id not found in service account file.');
      return;
    }

    final admin = FirebaseAdminApp.initializeApp(
      projectId,
      Credential.fromServiceAccount(serviceAccountFile),
    );

    final firestore = Firestore(admin);

    print('Worker started. Worker ID: $workerId');
    print('Cleaning up orphaned VMs from previous runs...');
    await cleanupOrphanedVms(workerId);
    print('Polling for jobs...');

    final spinnerChars = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
    int spinnerIndex = 0;
    var waitingStartTime = DateTime.now();
    int pollCounter = 0;
    const pollInterval = 10;

    while (true) {
      bool jobFound = false;

      if (pollCounter == 0) {
        try {
          jobFound = await processJob(
            firestore,
            projectId,
            serviceAccountPath,
            workerId,
          );
        } catch (e) {
          print('\nError processing job: $e');
        }

        try {
          final shouldRestart = await checkForUpdate(firestore);
          if (shouldRestart) {
            print('\n🔄 Update complete. Restarting worker...');
            await Process.start('openci_worker', [
              '--service-account',
              serviceAccountPath,
              '--worker-id',
              workerId,
            ], mode: ProcessStartMode.inheritStdio);
            exit(0);
          }
        } catch (e) {
          print('\n[WARN] Update check failed: $e');
        }
      }

      if (!jobFound) {
        final elapsed = DateTime.now().difference(waitingStartTime);
        final minutes = elapsed.inMinutes;
        final seconds = elapsed.inSeconds % 60;
        final timeStr = '${minutes}m ${seconds}s';
        stdout.write(
          '\r${spinnerChars[spinnerIndex]} [$workerId] Waiting for jobs... ($timeStr)  ',
        );
        spinnerIndex = (spinnerIndex + 1) % spinnerChars.length;
        pollCounter = (pollCounter + 1) % pollInterval;
        await Future.delayed(const Duration(milliseconds: 100));
      } else {
        print('');
        waitingStartTime = DateTime.now();
        pollCounter = 0;
      }
    }
  } on FormatException catch (e) {
    print(e.message);
    print('');
    printUsage(argParser);
  } catch (e) {
    print('Unexpected error: $e');
    exit(1);
  }
}

Future<bool> checkForUpdate(Firestore firestore) async {
  final configDoc = await firestore
      .collection('worker_config_v0')
      .doc('latest_version')
      .get();

  if (!configDoc.exists) return false;

  final data = configDoc.data();
  if (data == null) return false;

  final latestVersion = data['version'] as String?;
  if (latestVersion == null || latestVersion == version) return false;

  print('\n📦 New version available: $version → $latestVersion');
  print('Updating...');

  final shell = Shell(verbose: true);
  await shell.run('dart pub global activate openci_worker_cli');

  return true;
}

Future<bool> processJob(
  Firestore firestore,
  String projectId,
  String serviceAccountPath,
  String workerId,
) async {
  final doc = await firestore
      .collection('build_jobs_v0')
      .where('status', WhereFilter.equal, 'queued')
      .orderBy('createdAt', descending: false)
      .limit(1)
      .get();

  if (doc.docs.isEmpty) {
    return false;
  }

  final candidateRef = doc.docs.first.ref;

  final claimedJob = await firestore.runTransaction((transaction) async {
    final snapshot = await transaction.get(candidateRef);
    if (!snapshot.exists) return null;

    final data = snapshot.data();
    if (data == null || data['status'] != 'queued') {
      return null;
    }

    transaction.update(candidateRef, {'status': 'in_progress'});
    return snapshot;
  });

  if (claimedJob == null) {
    return false;
  }

  final buildJobId = claimedJob.id;
  final buildJobData = claimedJob.data()!;
  final token = buildJobData['installationToken'] as String;
  final owner = buildJobData['owner'] as String;
  final repo = buildJobData['repo'] as String;
  final commitSha = buildJobData['commitSha'] as String?;
  final checkRunId = buildJobData['checkRunId'] as int?;

  if (commitSha == null || commitSha.isEmpty) {
    throw Exception('commitSha is missing in build job data');
  }

  final runDocRef = firestore
      .collection('build_jobs_v0')
      .doc(buildJobId)
      .collection('runs')
      .doc();
  final runId = runDocRef.id;
  final logger = BuildLogger(firestore, buildJobId, runId);
  await logger.initializeRun();

  await logger.info('Processing job: $buildJobId for $owner/$repo');

  if (checkRunId != null) {
    await logger.info('Updating check run to in_progress...');
    await updateCheckRun(owner, repo, checkRunId, token, status: 'in_progress');
  }

  final currentVmName = 'openci-vm-$workerId-$buildJobId';
  await logger.info('Cloning VM $baseVmName to $currentVmName...');
  await Shell().run('tart clone $baseVmName $currentVmName');

  Future<void> execCommand(String command, {String? displayCommand}) async {
    var shell = Shell(verbose: true, throwOnError: false);
    final results = await shell.run("tart exec $currentVmName $command");

    for (final result in results) {
      final stdout = result.stdout?.toString().trim();
      final stderr = result.stderr?.toString().trim();

      if (stdout != null && stdout.isNotEmpty) {
        final maskedOutput = stdout.replaceAll(token, '***');
        await logger.info(maskedOutput);
      }
      if (stderr != null && stderr.isNotEmpty) {
        final maskedOutput = stderr.replaceAll(token, '***');
        await logger.info(maskedOutput);
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

  Future<void> checkCancellation() async {
    if (await isCancelled()) {
      throw CancelledException();
    }
  }

  try {
    final workflowId = buildJobData['workflowId'] as String?;
    if (workflowId == null || workflowId.isEmpty) {
      await logger.error('workflowId is missing in build job data');
      throw Exception('workflowId is missing');
    }

    final workflowDoc = await firestore
        .collection('workflows_v1')
        .doc(workflowId)
        .get();

    if (!workflowDoc.exists) {
      await logger.error('Workflow not found: $workflowId');
      throw Exception('Workflow not found');
    }

    final workflowData = workflowDoc.data()!;
    final steps = workflowData['workflowSteps'] as List;
    final workflowConfig =
        workflowData['workflowConfig'] as Map<String, dynamic>?;
    final cwd = workflowConfig?['selectedWorkingDirectory'] as String?;

    await logger.info('Loaded workflow with ${steps.length} steps');
    await logger.info('Working directory: ${cwd ?? "(root)"}');

    Object? vmStartError;
    unawaited(
      runTart(currentVmName).catchError((e) {
        vmStartError = e;
      }),
    );

    await logger.info('Waiting for VM to be ready...');
    await waitForVmReady(currentVmName, vmStartError: () => vmStartError);
    await logger.info('VM is ready!');

    await logger.info('Cloning repository $owner/$repo...');
    final cloneUrl =
        'https://x-access-token:$token@github.com/$owner/$repo.git';

    await execCommand('git clone --progress $cloneUrl');

    final pullRequestNumber = buildJobData['pullRequestNumber'] as int?;

    await logger.info('Fetching commit $commitSha...');
    try {
      await execCommand('git -C $repo fetch origin $commitSha');
    } catch (_) {
      if (pullRequestNumber != null) {
        await logger.info(
          'Direct fetch failed, trying PR ref pull/$pullRequestNumber/head...',
        );
        await execCommand(
          'git -C $repo fetch origin pull/$pullRequestNumber/head',
        );
      } else {
        rethrow;
      }
    }

    await logger.info('Checking out commit $commitSha...');
    await execCommand('git -C $repo checkout $commitSha');

    await logger.info('Repository cloned successfully');

    String workingDirectory = repo;
    if (cwd != null && cwd.isNotEmpty) {
      workingDirectory = '$repo/$cwd';
    }

    final tagName = buildJobData['tagName'] as String?;
    final tagVersion = tagName != null && tagName.isNotEmpty
        ? (tagName.startsWith('v') || tagName.startsWith('V')
              ? tagName.substring(1)
              : tagName)
        : null;

    final teamId = workflowData['teamId'] as String;

    final builtInEnvVars = <String>[
      if (tagName != null && tagName.isNotEmpty) "export OPENCI_TAG='$tagName'",
      if (tagVersion != null) "export OPENCI_TAG_VERSION='$tagVersion'",
      "export OPENCI_PROJECT_ID='$projectId'",
      "export OPENCI_TEAM_ID='$teamId'",
      () {
        final saJson = File(serviceAccountPath).readAsStringSync();
        final escaped = saJson.replaceAll("'", "'\\''");
        return "export OPENCI_GCP_SA_JSON='$escaped'";
      }(),
    ];

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
        await logger.info(
          'Auto-incremented $key: $value → ${int.parse(value) + 1}',
        );
      }

      final escapedValue = value.replaceAll("'", "'\\''");
      builtInEnvVars.add("export $key='$escapedValue'");
    }

    if (envVarsSnapshot.docs.isNotEmpty) {
      await logger.info(
        'Loaded ${envVarsSnapshot.docs.length} environment variable(s)',
      );
    }

    if (tagName != null && tagName.isNotEmpty) {
      await logger.info('Tag: $tagName (available as \$OPENCI_TAG)');
    }

    for (int i = 0; i < steps.length; i++) {
      await checkCancellation();

      final step = steps[i] as Map<String, dynamic>;
      final stepName = step['name'] as String? ?? 'Step ${i + 1}';

      await logger.info('Running step ${i + 1}/${steps.length}: $stepName');

      final command = step['command'] as String;

      if (command.contains('ios-sign')) {
        final updatedStep = await _ensureDistCertSecrets(
          step: step,
          stepIndex: i,
          workflowId: workflowId,
          teamId: teamId,
          projectId: projectId,
          serviceAccountPath: serviceAccountPath,
          firestore: firestore,
          logger: logger,
        );
        steps[i] = updatedStep;
      }

      final secrets =
          (steps[i] as Map<String, dynamic>)['requiredSecrets'] as List? ?? [];
      final exportCommands = <String>[];

      await logger.info('Command: $command');

      for (final secret in secrets) {
        final secretDocumentId = secret['secretDocumentId'] as String;
        final key = secret['key'] as String;
        final secretDoc = await firestore
            .collection('secrets_v0')
            .doc(secretDocumentId)
            .get();

        final secretData = secretDoc.data()!;
        final pathToSecret = secretData['pathToSecret'] as String;
        final secretValue = await fetchSecretValue(
          projectId,
          pathToSecret,
          serviceAccountPath,
        );

        final escapedValue = secretValue.replaceAll("'", "'\\''");
        exportCommands.add("export $key='$escapedValue'");
        final escapedPath = pathToSecret.replaceAll("'", "'\\''");
        exportCommands.add("export ${key}_SECRET_PATH='$escapedPath'");
      }

      final commandParts = [
        'set -e',
        'export LANG=en_US.UTF-8',
        'export PATH="/Users/admin/flutter/bin:\$PATH"',
        ...builtInEnvVars,
        'cd $workingDirectory',
        ...exportCommands,
        command,
      ];

      final fullCommand = commandParts.join('\n');
      final encodedCommand = base64Encode(utf8.encode(fullCommand));
      await execCommand(
        "/bin/zsh -c 'echo $encodedCommand | base64 -D | /bin/zsh'",
      );

      await logger.info('Step ${i + 1}/${steps.length} completed: $stepName');
    }

    await Future.delayed(const Duration(seconds: 5));

    if (checkRunId != null) {
      await updateCheckRun(
        owner,
        repo,
        checkRunId,
        token,
        status: 'completed',
        conclusion: 'success',
      );
    }

    await logger.info('Build completed successfully');
    await logger.updateRunStatus('completed', conclusion: 'success');

    await firestore.collection('build_jobs_v0').doc(buildJobId).update({
      'status': 'success',
    });
  } on CancelledException {
    await logger.info('Build was cancelled by user');
    if (checkRunId != null) {
      await updateCheckRun(
        owner,
        repo,
        checkRunId,
        token,
        status: 'completed',
        conclusion: 'cancelled',
      );
    }
    await logger.updateRunStatus('completed', conclusion: 'cancelled');
  } catch (e, s) {
    await logger.error('Job failed: $e', stackTrace: s.toString());
    if (checkRunId != null) {
      await updateCheckRun(
        owner,
        repo,
        checkRunId,
        token,
        status: 'completed',
        conclusion: 'failure',
      );
    }
    await logger.updateRunStatus('completed', conclusion: 'failure');

    await firestore.collection('build_jobs_v0').doc(buildJobId).update({
      'status': 'failure',
    });
    rethrow;
  } finally {
    try {
      await stopTart(currentVmName);
    } catch (e) {
      await logger.warning('Error stopping VM: $e');
    }
    try {
      await deleteTart(currentVmName);
    } catch (e) {
      await logger.warning('Error deleting VM: $e');
    }
    await pruneStaleVms(logger, workerId: workerId);
  }

  return true;
}

const baseVmName = 'sequoia-base';

Future<void> updateCheckRun(
  String owner,
  String repo,
  int checkRunId,
  String token, {
  required String status,
  String? conclusion,
}) async {
  final url = Uri.parse(
    'https://api.github.com/repos/$owner/$repo/check-runs/$checkRunId',
  );

  final body = {'status': status, 'conclusion': ?conclusion};

  final response = await http.patch(
    url,
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'OpenCI-Worker',
    },
    body: jsonEncode(body),
  );

  if (response.statusCode >= 300) {
    print('Failed to update check run: ${response.body}');
  } else {
    print('Updated check run status to $status');
  }
}

Future<void> runTart(String vmName) async {
  var shell = Shell();
  await shell.run('tart run $vmName');
}

Future<void> stopTart(String vmName) async {
  var shell = Shell();
  await shell.run('tart stop $vmName');
}

Future<void> deleteTart(String vmName) async {
  var shell = Shell(throwOnError: false);
  await shell.run('tart delete $vmName');
}

Future<void> waitForVmReady(
  String name, {
  Object? Function()? vmStartError,
}) async {
  var shell = Shell(throwOnError: false);
  print('Waiting for Guest Agent to respond...');
  for (int i = 0; i < 60; i++) {
    // Check if tart run has already failed
    final error = vmStartError?.call();
    if (error != null) {
      throw Exception('VM failed to start: $error');
    }

    var result = await shell.run('tart exec $name echo "ready"');
    print('exit code: ${result.first.exitCode}');

    if (result.first.exitCode == 0) {
      return;
    }

    await Future.delayed(const Duration(seconds: 1));
  }

  throw Exception('VM boot timeout: Guest Agent did not respond.');
}

Future<String> fetchSecretValue(
  String projectId,
  String pathToSecret,
  String serviceAccountPath,
) async {
  final credentials = ServiceAccountCredentials.fromJson(
    File(serviceAccountPath).readAsStringSync(),
  );

  final client = await clientViaServiceAccount(credentials, [
    SecretManagerApi.cloudPlatformScope,
  ]);

  try {
    final api = SecretManagerApi(client);
    final response = await api.projects.secrets.versions.access(
      '$pathToSecret/versions/latest',
    );
    final payload = response.payload?.data;

    if (payload == null || payload.isEmpty) {
      return '';
    }

    return utf8.decode(base64.decode(payload));
  } catch (e) {
    if (e.toString().contains('NOT_FOUND') ||
        e.toString().contains('404') ||
        e.toString().contains('no versions')) {
      return '';
    }
    rethrow;
  } finally {
    client.close();
  }
}

Future<void> cleanupOrphanedVms(String workerId) async {
  try {
    final shell = Shell(throwOnError: false, verbose: false);
    final result = await shell.run('tart list');
    if (result.isEmpty) return;

    final output = result.first.stdout.toString();
    final lines = LineSplitter.split(output);
    final prefix = 'openci-vm-$workerId-';

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('Source') && line.contains('Name')) continue;

      final parts = line.split(RegExp(r'\s+'));

      final vmNameIndex = parts.indexWhere((p) => p.startsWith(prefix));
      if (vmNameIndex == -1) continue;

      final vmName = parts[vmNameIndex];
      final state = parts.last;

      if (state == 'running') continue;

      print('Deleting orphaned VM: $vmName (State: $state)');
      await shell.run('tart delete $vmName');
    }
  } catch (e) {
    print('Error cleaning up orphaned VMs: $e');
  }
}

Future<void> pruneStaleVms(
  BuildLogger logger, {
  required String workerId,
}) async {
  try {
    final shell = Shell(throwOnError: false, verbose: false);
    final result = await shell.run('tart list');
    if (result.isEmpty) return;

    final output = result.first.stdout.toString();
    final lines = LineSplitter.split(output);
    final prefix = 'openci-vm-$workerId-';

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('Source') && line.contains('Name')) continue;

      final parts = line.split(RegExp(r'\s+'));

      final vmNameIndex = parts.indexWhere((p) => p.startsWith(prefix));
      if (vmNameIndex == -1) continue;

      final vmName = parts[vmNameIndex];
      final state = parts.last;

      if (state == 'running') continue;

      await logger.info('Deleting stale VM: $vmName (State: $state)');
      await shell.run('tart delete $vmName');
    }
  } catch (e) {
    await logger.warning('Error pruning stale VMs: $e');
  }
}

// ══════════════════════════════════════════════════════════════
// Distribution Certificate: Auto Secret Creation
// ══════════════════════════════════════════════════════════════

const _distCertKeys = [
  'OPENCI_DISTRIBUTION_CERTIFICATE_P12',
  'OPENCI_DISTRIBUTION_CERTIFICATE_PASSWORD',
  'OPENCI_DISTRIBUTION_CERTIFICATE_ID',
];

Future<Map<String, dynamic>> _ensureDistCertSecrets({
  required Map<String, dynamic> step,
  required int stepIndex,
  required String workflowId,
  required String teamId,
  required String projectId,
  required String serviceAccountPath,
  required Firestore firestore,
  required BuildLogger logger,
}) async {
  final existing = ((step['requiredSecrets'] as List?) ?? [])
      .cast<Map<String, dynamic>>();
  final existingKeys = existing.map((s) => s['key'] as String).toSet();

  final missingKeys = _distCertKeys
      .where((k) => !existingKeys.contains(k))
      .toList();

  if (missingKeys.isEmpty) {
    return step;
  }

  await logger.info(
    '🔑 Auto-creating distribution cert secrets: ${missingKeys.join(", ")}',
  );

  final saJsonStr = File(serviceAccountPath).readAsStringSync();
  final credentials = ServiceAccountCredentials.fromJson(saJsonStr);
  final authClient = await clientViaServiceAccount(credentials, [
    SecretManagerApi.cloudPlatformScope,
  ]);

  try {
    final secretApi = SecretManagerApi(authClient);
    final parent = 'projects/$projectId';

    final newSecrets = <Map<String, dynamic>>[];

    for (final key in missingKeys) {
      final secretId = const Uuid().v4();
      final secretName = '$parent/secrets/$secretId';

      await secretApi.projects.secrets.create(
        Secret(replication: Replication(automatic: Automatic())),
        parent,
        secretId: secretId,
      );

      final documentId = const Uuid().v4();
      await firestore.collection('secrets_v0').doc(documentId).set({
        'id': documentId,
        'name': key,
        'teamId': teamId,
        'pathToSecret': secretName,
        'createdAt': FieldValue.serverTimestamp,
        'updatedAt': FieldValue.serverTimestamp,
      });

      newSecrets.add({'key': key, 'secretDocumentId': documentId});

      await logger.info('  📦 Created: $key → $secretName');
    }

    final updatedSecrets = [...existing, ...newSecrets];
    final updatedStep = Map<String, dynamic>.from(step);
    updatedStep['requiredSecrets'] = updatedSecrets;

    final workflowDoc = await firestore
        .collection('workflows_v1')
        .doc(workflowId)
        .get();
    if (workflowDoc.exists) {
      final allSteps = (workflowDoc.data()!['workflowSteps'] as List).toList();
      allSteps[stepIndex] = updatedStep;
      await firestore.collection('workflows_v1').doc(workflowId).update({
        'workflowSteps': allSteps,
      });
    }

    await logger.info('  ✅ All distribution cert secrets provisioned');
    return updatedStep;
  } finally {
    authClient.close();
  }
}
