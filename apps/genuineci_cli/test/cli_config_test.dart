import 'dart:io';

import 'package:genuineci_cli/genuineci_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late String customConfigPath;
  late CliConfig config;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('genuineci_config_test_');
    customConfigPath = p.join(tempDir.path, 'config.json');
    config = CliConfig(customFilePath: customConfigPath);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('CliConfig', () {
    test('read returns empty Map when config file does not exist', () async {
      final data = await config.read();
      expect(data, isEmpty);
    });

    test('write creates file and read loads the written data', () async {
      final input = {'language': 'ja'};
      await config.write(input);

      final data = await config.read();
      expect(data, equals(input));
    });

    test(
      'write automatically creates parent directories if not exist',
      () async {
        final nestedPath = p.join(
          tempDir.path,
          'nested',
          'sub',
          'custom_config.json',
        );
        final nestedConfig = CliConfig(customFilePath: nestedPath);

        await nestedConfig.write({'key': 'value'});

        expect(await File(nestedPath).exists(), isTrue);
        final data = await nestedConfig.read();
        expect(data, equals({'key': 'value'}));
      },
    );

    test('write overwrites existing config data', () async {
      await config.write({'language': 'en'});
      await config.write({'language': 'ja', 'version': 1});

      final data = await config.read();
      expect(data, equals({'language': 'ja', 'version': 1}));
    });

    test('read throws FormatException when config file is empty', () async {
      final file = File(customConfigPath);
      await file.writeAsString('   \n');

      expect(() => config.read(), throwsA(isA<FormatException>()));
    });

    test('read throws FormatException when JSON is malformed', () async {
      final file = File(customConfigPath);
      await file.writeAsString('{ invalid json }');

      expect(() => config.read(), throwsA(isA<FormatException>()));
    });

    test('read throws FormatException when root JSON is not a Map', () async {
      final file = File(customConfigPath);
      await file.writeAsString('["item1", "item2"]');

      expect(() => config.read(), throwsA(isA<FormatException>()));
    });
  });
}
