import 'dart:async';
import 'dart:io';

import 'package:openci_workflow/openci_workflow.dart';
import 'package:test/test.dart';

void main() {
  const workspace = '/tmp/genuine-ci-workspace';
  final commands = <String, Future<void> Function(FlutterCi, {String? dir})>{
    'flutter analyze': (flutter, {dir}) => flutter.staticAnalysis(dir: dir),
    'flutter test': (flutter, {dir}) => flutter.unitTests(dir: dir),
  };

  for (final (command, execute) in commands.entries.map(
    (entry) => (entry.key, entry.value),
  )) {
    group(command, () {
      for (final directory in <String?>[
        null,
        '',
        const WorkspaceDirectory('apps/dashboard'),
      ]) {
        test('inherits the workflow directory: $directory', () async {
          final calls = <(String, String)>[];
          final ci = OpenCI.forTesting(
            workspacePath: workspace,
            currentWorkingDirectory: directory,
            commandRunner: (command, {required workingDirectory}) async {
              calls.add((command, workingDirectory));
            },
          );

          await execute(ci.flutter);

          final expectedDirectory = directory == null || directory.isEmpty
              ? workspace
              : '$workspace${Platform.pathSeparator}apps/dashboard';
          expect(calls, [(command, expectedDirectory)]);
        });
      }

      for (final (dir, relativePath) in [
        ('', ''),
        (const WorkspaceDirectory('.'), '.'),
        (const WorkspaceDirectory('apps/other app'), 'apps/other app'),
      ]) {
        test('overrides the directory for only this call: $dir', () async {
          final calls = <(String, String)>[];
          final ci = OpenCI.forTesting(
            workspacePath: workspace,
            currentWorkingDirectory: 'apps/dashboard',
            commandRunner: (command, {required workingDirectory}) async {
              calls.add((command, workingDirectory));
            },
          );

          await execute(ci.flutter, dir: dir);
          await execute(ci.flutter);

          final expectedDirectory = relativePath.isEmpty
              ? workspace
              : '$workspace${Platform.pathSeparator}$relativePath';
          expect(calls, [
            (command, expectedDirectory),
            (command, '$workspace${Platform.pathSeparator}apps/dashboard'),
          ]);
        });
      }

      test('waits for the command to complete', () async {
        final completion = Completer<void>();
        final ci = OpenCI.forTesting(
          workspacePath: workspace,
          commandRunner: (_, {required workingDirectory}) => completion.future,
        );
        var finished = false;
        final result = execute(ci.flutter).then((_) => finished = true);

        await Future<void>.value();
        expect(finished, isFalse);
        completion.complete();
        await result;
        expect(finished, isTrue);
      });

      test('propagates command failures', () async {
        final error = StateError('Could not start Flutter');
        final ci = OpenCI.forTesting(
          workspacePath: workspace,
          commandRunner: (_, {required workingDirectory}) =>
              Future.error(error),
        );

        await expectLater(execute(ci.flutter), throwsA(same(error)));
      });
    });
  }

  test('each workflow keeps its own working directory', () async {
    final directories = <String>[];
    Future<void> record(
      String command, {
      required String workingDirectory,
    }) async {
      directories.add(workingDirectory);
    }

    final dashboard = OpenCI.forTesting(
      workspacePath: workspace,
      currentWorkingDirectory: 'apps/dashboard',
      commandRunner: record,
    );
    final mobile = OpenCI.forTesting(
      workspacePath: workspace,
      currentWorkingDirectory: 'apps/mobile',
      commandRunner: record,
    );

    await dashboard.flutter.staticAnalysis();
    await mobile.flutter.unitTests();
    await dashboard.flutter.unitTests();

    expect(directories, [
      '$workspace${Platform.pathSeparator}apps/dashboard',
      '$workspace${Platform.pathSeparator}apps/mobile',
      '$workspace${Platform.pathSeparator}apps/dashboard',
    ]);
  });
}
