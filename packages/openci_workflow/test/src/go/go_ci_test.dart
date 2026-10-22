import 'dart:async';
import 'dart:io';

import 'package:openci_workflow/openci_workflow.dart';
import 'package:test/test.dart';

void main() {
  const workspace = '/tmp/openci-workspace';
  final commands = <String, Future<void> Function(GoCI, {String? dir})>{
    'go fmt ./...': (go, {dir}) => go.format(dir: dir),
    'go vet ./...': (go, {dir}) => go.vet(dir: dir),
    'go test -v ./...': (go, {dir}) => go.test(dir: dir),
  };

  for (final entry in commands.entries) {
    group(entry.key, () {
      test('inherits the workflow directory without setup commands', () async {
        final calls = <(String, String)>[];
        final ci = OpenCI(
          workflowName: 'test',
          ciTriggers: const [CITrigger.push(branch: 'test')],
          workspacePath: workspace,
          currentWorkingDirectory: 'apps/genuineci_server',
          commandRunner: (command, {required workingDirectory}) async {
            calls.add((command, workingDirectory));
          },
        );

        await entry.value(ci.go);

        expect(calls, [
          (
            entry.key,
            '$workspace${Platform.pathSeparator}apps/genuineci_server',
          ),
        ]);
      });

      test('overrides the directory for only the requested call', () async {
        final calls = <(String, String)>[];
        final ci = OpenCI(
          workflowName: 'test',
          ciTriggers: const [CITrigger.push(branch: 'test')],
          workspacePath: workspace,
          commandRunner: (command, {required workingDirectory}) async {
            calls.add((command, workingDirectory));
          },
        );

        await entry.value(ci.go, dir: 'apps/other server');
        await entry.value(ci.go);

        expect(calls, [
          (entry.key, '$workspace${Platform.pathSeparator}apps/other server'),
          (entry.key, workspace),
        ]);
      });

      test('waits for the command and propagates its failure', () async {
        final completion = Completer<void>();
        final error = StateError('Go check failed');
        final ci = OpenCI(
          workflowName: 'test',
          ciTriggers: const [CITrigger.push(branch: 'test')],
          workspacePath: workspace,
          commandRunner: (_, {required workingDirectory}) => completion.future,
        );
        var finished = false;
        final result = entry.value(ci.go).whenComplete(() => finished = true);
        final expectation = expectLater(result, throwsA(same(error)));

        await Future<void>.value();
        expect(finished, isFalse);
        completion.completeError(error);
        await expectation;
        expect(finished, isTrue);
      });
    });
  }
}
