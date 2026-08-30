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
    test(
      'read returns empty CliConfigData when config file does not exist',
      () async {
        final data = await config.get();
        expect(data, equals(const CliConfigData()));
        expect(data.language, isNull);
      },
    );

    test('write creates file and read loads the written data', () async {
      const input = CliConfigData(language: 'ja');
      await config.write(input);

      final data = await config.get();
      expect(data, equals(input));
      expect(data.language, equals('ja'));
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

        await nestedConfig.write(const CliConfigData(language: 'en'));

        expect(await File(nestedPath).exists(), isTrue);
        final data = await nestedConfig.get();
        expect(data, equals(const CliConfigData(language: 'en')));
      },
    );

    test('write overwrites existing config data', () async {
      await config.write(const CliConfigData(language: 'en'));
      await config.write(const CliConfigData(language: 'ja'));

      final data = await config.get();
      expect(data, equals(const CliConfigData(language: 'ja')));
    });

    test('read throws FormatException when config file is empty', () async {
      final file = File(customConfigPath);
      await file.writeAsString('   \n');

      expect(() => config.get(), throwsA(isA<FormatException>()));
    });

    test('read throws FormatException when JSON is malformed', () async {
      final file = File(customConfigPath);
      await file.writeAsString('{ invalid json }');

      expect(() => config.get(), throwsA(isA<FormatException>()));
    });

    test('read throws FormatException when root JSON is not a Map', () async {
      final file = File(customConfigPath);
      await file.writeAsString('["item1", "item2"]');

      expect(() => config.get(), throwsA(isA<FormatException>()));
    });
  });
}
