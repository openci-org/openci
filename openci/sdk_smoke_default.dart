// Verify the refreshed macOS image after the November 4 rollout.
import 'dart:convert';
import 'dart:io';
import 'package:openci_workflow/openci_workflow.dart';

Future<void> main() async {
  await OpenCI.init(
    workflowName: 'SDK smoke default',
    ciTriggers: [CITrigger.push(branch: 'ci/flutter-sdk-smoke-20261104')],
  );
  final result = await Process.run('flutter', ['--version', '--machine']);
  if (result.exitCode != 0) throw StateError(result.stderr.toString());
  final version =
      (jsonDecode(result.stdout as String) as Map)['frameworkVersion'];
  if (version != '3.47.8') throw StateError('Unexpected Flutter: $version');
  print('SDK_VERIFIED=$version');
}
