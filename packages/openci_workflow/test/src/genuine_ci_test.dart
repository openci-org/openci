import 'dart:convert';
import 'dart:io';

import 'package:genuine_ci/genuine_ci.dart';
import 'package:test/test.dart';

void main() {
  group('GenuineCI.resolveWorkingDirectory', () {
    const workspacePath = '/tmp/genuine_ci_workspace';
    final genuineCI = GenuineCI.forTesting(workspacePath: workspacePath);

    test('returns workspace path when relative cwd is omitted', () {
      expect(genuineCI.resolveWorkingDirectory(), workspacePath);
    });

    test('returns workspace path when relative cwd is empty', () {
      expect(genuineCI.resolveWorkingDirectory(''), workspacePath);
    });

    test('joins relative cwd onto the workspace path', () {
      expect(
        genuineCI.resolveWorkingDirectory('apps/dashboard'),
        '$workspacePath${Platform.pathSeparator}apps/dashboard',
      );
    });
  });

  group('GenuineCI.placeFileFromBase64', () {
    late Directory workspace;
    late GenuineCI ci;

    setUp(() async {
      workspace = await Directory.systemTemp.createTemp(
        'genuine-ci-place-file-',
      );
      ci = GenuineCI.forTesting(
        workspacePath: workspace.path,
        currentWorkingDirectory: 'another-directory',
      );
    });

    tearDown(() => workspace.delete(recursive: true));

    test(
      'creates parent directories and restores text relative to the workspace',
      () async {
        const content = '// Firebase設定\nconst projectId = "test-project";\n';

        await ci.placeFileFromBase64(
          dir: const WorkspaceDirectory('apps/dashboard/lib'),
          fileName: 'firebase_options.dart',
          base64Content: base64Encode(utf8.encode(content)),
        );

        expect(
          await File(
            '${workspace.path}/apps/dashboard/lib/firebase_options.dart',
          ).readAsString(),
          content,
        );
        expect(
          Directory('${workspace.path}/another-directory').existsSync(),
          isFalse,
        );
      },
    );

    test('preserves binary bytes without decoding them as text', () async {
      final bytes = List<int>.generate(256, (index) => index);

      await ci.placeFileFromBase64(
        dir: const WorkspaceDirectory('signing'),
        fileName: 'certificate.p12',
        base64Content: base64Encode(bytes),
      );

      expect(
        await File('${workspace.path}/signing/certificate.p12').readAsBytes(),
        bytes,
      );
    });

    test(
      'overwrites an existing file without leaving old trailing bytes',
      () async {
        final file = File('${workspace.path}/config.txt');
        await file.writeAsString(
          'old content that is longer than the replacement',
        );

        await ci.placeFileFromBase64(
          dir: const WorkspaceDirectory('.'),
          fileName: 'config.txt',
          base64Content: base64Encode(utf8.encode('new')),
        );

        expect(await file.readAsString(), 'new');
      },
    );

    test('accepts empty Base64 as an empty file', () async {
      await ci.placeFileFromBase64(
        dir: const WorkspaceDirectory('.'),
        fileName: 'empty.txt',
        base64Content: '',
      );

      expect(await File('${workspace.path}/empty.txt').readAsBytes(), isEmpty);
    });

    for (final fileExists in [false, true]) {
      test(
        'invalid Base64 preserves the filesystem (existing file: $fileExists)',
        () async {
          final file = File('${workspace.path}/config/private.txt');
          if (fileExists) {
            await file.parent.create();
            await file.writeAsString('previous content');
          }

          await expectLater(
            ci.placeFileFromBase64(
              dir: const WorkspaceDirectory('config'),
              fileName: 'private.txt',
              base64Content: 'private-base64-content!!!',
            ),
            throwsA(
              isA<FormatException>()
                  .having(
                    (error) => error.message,
                    'message',
                    'Invalid Base64 content.',
                  )
                  .having((error) => error.source, 'source', isNull)
                  .having(
                    (error) => error.toString(),
                    'diagnostic',
                    isNot(contains('private-base64-content')),
                  ),
            ),
          );

          if (fileExists) {
            expect(await file.readAsString(), 'previous content');
          } else {
            expect(await file.parent.exists(), isFalse);
          }
        },
      );
    }

    test('propagates filesystem errors when a parent path is a file', () async {
      final parentFile = File('${workspace.path}/blocked');
      await parentFile.writeAsString('keep');

      await expectLater(
        ci.placeFileFromBase64(
          dir: const WorkspaceDirectory('blocked'),
          fileName: 'config.txt',
          base64Content: base64Encode(utf8.encode('new')),
        ),
        throwsA(isA<FileSystemException>()),
      );

      expect(await parentFile.readAsString(), 'keep');
    });
  });

  group('GenuineCI.init', () {
    test('retains all configured triggers as an immutable snapshot', () async {
      final triggers = [
        const CiTrigger.pullRequest(branch: 'develop'),
        const CiTrigger.push(branch: 'develop'),
      ];
      final ci = await GenuineCI.init(
        workflowName: 'Dashboard CI',
        ciTriggers: triggers,
      );
      triggers.clear();

      expect(ci.ciTriggers, const [
        CiTrigger.pullRequest(branch: 'develop'),
        CiTrigger.push(branch: 'develop'),
      ]);
      expect(() => ci.ciTriggers.clear(), throwsUnsupportedError);
    });

    test('initializes with default current directory as workspace', () async {
      final ci = await GenuineCI.init(
        workflowName: 'Test Workflow',
        ciTriggers: const [CiTrigger.push(branch: 'main')],
      );

      expect(ci.workflowName, 'Test Workflow');
      expect(ci.workspacePath, Directory.current.path);
    });

    test('initializes with custom workspace path', () async {
      final customPath = '${Directory.systemTemp.path}/custom_workspace';
      final ci = await GenuineCI.init(
        workflowName: 'Test Workflow',
        ciTriggers: const [CiTrigger.push(branch: 'main')],
        workspacePath: customPath,
      );

      expect(ci.workspacePath, customPath);
    });
  });
}
