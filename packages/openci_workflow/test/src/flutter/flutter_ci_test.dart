import 'dart:async';
import 'dart:io';

import 'package:openci_workflow/openci_workflow.dart';
import 'package:test/test.dart';

void main() {
  const workspace = '/tmp/openci-workspace';
  final commands = <String, Future<void> Function(FlutterCI, {String? dir})>{
    'flutter analyze --suppress-analytics': (flutter, {dir}) =>
        flutter.staticAnalysis(dir: dir),
    'flutter analyze': (flutter, {dir}) =>
        flutter.staticAnalysis(dir: dir, suppressAnalytics: false),
    'flutter analyze --suppress-analytics --no-fatal-infos': (flutter, {dir}) =>
        flutter.staticAnalysis(dir: dir, noFatalInfos: true),
    'flutter analyze --suppress-analytics --no-fatal-warnings':
        (flutter, {dir}) =>
            flutter.staticAnalysis(dir: dir, noFatalWarnings: true),
    'flutter analyze --suppress-analytics --no-fatal-infos --no-fatal-warnings':
        (flutter, {dir}) => flutter.staticAnalysis(
          dir: dir,
          noFatalInfos: true,
          noFatalWarnings: true,
        ),
    'flutter test': (flutter, {dir}) => flutter.unitTests(dir: dir),
    'flutter build apk': (flutter, {dir}) => flutter.buildApk(dir: dir),
    "flutter build apk --flavor 'staging'": (flutter, {dir}) =>
        flutter.buildApk(dir: dir, flavor: 'staging'),
    'flutter build appbundle': (flutter, {dir}) => flutter.buildAab(dir: dir),
    "flutter build appbundle --flavor 'production'": (flutter, {dir}) =>
        flutter.buildAab(dir: dir, flavor: 'production'),
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

  for (final (target, build)
      in <(String, Future<void> Function(FlutterCI, String?))>[
        ('apk', (flutter, flavor) => flutter.buildApk(flavor: flavor)),
        ('appbundle', (flutter, flavor) => flutter.buildAab(flavor: flavor)),
      ]) {
    group('$target flavor arguments', () {
      for (final flavor in <String?>[
        null,
        'production',
        '',
        r'''staging' "$OPENCI_TEST_FLAVOR" `printf expanded` $(printf expanded); printf injected''',
      ]) {
        test('passes the literal flavor to the command: $flavor', () async {
          final flutter = FlutterCI((command, {workingDirectory}) async {
            final result = await Process.run(
              'sh',
              [
                '-c',
                r'''flutter() { printf '%s\000' "$@"; }'''
                    '\n$command',
              ],
              environment: {'OPENCI_TEST_FLAVOR': 'expanded'},
            );

            expect(result.exitCode, 0, reason: result.stderr.toString());
            expect((result.stdout as String).split('\u0000'), [
              'build',
              target,
              if (flavor != null) ...['--flavor', flavor],
              '',
            ]);
          });

          await build(flutter, flavor);
        });
      }
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
