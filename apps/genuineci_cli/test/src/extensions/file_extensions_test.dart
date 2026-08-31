import 'dart:io';

import 'package:genuineci_cli/src/extensions/file_extensions.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('file_extensions_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('AtomicFileExtension', () {
    test('writeAsStringAtomic successfully writes content', () async {
      final file = File(p.join(tempDir.path, 'test.txt'));
      await file.writeAsStringAtomic('hello world');

      expect(await file.exists(), isTrue);
      expect(await file.readAsString(), equals('hello world'));
    });

    test('writeAsStringAtomic creates parent directories if needed', () async {
      final file = File(p.join(tempDir.path, 'nested', 'sub', 'test.txt'));
      await file.writeAsStringAtomic('nested content');

      expect(await file.exists(), isTrue);
      expect(await file.readAsString(), equals('nested content'));
    });

    test('writeAsStringAtomic overwrites existing file', () async {
      final file = File(p.join(tempDir.path, 'test.txt'));
      await file.writeAsStringAtomic('initial');
      await file.writeAsStringAtomic('updated');

      expect(await file.readAsString(), equals('updated'));
    });

    test(
      'writeAsStringAtomic sets permissions to 0600 when chmod600 is true',
      () async {
        final file = File(p.join(tempDir.path, 'secret.txt'));
        await file.writeAsStringAtomic('secret content', chmod600: true);

        expect(await file.exists(), isTrue);
        expect(await file.readAsString(), equals('secret content'));

        if (!Platform.isWindows) {
          final stat = await file.stat();
          expect(stat.modeString(), contains('rw-------'));
        }
      },
    );
  });
}
