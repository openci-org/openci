import 'dart:io';

import 'package:genuineci_cli/src/asc/prepare_asc_key_directory.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test(
    'reserves separate owner-only directories under application data',
    () async {
      final data = await Directory.systemTemp.createTemp('asc data test ');
      addTearDown(() => data.delete(recursive: true));
      final first = await prepareAscKeyDirectory(dataDirectory: data);
      final key = await File(
        p.join(first.path, 'existing.p8'),
      ).writeAsString('test');
      final second = await prepareAscKeyDirectory(dataDirectory: data);

      expect(first.path, isNot(second.path));
      expect(p.isWithin(p.join(data.path, 'asc-api-keys'), first.path), isTrue);
      expect(
        p.isWithin(p.join(data.path, 'asc-api-keys'), second.path),
        isTrue,
      );
      expect(await key.readAsString(), 'test');
      if (!Platform.isWindows) {
        expect((await first.stat()).mode & 0x1ff, 0x1c0);
        expect((await second.stat()).mode & 0x1ff, 0x1c0);
      }
    },
  );

  test('propagates inability to reserve a directory', () async {
    final data = await Directory.systemTemp.createTemp('asc data test ');
    addTearDown(() => data.delete(recursive: true));
    await File(p.join(data.path, 'asc-api-keys')).writeAsString('occupied');

    await expectLater(
      prepareAscKeyDirectory(dataDirectory: data),
      throwsA(isA<FileSystemException>()),
    );
  });
}
