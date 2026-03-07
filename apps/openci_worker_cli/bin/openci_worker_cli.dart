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
import 'package:yaml/yaml.dart';

const String version = '0.5.0';

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

  Future<void> execCommand(String command) async {
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

  Future<String> execCommandWithOutput(String command) async {
    var shell = Shell(verbose: false, throwOnError: false);
    final results = await shell.run("tart exec $currentVmName $command");
    final output = StringBuffer();

    for (final result in results) {
      final stdout = result.stdout?.toString().trim();
      if (stdout != null && stdout.isNotEmpty) {
        output.writeln(stdout);
      }
      if (result.exitCode != 0) {
        final stderr = result.stderr?.toString().trim() ?? '';
        throw Exception(
          'Command failed with exit code ${result.exitCode}: $stderr',
        );
      }
    }

    return output.toString().trim();
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
    final workflowFileName = buildJobData['workflowFileName'] as String?;
    if (workflowFileName == null || workflowFileName.isEmpty) {
      await logger.error('workflowFileName is missing in build job data');
      throw Exception('workflowFileName is missing');
    }

    await logger.info('Workflow file: .openci/$workflowFileName');

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

    await logger.info('Reading .openci/$workflowFileName...');
    final yamlContent = await execCommandWithOutput(
      "cat $repo/.openci/$workflowFileName",
    );

    final parsedYaml = loadYaml(yamlContent);
    if (parsedYaml is! YamlMap) {
      await logger.error('Invalid YAML in .openci/$workflowFileName');
      throw Exception('Invalid workflow YAML');
    }

    final steps = _extractStepsFromYaml(parsedYaml);
    if (steps.isEmpty) {
      await logger.error('No steps found in .openci/$workflowFileName');
      throw Exception('No steps found in workflow YAML');
    }

    await logger.info(
      'Loaded ${steps.length} steps from .openci/$workflowFileName',
    );

    final workingDirectory = repo;

    final tagName = buildJobData['tagName'] as String?;
    final tagVersion = tagName != null && tagName.isNotEmpty
        ? (tagName.startsWith('v') || tagName.startsWith('V')
              ? tagName.substring(1)
              : tagName)
        : null;

    final teamId = buildJobData['teamId'] as String?;

    final builtInEnvVars = <String>[
      if (tagName != null && tagName.isNotEmpty) "export OPENCI_TAG='$tagName'",
      if (tagVersion != null) "export OPENCI_TAG_VERSION='$tagVersion'",
      "export OPENCI_PROJECT_ID='$projectId'",
      if (teamId != null) "export OPENCI_TEAM_ID='$teamId'",
      () {
        final saJson = File(serviceAccountPath).readAsStringSync();
        final escaped = saJson.replaceAll("'", "'\\''");
        return "export OPENCI_GCP_SA_JSON='$escaped'";
      }(),
    ];

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
    }

    if (tagName != null && tagName.isNotEmpty) {
      await logger.info('Tag: $tagName (available as \$OPENCI_TAG)');
    }

    for (int i = 0; i < steps.length; i++) {
      await checkCancellation();

      final step = steps[i];
      final stepName = step['name'] as String? ?? 'Step ${i + 1}';
      final runCommand = step['run'] as String?;
      final usesAction = step['uses'] as String?;

      await logger.info('Running step ${i + 1}/${steps.length}: $stepName');

      if (runCommand != null && runCommand.isNotEmpty) {
        await logger.info('run: $runCommand');

        final commandParts = [
          'set -e',
          'export LANG=en_US.UTF-8',
          'export PATH="/Users/admin/flutter/bin:\$PATH"',
          ...builtInEnvVars,
          'cd $workingDirectory',
          runCommand,
        ];

        final fullCommand = commandParts.join('\n');
        final encodedCommand = base64Encode(utf8.encode(fullCommand));
        await execCommand(
          "/bin/zsh -c 'echo $encodedCommand | base64 -D | /bin/zsh'",
        );
      } else if (usesAction != null && usesAction.isNotEmpty) {
        final withParams = <String, String>{};
        final rawWith = step['with'];
        if (rawWith is Map) {
          for (final entry in rawWith.entries) {
            withParams[entry.key.toString()] = entry.value.toString();
          }
        }

        await executeUsesStep(
          uses: usesAction,
          withParams: withParams,
          workingDirectory: workingDirectory,
          builtInEnvVars: builtInEnvVars,
          logger: logger,
          execCommand: execCommand,
          execCommandWithOutput: execCommandWithOutput,
        );
      } else {
        await logger.warning('Step ${i + 1} has no run or uses, skipping');
      }

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

List<Map<String, dynamic>> _extractStepsFromYaml(YamlMap parsed) {
  final steps = <Map<String, dynamic>>[];
  final jobs = parsed['jobs'];
  if (jobs is! YamlMap) return steps;

  for (final jobKey in jobs.keys) {
    final job = jobs[jobKey];
    if (job is! YamlMap) continue;
    final jobSteps = job['steps'];
    if (jobSteps is! YamlList) continue;

    for (final step in jobSteps) {
      if (step is! YamlMap) continue;

      final entry = <String, dynamic>{'name': step['name']?.toString() ?? ''};

      if (step['uses'] != null) {
        entry['uses'] = step['uses'].toString();
        if (step['with'] is YamlMap) {
          final withMap = <String, String>{};
          final w = step['with'] as YamlMap;
          for (final key in w.keys) {
            withMap[key.toString()] = w[key].toString();
          }
          entry['with'] = withMap;
        }
      } else if (step['run'] != null) {
        entry['run'] = step['run'].toString();
      }

      steps.add(entry);
    }
  }

  return steps;
}

Future<void> executeUsesStep({
  required String uses,
  required Map<String, String> withParams,
  required String workingDirectory,
  required List<String> builtInEnvVars,
  required BuildLogger logger,
  required Future<void> Function(String command) execCommand,
  required Future<String> Function(String command) execCommandWithOutput,
}) async {
  await logger.info('uses: $uses');

  final atIndex = uses.indexOf('@');
  final ref = atIndex != -1 ? uses.substring(atIndex + 1) : 'main';
  final repoPath = atIndex != -1 ? uses.substring(0, atIndex) : uses;
  final pathParts = repoPath.split('/');

  if (pathParts.length < 2) {
    throw Exception('Invalid action reference: $uses');
  }

  final actionOwner = pathParts[0];
  final actionRepo = pathParts[1];
  final actionSubPath = pathParts.length > 2
      ? pathParts.sublist(2).join('/')
      : '';

  final sanitizedRef = ref.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  final actionDirName = '${actionOwner}_${actionRepo}_$sanitizedRef';
  const actionBaseDir = '/tmp/openci-actions';
  final actionDir = '$actionBaseDir/$actionDirName';
  final actionRoot = actionSubPath.isNotEmpty
      ? '$actionDir/$actionSubPath'
      : actionDir;

  await logger.info('Cloning action $actionOwner/$actionRepo@$ref...');

  final cloneScript = [
    'set -e',
    'mkdir -p $actionBaseDir',
    'if [ ! -d "$actionDir" ]; then',
    '  git clone --depth 1 --branch $ref https://github.com/$actionOwner/$actionRepo.git $actionDir',
    'fi',
    'cat $actionRoot/action.yml 2>/dev/null || cat $actionRoot/action.yaml',
  ].join('\n');

  final encodedCloneScript = base64Encode(utf8.encode(cloneScript));
  final actionYamlContent = await execCommandWithOutput(
    "/bin/zsh -c 'echo $encodedCloneScript | base64 -D | /bin/zsh'",
  );

  final actionYaml = loadYaml(actionYamlContent);
  if (actionYaml is! YamlMap) {
    throw Exception('Invalid action.yml for $uses');
  }

  final runs = actionYaml['runs'] as YamlMap?;
  if (runs == null) {
    throw Exception('Invalid action.yml: missing "runs" section');
  }

  final using = runs['using']?.toString() ?? '';

  final inputEnvVars = <String>[];

  final inputs = actionYaml['inputs'] as YamlMap?;
  if (inputs != null) {
    for (final inputKey in inputs.keys) {
      final inputDef = inputs[inputKey];
      if (inputDef is YamlMap) {
        final defaultValue = inputDef['default']?.toString();
        if (defaultValue != null) {
          final envKey =
              'INPUT_${inputKey.toString().toUpperCase().replaceAll('-', '_')}';
          final escaped = defaultValue.replaceAll("'", "'\\''");
          inputEnvVars.add("export $envKey='$escaped'");
        }
      }
    }
  }

  for (final entry in withParams.entries) {
    final envKey = 'INPUT_${entry.key.toUpperCase().replaceAll('-', '_')}';
    final escaped = entry.value.replaceAll("'", "'\\''");
    inputEnvVars.add("export $envKey='$escaped'");
  }

  if (using == 'composite') {
    final compositeSteps = runs['steps'] as YamlList?;
    if (compositeSteps == null || compositeSteps.isEmpty) {
      throw Exception('Composite action has no steps');
    }

    await logger.info(
      'Executing composite action with ${compositeSteps.length} sub-steps',
    );

    for (int j = 0; j < compositeSteps.length; j++) {
      final compositeStep = compositeSteps[j];
      if (compositeStep is! YamlMap) continue;

      final subStepName =
          compositeStep['name']?.toString() ?? 'Sub-step ${j + 1}';
      await logger.info('  [$subStepName]');

      final subRunCmd = compositeStep['run']?.toString();
      if (subRunCmd == null || subRunCmd.isEmpty) continue;

      final shell = compositeStep['shell']?.toString() ?? 'bash';
      final stepWorkingDir = compositeStep['working-directory']?.toString();

      final commandParts = [
        'set -e',
        'export LANG=en_US.UTF-8',
        'export PATH="/Users/admin/flutter/bin:\$PATH"',
        ...builtInEnvVars,
        ...inputEnvVars,
        'export GITHUB_ACTION_PATH="$actionRoot"',
        if (stepWorkingDir != null)
          'cd $workingDirectory/$stepWorkingDir'
        else
          'cd $workingDirectory',
        subRunCmd,
      ];

      final fullCommand = commandParts.join('\n');
      final encodedCommand = base64Encode(utf8.encode(fullCommand));
      await execCommand(
        "/bin/zsh -c 'echo $encodedCommand | base64 -D | /bin/$shell'",
      );
    }
  } else if (using.startsWith('node')) {
    final main = runs['main']?.toString();
    if (main == null) {
      throw Exception('Node action has no main entry point');
    }

    await logger.info('Executing Node.js action ($using): $main');

    final commandParts = [
      'set -e',
      'export LANG=en_US.UTF-8',
      'export PATH="/Users/admin/flutter/bin:\$PATH"',
      ...builtInEnvVars,
      ...inputEnvVars,
      'export GITHUB_ACTION_PATH="$actionRoot"',
      'cd $workingDirectory',
      'node $actionRoot/$main',
    ];

    final fullCommand = commandParts.join('\n');
    final encodedCommand = base64Encode(utf8.encode(fullCommand));
    await execCommand(
      "/bin/zsh -c 'echo $encodedCommand | base64 -D | /bin/zsh'",
    );
  } else {
    throw Exception(
      'Unsupported action type: $using (only composite and node actions are supported)',
    );
  }
}
