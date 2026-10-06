import 'dart:io';

import 'package:openci_workflow/openci_workflow.dart';

Future<void> main() async {
  final openCI = await OpenCI.init(
    workflowName: 'Website CI',
    ciTriggers: [
      CITrigger.pullRequest(branch: 'develop'),
      CITrigger.push(branch: 'develop'),
    ],
    currentWorkingDirectory: 'apps/website',
  );

  await openCI.run(
    'flutter pub get --enforce-lockfile',
    workingDirectory: '.',
  );
  await openCI.run('dart format --output=none --set-exit-if-changed lib test');
  // Avoid collisions with a preview or another build on the CI machine.
  final socket = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
  final port = socket.port;
  await socket.close();
  await openCI.run('dart run jaspr_cli:jaspr build --port $port');
  // Analytics network failures must not crash the CI analysis server.
  await openCI.run('dart --suppress-analytics analyze --fatal-infos');
  await openCI.run('dart test');
}
