import 'package:openci_workflow/openci_workflow.dart';

Future<void> main() async {
  final openCI = await OpenCI.init(
    workflowName: 'Dart Format Check',
    flutterVersion: '3.44.8',
    ciTriggers: [
      CITrigger.pullRequest(
        branch: '*',
        paths: [
          '**/*.dart',
          '**/analysis_options.yaml',
          '**/pubspec.yaml',
          '**/.gitignore',
          'pubspec.lock',
          '.fvmrc',
          '.fvm/fvm_config.json',
        ],
      ),
      CITrigger.push(
        branch: 'develop',
        paths: [
          '**/*.dart',
          '**/analysis_options.yaml',
          '**/pubspec.yaml',
          '**/.gitignore',
          'pubspec.lock',
          '.fvmrc',
          '.fvm/fvm_config.json',
        ],
      ),
    ],
  );

  await openCI.dart.checkFormat();
}
