import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_firebase_admin/dart_firebase_admin.dart';
import 'package:dart_firebase_admin/firestore.dart';
import 'package:process_run/process_run.dart';

const String version = '0.4.1';

ArgParser buildParser() {
  return ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Show additional command output.',
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
    bool verbose = false;

    // Process the parsed arguments.
    if (results.flag('help')) {
      printUsage(argParser);
      return;
    }
    if (results.flag('version')) {
      print('openci_worker_cli version: $version');
      return;
    }
    if (results.flag('verbose')) {
      verbose = true;
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
    final doc = await firestore
        .collection('build_jobs_v0')
        .where('status', WhereFilter.equal, 'queued')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    print("docLength: ${doc.docs.length}");

    if (doc.docs.isEmpty) {
      print('No queued build jobs found.');
      return;
    }

    final buildJob = doc.docs.first;

    final buildJobData = buildJob.data();
    final token = buildJobData['installationToken'] as String;
    final owner = buildJobData['owner'] as String;
    final repo = buildJobData['repo'] as String;

    unawaited(runTart());

    print('Waiting for VM to be ready...');
    await waitForVmReady(vmName);
    print('VM is ready!');

    final cloneUrl =
        'https://x-access-token:$token@github.com/$owner/$repo.git';
    print('cloneUrl: $cloneUrl');

    await execCommand('rm -rf openci');
    await execCommand('git clone --progress $cloneUrl');
    print('finish cloning');

    await Future.delayed(const Duration(minutes: 15));

    await stopTart();

    await admin.close();
  } on FormatException catch (e) {
    // Print usage information if an invalid argument was provided.
    print(e.message);
    print('');
    printUsage(argParser);
  }
}

const vmName = 'sequoia-base';

Future<void> execCommand(String command) async {
  var shell = Shell(verbose: true);
  await shell.run("tart exec $vmName $command");
}

Future<void> runTart() async {
  var shell = Shell();
  await shell.run('tart run $vmName');
}

Future<void> stopTart() async {
  var shell = Shell();
  await shell.run('tart stop $vmName');
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
