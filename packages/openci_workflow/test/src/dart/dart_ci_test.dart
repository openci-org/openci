import 'dart:io';

import 'package:openci_workflow/openci_workflow.dart';
import 'package:test/test.dart';

void main() {
  late Directory workspace;
  late OpenCI ci;

  Future<File> writeFile(String path, String content) async {
    final file = File('${workspace.path}/$path');
    await file.parent.create(recursive: true);
    return file.writeAsString(content);
  }

  Future<void> git(List<String> arguments) async {
    final result = await Process.run(
      'git',
      arguments,
      workingDirectory: workspace.path,
    );
    expect(result.exitCode, 0, reason: '${result.stdout}${result.stderr}');
  }

  OpenCI createCI({String? currentWorkingDirectory}) => OpenCI(
    workflowName: 'Dart format check',
    ciTriggers: const [CITrigger.push(branch: 'main')],
    workspacePath: workspace.path,
    currentWorkingDirectory: currentWorkingDirectory,
    commandRunner: (command, {required workingDirectory}) async {
      final result = await Process.run(
        'sh',
        ['-c', command],
        workingDirectory: workingDirectory,
        environment: {
          'PATH':
              '${File(Platform.resolvedExecutable).parent.path}'
              ':${Platform.environment['PATH'] ?? ''}',
        },
      );
      if (result.exitCode != 0) {
        throw ProcessException(
          'sh',
          ['-c', command],
          '${result.stdout}${result.stderr}',
          result.exitCode,
        );
      }
    },
  );

  setUp(() async {
    workspace = await Directory.systemTemp.createTemp('openci-dart-format-');
    await git(['init', '--quiet']);
    await writeFile('.gitignore', 'build/\n');
    await writeFile(
      'pubspec.yaml',
      'name: format_fixture\nenvironment:\n  sdk: ^3.11.5\n',
    );
    ci = createCI();
  });

  tearDown(() => workspace.delete(recursive: true));

  test('passes formatted tracked files and preserves ignored files', () async {
    final tracked = await writeFile('main.dart', 'void main() {}\n');
    await git(['add', 'main.dart']);
    const ignoredContent = 'void main(){print("ignored");}\n';
    final ignored = await writeFile('build/downloaded.dart', ignoredContent);

    await ci.dart.checkFormat();

    expect(await tracked.readAsString(), 'void main() {}\n');
    expect(await ignored.readAsString(), ignoredContent);
  });

  test('fails unformatted tracked files without rewriting them', () async {
    const content = 'void main(){print("tracked");}\n';
    final file = await writeFile('main.dart', content);
    await git(['add', 'main.dart']);

    await expectLater(ci.dart.checkFormat(), throwsA(isA<ProcessException>()));

    expect(await file.readAsString(), content);
  });

  for (final path in [
    'new file.dart',
    "quote'file.dart",
    'line\nbreak.dart',
    '-options.dart',
  ]) {
    test(
      'checks new files with literal paths: ${path.replaceAll('\n', r'\n')}',
      () async {
        const content = 'void main(){print("new");}\n';
        final file = await writeFile(path, content);

        await expectLater(
          ci.dart.checkFormat(),
          throwsA(isA<ProcessException>()),
        );

        expect(await file.readAsString(), content);
        await file.writeAsString('void main() {}\n');
        await ci.dart.checkFormat();
      },
    );
  }

  test('checks tracked files even when their directory is ignored', () async {
    final file = await writeFile(
      'build/tracked.g.dart',
      'void main(){print("generated");}\n',
    );
    await git(['add', '--force', 'build/tracked.g.dart']);

    await expectLater(ci.dart.checkFormat(), throwsA(isA<ProcessException>()));

    expect(await file.readAsString(), 'void main(){print("generated");}\n');
  });

  test('inherits the workflow directory and checks its descendants', () async {
    await writeFile('outside.dart', 'void main(){print("outside");}\n');
    final file = await writeFile(
      'packages/mobile/lib/main.dart',
      'void main() {}\n',
    );
    ci = createCI(currentWorkingDirectory: 'packages/mobile');

    await ci.dart.checkFormat();

    await file.writeAsString('void main(){print("nested");}\n');
    await expectLater(ci.dart.checkFormat(), throwsA(isA<ProcessException>()));
  });

  test('overrides the directory for only one call, including spaces', () async {
    await writeFile('packages/default/main.dart', 'void main() {}\n');
    final other = await writeFile(
      'packages/other app/main.dart',
      'void main(){print("other");}\n',
    );
    ci = createCI(currentWorkingDirectory: 'packages/default');

    await expectLater(
      ci.dart.checkFormat(dir: 'packages/other app'),
      throwsA(isA<ProcessException>()),
    );
    await ci.dart.checkFormat();

    await other.writeAsString('void main() {}\n');
    await ci.dart.checkFormat(dir: 'packages/other app');
  });

  test(
    'succeeds without matching files and does not format ignored files',
    () async {
      const content = 'void main(){print("ignored");}\n';
      final file = await writeFile('build/only.dart', content);

      await ci.dart.checkFormat();

      expect(await file.readAsString(), content);
    },
  );

  test('fails outside a Git checkout instead of reporting success', () async {
    await Directory('${workspace.path}/.git').delete(recursive: true);

    await expectLater(ci.dart.checkFormat(), throwsA(isA<ProcessException>()));
  });

  test('fails invalid Dart syntax without changing the file', () async {
    const content = 'void main( {\n';
    final file = await writeFile('broken.dart', content);

    await expectLater(ci.dart.checkFormat(), throwsA(isA<ProcessException>()));

    expect(await file.readAsString(), content);
  });
}
