import 'dart:io';

import 'package:genuineci_cli/genuineci_cli.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late String customConfigPath;
  late CliConfig config;
  late EditLanguageConfig languageConfig;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('genuineci_i18n_test_');
    customConfigPath = p.join(tempDir.path, 'config.json');
    config = CliConfig(customFilePath: customConfigPath);
    languageConfig = EditLanguageConfig(config: config);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('EditLanguageConfig', () {
    test('getLanguage returns null when no config exists', () async {
      final lang = await languageConfig.getLanguage();
      expect(lang, isNull);
    });

    test('setLanguage saves language and updates LocaleSettings', () async {
      await languageConfig.setLanguage('ja');

      final lang = await languageConfig.getLanguage();
      expect(lang, equals('ja'));
      expect(LocaleSettings.currentLocale, equals(AppLocale.ja));

      await languageConfig.setLanguage('en');
      expect(await languageConfig.getLanguage(), equals('en'));
      expect(LocaleSettings.currentLocale, equals(AppLocale.en));
    });
  });

  group('initI18n', () {
    test('initI18n defaults to en when no config exists', () async {
      await initI18n(languageConfig: languageConfig);
      expect(LocaleSettings.currentLocale, equals(AppLocale.en));
    });

    test('initI18n applies ja when config has ja', () async {
      await config.set(const CliConfigData(language: 'ja'));
      await initI18n(languageConfig: languageConfig);
      expect(LocaleSettings.currentLocale, equals(AppLocale.ja));
    });
  });
}
