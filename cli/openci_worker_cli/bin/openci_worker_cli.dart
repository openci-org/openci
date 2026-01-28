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

const String version = '0.4.5';

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

    // Process the parsed arguments.
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

    while (true) {
      bool jobFound = false;
      try {
        jobFound = await processJob(firestore, projectId, serviceAccountPath);
      } catch (e) {
        print('Error processing job: $e');
      }

      if (!jobFound) {
        await Future.delayed(const Duration(seconds: 5));
      }
    }
  } on FormatException catch (e) {
    // Print usage information if an invalid argument was provided.
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
      .orderBy('createdAt', descending: true)
      .limit(1)
      .get();
  print("docLength: ${doc.docs.length}");

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
  final checkRunId = buildJobData['checkRunId'] as int?;

  print('Processing job: $buildJobId for $owner/$repo');

  if (checkRunId != null) {
    print('Updating check run to in_progress...');
    await updateCheckRun(owner, repo, checkRunId, token, status: 'in_progress');
  }

  final currentVmName = '$baseVmName-$buildJobId';
  print('Cloning VM $baseVmName to $currentVmName...');
  await Shell().run('tart clone $baseVmName $currentVmName');

  // Local helper to execute commands on the specific VM
  Future<void> execCommand(String command) async {
    var shell = Shell(verbose: true);
    await shell.run("tart exec $currentVmName $command");
  }

  try {
    final workflowQs = await firestore
        .collection('workflows_v1')
        .where(
          'workflowConfig.selectedRepository',
          WhereFilter.equal,
          '$owner/$repo',
        )
        .get();

    if (workflowQs.docs.isEmpty) {
      print('No workflow found for repository $owner/$repo.');
      throw Exception('No workflow found');
    }

    final workflowDoc = workflowQs.docs.first;
    final workflowData = workflowDoc.data();
    final steps = workflowData['workflowSteps'] as List;
    final workflowConfig =
        workflowData['workflowConfig'] as Map<String, dynamic>?;
    final cwd = workflowConfig?['selectedWorkingDirectory'] as String?;

    print('steps: $steps');
    print('cwd: $cwd');

    unawaited(runTart(currentVmName));

    print('Waiting for VM to be ready...');
    await waitForVmReady(currentVmName);
    print('VM is ready!');

    final cloneUrl =
        'https://x-access-token:$token@github.com/$owner/$repo.git';
    print('cloneUrl: $cloneUrl');

    await execCommand('rm -rf openci');
    await execCommand('git clone --progress $cloneUrl');

    print('finish cloning');

    String workingDirectory = repo;
    if (cwd != null && cwd.isNotEmpty) {
      workingDirectory = '$repo/$cwd';
    }

    for (final step in steps) {
      final command = step['command'] as String;
      final secrets = step['requiredSecrets'] as List;
      final exportCommands = <String>[];

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
        'export LANG=en_US.UTF-8',
        'cd $workingDirectory',
        ...exportCommands,
        command,
      ];

      await execCommand('/bin/zsh -c "${commandParts.join(' && ')}"');
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

    // Mark as completed in Firestore
    await firestore.collection('build_jobs_v0').doc(buildJobId).update({
      'status': 'success',
    });
  } catch (e, s) {
    print('Job failed: $e');
    print('Stack trace: $s');
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
    // Mark as failed in Firestore
    await firestore.collection('build_jobs_v0').doc(buildJobId).update({
      'status': 'failure',
    });
    rethrow;
  } finally {
    try {
      await stopTart(currentVmName);
    } catch (e) {
      print('Error stopping VM: $e');
    }
    try {
      await deleteTart(currentVmName);
    } catch (e) {
      print('Error deleting VM: $e');
    }
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

    // Secret payload is base64 encoded
    return utf8.decode(base64.decode(payload));
  } finally {
    client.close();
  }
}
