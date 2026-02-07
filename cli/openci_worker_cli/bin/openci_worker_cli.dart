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

const String version = '0.4.16';

enum LogLevel { info, warning, error }

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
        if (stackTrace != null) 'stackTrace': stackTrace,
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
            if (conclusion != null) 'conclusion': conclusion,
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
    ..addOption('project-id', help: 'The Firebase project ID.')
    ..addOption(
      'service-account',
      help: 'The path to the service account JSON file.',
    );
}

void printUsage(ArgParser argParser) {
  print('Usage: dart openci_worker_cli.dart <flags> [arguments]');
  print(argParser.usage);
}

Future<void> main(List<String> arguments) async {
  final ArgParser argParser = buildParser();

  try {
    final ArgResults results = argParser.parse(arguments);

    if (results.flag('help')) {
      printUsage(argParser);
      return;
    }
    if (results.flag('version')) {
      print('openci_worker_cli version: $version');
      return;
    }

    final String? projectId = results['project-id'];
    final String? serviceAccountPath = results['service-account'];

    if (projectId == null || serviceAccountPath == null) {
      print('Error: --project-id and --service-account are required.');
      printUsage(argParser);
      return;
    }

    final admin = FirebaseAdminApp.initializeApp(
      projectId,
      Credential.fromServiceAccount(File(serviceAccountPath)),
    );

    final firestore = Firestore(admin);

    print('Worker started. Polling for jobs...');

    final spinnerChars = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
    int spinnerIndex = 0;
    var waitingStartTime = DateTime.now();
    int pollCounter = 0;
    const pollInterval = 10;

    while (true) {
      bool jobFound = false;

      if (pollCounter == 0) {
        try {
          jobFound = await processJob(firestore, projectId, serviceAccountPath);
        } catch (e) {
          print('\nError processing job: $e');
        }
      }

      if (!jobFound) {
        final elapsed = DateTime.now().difference(waitingStartTime);
        final minutes = elapsed.inMinutes;
        final seconds = elapsed.inSeconds % 60;
        final timeStr = '${minutes}m ${seconds}s';
        stdout.write(
          '\r${spinnerChars[spinnerIndex]} Waiting for jobs... ($timeStr)  ',
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

Future<bool> processJob(
  Firestore firestore,
  String projectId,
  String serviceAccountPath,
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

  final currentVmName = 'openci-vm-$buildJobId';
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

    unawaited(runTart(currentVmName));

    await logger.info('Waiting for VM to be ready...');
    await waitForVmReady(currentVmName);
    await logger.info('VM is ready!');

    await logger.info('Cloning repository $owner/$repo...');
    final cloneUrl =
        'https://x-access-token:$token@github.com/$owner/$repo.git';

    await execCommand('git clone --progress $cloneUrl');

    await logger.info('Checking out commit $commitSha...');
    await execCommand('git -C $repo checkout $commitSha');

    await logger.info('Repository cloned successfully');

    String workingDirectory = repo;
    if (cwd != null && cwd.isNotEmpty) {
      workingDirectory = '$repo/$cwd';
    }

    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      final command = step['command'] as String;
      final stepName = step['name'] as String? ?? 'Step ${i + 1}';
      final secrets = step['requiredSecrets'] as List;
      final exportCommands = <String>[];

      await logger.info('Running step ${i + 1}/${steps.length}: $stepName');
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
      }

      final commandParts = [
        'set -e',
        'export LANG=en_US.UTF-8',
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
    await pruneStaleVms(logger);
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

  final body = {
    'status': status,
    if (conclusion != null) 'conclusion': conclusion,
  };

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

Future<void> waitForVmReady(String name) async {
  var shell = Shell(throwOnError: false);
  print('Waiting for Guest Agent to respond...');
  for (int i = 0; i < 60; i++) {
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

    if (payload == null) {
      throw Exception('Secret payload is empty');
    }

    return utf8.decode(base64.decode(payload));
  } finally {
    client.close();
  }
}

Future<void> pruneStaleVms(BuildLogger logger) async {
  try {
    final shell = Shell(throwOnError: false, verbose: false);
    final result = await shell.run('tart list');
    if (result.isEmpty) return;

    final output = result.first.stdout.toString();
    final lines = LineSplitter.split(output);

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('Source') && line.contains('Name')) continue;

      final parts = line.split(RegExp(r'\s+'));

      final vmNameIndex = parts.indexWhere((p) => p.startsWith('openci-vm-'));
      if (vmNameIndex == -1) continue;

      final vmName = parts[vmNameIndex];
      // State is the last column
      final state = parts.last;

      if (state == 'running') {
        continue;
      }

      await logger.info('Deleting unused VM: $vmName (State: $state)');
      await shell.run('tart delete $vmName');
    }
  } catch (e) {
    await logger.warning('Error pruning stale VMs: $e');
  }
}
