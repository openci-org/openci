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

const String version = '0.6.5';

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
  print('Usage: openci-worker <flags> [arguments]');
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
      print('openci-worker version: $version');
      return;
    }
    if (results.flag('update')) {
      print('Updating openci-worker...');
      final shell = Shell(verbose: true);
      await shell.run('brew update');
      await shell.run('brew upgrade openci-worker');
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
    print('Cleaning up orphaned VMs from previous runs (lume)...');
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
            await Process.start('openci-worker', [
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

  try {
    final shell = Shell(verbose: true, throwOnError: false);
    await shell.run('brew update');
    final result = await shell.run('brew upgrade openci-worker');
    final output = result.first.stdout?.toString() ?? '';

    if (output.contains('already installed')) {
      print('[INFO] Already on latest brew version. Skipping restart.');
      return false;
    }

    return true;
  } catch (e) {
    print('[WARN] Auto-update failed: $e');
    return false;
  }
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

  try {
    final workflowFileName = buildJobData['workflowFileName'] as String?;
    if (workflowFileName == null || workflowFileName.isEmpty) {
      await logger.error('workflowFileName is missing in build job data');
      throw Exception('workflowFileName is missing');
    }

    await logger.info('Workflow: $workflowFileName');

    Object? vmStartError;
    unawaited(
      runVm(currentVmName).catchError((e) {
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

    await logger.info('Setting up environment...');

    final tagName = buildJobData['tagName'] as String?;
    final tagVersion = tagName != null && tagName.isNotEmpty
        ? (tagName.startsWith('v') || tagName.startsWith('V')
              ? tagName.substring(1)
              : tagName)
        : null;

    final teamId = buildJobData['teamId'] as String?;

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
          await logger.info(
            'Auto-incremented $key: $value → ${int.parse(value) + 1}',
          );
        }

        envVars[key] = value;
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
    await logger.info('Environment variables written');

    await logger.info('Running workflow with act...');

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
      logger,
      token,
      isCancelled: isCancelled,
    );

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
      await stopVm(currentVmName);
    } catch (e) {
      await logger.warning('Error stopping VM: $e');
    }
    try {
      await deleteVm(currentVmName);
    } catch (e) {
      await logger.warning('Error deleting VM: $e');
    }
    await pruneStaleVms(logger, workerId: workerId);
  }

  return true;
}

const baseVmName = 'tahoe-base_v1.0.0';
const sshUser = 'admin';
const sshPassword = 'admin';

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

Future<void> runVm(String vmName) async {
  var shell = Shell();
  await shell.run('lume run $vmName --no-display');
}

Future<void> stopVm(String vmName) async {
  var shell = Shell();
  await shell.run('lume stop $vmName');
}

Future<void> deleteVm(String vmName) async {
  var shell = Shell(throwOnError: false);
  await shell.run('lume delete $vmName --force');
}

Future<void> waitForVmReady(
  String name, {
  Object? Function()? vmStartError,
}) async {
  var shell = Shell(throwOnError: false);
  print('Waiting for VM to respond...');
  for (int i = 0; i < 120; i++) {
    final error = vmStartError?.call();
    if (error != null) {
      throw Exception('VM failed to start: $error');
    }

    var result = await shell.run(
      'lume ssh $name --user $sshUser --password $sshPassword --timeout 10 -- echo "ready"',
    );
    print('exit code: ${result.first.exitCode}');

    if (result.first.exitCode == 0) {
      return;
    }

    await Future.delayed(const Duration(seconds: 2));
  }

  throw Exception('VM boot timeout: VM did not respond.');
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
    final result = await shell.run('lume ls');
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
      await shell.run('lume delete $vmName --force');
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
    final result = await shell.run('lume list');
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
      await shell.run('lume delete $vmName --force');
    }
  } catch (e) {
    await logger.warning('Error pruning stale VMs: $e');
  }
}

Future<void> writeFileToVm(
  String vmName,
  String remotePath,
  String content,
) async {
  final encoded = base64Encode(utf8.encode(content));

  const chunkSize = 4096;
  final chunks = <String>[];
  for (var i = 0; i < encoded.length; i += chunkSize) {
    final end = (i + chunkSize < encoded.length)
        ? i + chunkSize
        : encoded.length;
    chunks.add(encoded.substring(i, end));
  }

  Future<ProcessResult> sshRun(String remoteCommand) async {
    return Process.run('lume', [
      'ssh',
      vmName,
      '--user',
      sshUser,
      '--password',
      sshPassword,
      remoteCommand,
    ]);
  }

  await sshRun('rm -f $remotePath $remotePath.b64');

  for (final chunk in chunks) {
    final result = await sshRun('printf %s $chunk >> $remotePath.b64');
    if (result.exitCode != 0) {
      throw Exception('Failed to write chunk to $remotePath: ${result.stderr}');
    }
  }

  final decodeResult = await sshRun(
    'base64 -D < $remotePath.b64 > $remotePath && rm $remotePath.b64',
  );
  if (decodeResult.exitCode != 0) {
    throw Exception(
      'Failed to decode $remotePath in VM: ${decodeResult.stderr}',
    );
  }
}

Future<void> execCommandStreaming(
  List<String> command,
  String vmName,
  BuildLogger logger,
  String token, {
  required Future<bool> Function() isCancelled,
}) async {
  final process = await Process.start('lume', [
    'ssh',
    vmName,
    '--user',
    sshUser,
    '--password',
    sshPassword,
    '--timeout',
    '0',
    '--',
    ...command,
  ]);

  final stdoutCompleter = Completer<void>();
  final stderrCompleter = Completer<void>();

  process.stdout.transform(utf8.decoder).listen((data) {
    final masked = data.replaceAll(token, '***').trim();
    if (masked.isNotEmpty) {
      for (final line in LineSplitter.split(masked)) {
        if (line.trim().isNotEmpty) {
          logger.info(line.trim());
        }
      }
    }
  }, onDone: () => stdoutCompleter.complete());

  process.stderr.transform(utf8.decoder).listen((data) {
    final masked = data.replaceAll(token, '***').trim();
    if (masked.isNotEmpty) {
      for (final line in LineSplitter.split(masked)) {
        if (line.trim().isNotEmpty) {
          logger.info(line.trim());
        }
      }
    }
  }, onDone: () => stderrCompleter.complete());

  final cancelTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
    if (await isCancelled()) {
      process.kill(ProcessSignal.sigterm);
    }
  });

  final exitCode = await process.exitCode;
  cancelTimer.cancel();
  await stdoutCompleter.future;
  await stderrCompleter.future;

  if (exitCode != 0) {
    throw Exception('act exited with code $exitCode');
  }
}
