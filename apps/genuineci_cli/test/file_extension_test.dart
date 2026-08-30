import 'dart:io';

import 'package:genuineci_cli/src/extensions/file_extension.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('genuineci_file_ext_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('AtomicFileExtension', () {
    test('writeAsStringAtomic writes content to target file', () async {
      final file = File(p.join(tempDir.path, 'test.txt'));
      await file.writeAsStringAtomic('Hello Atomic World');

      expect(await file.exists(), isTrue);
      expect(await file.readAsString(), equals('Hello Atomic World'));
    });

    test(
      'writeAsStringAtomic creates parent directories automatically',
      () async {
        final file = File(
          p.join(tempDir.path, 'nested', 'deeply', 'target.txt'),
        );
        await file.writeAsStringAtomic('Nested Content');

        expect(await file.exists(), isTrue);
        expect(await file.readAsString(), equals('Nested Content'));
      },
    );

    test('writeAsStringAtomic overwrites existing file', () async {
      final file = File(p.join(tempDir.path, 'overwrite.txt'));
      await file.writeAsStringAtomic('Initial');
      await file.writeAsStringAtomic('Updated');

      expect(await file.readAsString(), equals('Updated'));
    });
  });
}
