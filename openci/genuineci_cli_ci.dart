import 'package:openci_workflow/openci_workflow.dart';

Future<void> main() async {
  final openCI = await OpenCI.init(
    workflowName: 'GenuineCI CLI CI',
    ciTriggers: [
      CITrigger.pullRequest(branch: '*'),
      CITrigger.push(branch: 'develop'),
    ],
    currentWorkingDirectory: 'apps/genuineci_cli',
  );

  await openCI.run(r'unformatted=$(gofmt -l .) && test -z "$unformatted"');
  await openCI.go.vet();
  await openCI.run('go test -race ./...');
  await openCI.run('go build -o build/go-genuine ./cmd/go-genuine');
}
