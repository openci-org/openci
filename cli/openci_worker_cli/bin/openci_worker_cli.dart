import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_firebase_admin/dart_firebase_admin.dart';
import 'package:dart_firebase_admin/firestore.dart';

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
    final doc = await firestore.collection('build_jobs_v0').get();
    print(doc.docs);
    if (verbose) {
      print('Fetched ${doc.docs.length} documents from build_jobs_v0');
    }

    await admin.close();
  } on FormatException catch (e) {
    // Print usage information if an invalid argument was provided.
    print(e.message);
    print('');
    printUsage(argParser);
  }
}
