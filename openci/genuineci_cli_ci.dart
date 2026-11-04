import 'package:openci_workflow/openci_workflow.dart';

Future<void> main() async {
  final openCI = await OpenCI.init(
    workflowName: 'GenuineCI CLI CI',
    cancelPreviousRuns: true,
    ciTriggers: [
      CITrigger.pullRequest(
        branch: '*',
        paths: [
          'apps/genuineci_cli/**',
          'openci/genuineci_cli_ci.dart',
          'packages/openci_workflow/**',
          'packages/pubspec_version_hook/**',
          'openci/generated/**',
          '**/pubspec.yaml',
          'pubspec.lock',
          '.fvmrc',
        ],
      ),
      CITrigger.push(
        branch: 'develop',
        paths: [
          'apps/genuineci_cli/**',
          'openci/genuineci_cli_ci.dart',
          'packages/openci_workflow/**',
          'packages/pubspec_version_hook/**',
          'openci/generated/**',
          '**/pubspec.yaml',
          'pubspec.lock',
          '.fvmrc',
        ],
      ),
    ],
    currentWorkingDirectory: 'apps/genuineci_cli',
  );

  await openCI.run(r'unformatted=$(gofmt -l .) && test -z "$unformatted"');
  await openCI.go.vet();
  await openCI.run('go test -race ./...');
  await openCI.run('go build -o build/go-genuine ./cmd/go-genuine');
}
