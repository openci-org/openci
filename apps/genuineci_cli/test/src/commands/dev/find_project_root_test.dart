import 'dart:io';

import 'package:genuineci_cli/src/commands/dev/find_project_root.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('find_project_root_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('isOpenciProjectRoot', () {
    test(
      'returns true when both docker-compose.yml and apps/openci_server exist',
      () async {
        final composeFile = File(p.join(tempDir.path, 'docker-compose.yml'));
        await composeFile.writeAsString('services: {}');

        final serverDir = Directory(
          p.join(tempDir.path, 'apps', 'openci_server'),
        );
        await serverDir.create(recursive: true);

        expect(isOpenciProjectRoot(tempDir), isTrue);
      },
    );

    test('returns false when only docker-compose.yml exists', () async {
      final composeFile = File(p.join(tempDir.path, 'docker-compose.yml'));
      await composeFile.writeAsString('services: {}');

      expect(isOpenciProjectRoot(tempDir), isFalse);
    });

    test('returns false when only apps/openci_server exists', () async {
      final serverDir = Directory(
        p.join(tempDir.path, 'apps', 'openci_server'),
      );
      await serverDir.create(recursive: true);

      expect(isOpenciProjectRoot(tempDir), isFalse);
    });

    test(
      'returns false when neither docker-compose.yml nor apps/openci_server exists',
      () {
        expect(isOpenciProjectRoot(tempDir), isFalse);
      },
    );
  });

  group('findProjectRoot', () {
    test(
      'finds project root from nested subdirectory when both docker-compose.yml and apps/openci_server exist',
      () async {
        final rootComposeFile = File(
          p.join(tempDir.path, 'docker-compose.yml'),
        );
        await rootComposeFile.writeAsString('services: {}');

        final serverDir = Directory(
          p.join(tempDir.path, 'apps', 'openci_server'),
        );
        await serverDir.create(recursive: true);

        final cliNestedDir = Directory(
          p.join(tempDir.path, 'apps', 'genuineci_cli', 'nested'),
        );
        await cliNestedDir.create(recursive: true);

        final foundRoot = findProjectRoot(cliNestedDir);
        expect(foundRoot, isNotNull);
        expect(foundRoot!.path, equals(tempDir.path));
      },
    );

    test(
      'ignores unrelated docker-compose.yml if apps/openci_server is missing and continues searching parent',
      () async {
        // Outer dir: valid OpenCI root
        final openciRoot = Directory(p.join(tempDir.path, 'openci_repo'));
        await openciRoot.create(recursive: true);
        await File(
          p.join(openciRoot.path, 'docker-compose.yml'),
        ).writeAsString('services: {}');
        await Directory(
          p.join(openciRoot.path, 'apps', 'openci_server'),
        ).create(recursive: true);

        // Inner dir: unrelated project with only docker-compose.yml
        final unrelatedSubDir = Directory(
          p.join(openciRoot.path, 'subprojects', 'other_docker_project'),
        );
        await unrelatedSubDir.create(recursive: true);
        await File(
          p.join(unrelatedSubDir.path, 'docker-compose.yml'),
        ).writeAsString('services: {}');

        // Start search from deep inside the unrelated project
        final startDir = Directory(p.join(unrelatedSubDir.path, 'src'));
        await startDir.create(recursive: true);

        final foundRoot = findProjectRoot(startDir);
        expect(foundRoot, isNotNull);
        expect(foundRoot!.path, equals(openciRoot.path));
      },
    );

    test('returns null when OpenCI project root is not found', () async {
      final emptySubDir = Directory(
        p.join(tempDir.path, 'empty_dir', 'nested'),
      );
      await emptySubDir.create(recursive: true);

      final foundRoot = findProjectRoot(emptySubDir);
      expect(foundRoot, isNull);
    });
  });
}
