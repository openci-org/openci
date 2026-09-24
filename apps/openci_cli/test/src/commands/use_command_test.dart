import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:openci_cli/openci_cli.dart';
import 'package:test/test.dart';

class _RecordingLogger implements Logger {
  final output = <String>[];
  final errors = <String>[];

  @override
  void stdout(String message) => output.add(message);

  @override
  void stderr(String message) => errors.add(message);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Directory directory;
  late CliConfig config;
  late EditLanguageConfig language;
  late _RecordingLogger logger;
  late CommandRunner<int> runner;
  late AppLocale originalLocale;

  setUp(() async {
    originalLocale = LocaleSettings.currentLocale;
    LocaleSettings.setLocaleSync(AppLocale.en);
    directory = await Directory.systemTemp.createTemp('openci-language-test-');
    config = CliConfig(customFilePath: '${directory.path}/config.json');
    language = EditLanguageConfig(config: config);
    logger = _RecordingLogger();
    runner = CommandRunner<int>('openci', 'test')
      ..addCommand(UseCommand(languageConfig: language, logger: logger));
  });

  tearDown(() async {
    LocaleSettings.setLocaleSync(originalLocale);
    await directory.delete(recursive: true);
  });

  for (final (input, code, locale, label) in [
    ('japanese', 'ja', AppLocale.ja, 'Japanese'),
    ('english', 'en', AppLocale.en, 'English'),
    ('  JAPANESE  ', 'ja', AppLocale.ja, 'Japanese'),
    ('  English  ', 'en', AppLocale.en, 'English'),
  ]) {
    test('use $input persists and restores the selected language', () async {
      expect(await runner.run(['use', input]), 0);
      expect(await language.getLanguage(), code);
      expect(LocaleSettings.currentLocale, locale);
      expect(logger.output, [t.use.success(language: label)]);
      expect(logger.errors, isEmpty);

      LocaleSettings.setLocaleSync(
        locale == AppLocale.en ? AppLocale.ja : AppLocale.en,
      );
      await initI18n(
        languageConfig: EditLanguageConfig(
          config: CliConfig(customFilePath: config.filePath),
        ),
      );
      expect(LocaleSettings.currentLocale, locale);
    });
  }

  test(
    'missing arguments preserve the saved language and report usage',
    () async {
      await language.setLanguage('ja');
      final before = await File(config.filePath).readAsString();
      expect(await runner.run(['use']), 64);
      expect(await File(config.filePath).readAsString(), before);
      expect(LocaleSettings.currentLocale, AppLocale.ja);
      expect(logger.output, isEmpty);
      expect(logger.errors, ['Usage: openci use <japanese|english>']);
    },
  );

  test('unknown language does not change the file or active locale', () async {
    await language.setLanguage('ja');
    final before = await File(config.filePath).readAsString();
    expect(await runner.run(['use', 'klingon']), 1);
    expect(await File(config.filePath).readAsString(), before);
    expect(LocaleSettings.currentLocale, AppLocale.ja);
    expect(logger.output, isEmpty);
    expect(logger.errors, [t.use.invalidLanguage(input: 'klingon')]);
  });

  test(
    'failed persistence does not report success or change the locale',
    () async {
      await Directory(config.filePath).create();
      await expectLater(
        runner.run(['use', 'japanese']),
        throwsA(isA<FileSystemException>()),
      );
      expect(LocaleSettings.currentLocale, AppLocale.en);
      expect(logger.output, isEmpty);
      expect(await Directory(config.filePath).exists(), isTrue);
      expect(await directory.list().map((entry) => entry.path).toList(), [
        config.filePath,
      ]);
    },
  );

  test(
    'startup defaults to English without creating a configuration file',
    () async {
      LocaleSettings.setLocaleSync(AppLocale.ja);
      await initI18n(languageConfig: language);
      expect(LocaleSettings.currentLocale, AppLocale.en);
      expect(await File(config.filePath).exists(), isFalse);
    },
  );

  test('startup uses English for an unsupported stored locale', () async {
    await config.set(const CliConfigData(language: 'unsupported'));
    LocaleSettings.setLocaleSync(AppLocale.ja);
    await initI18n(languageConfig: language);
    expect(LocaleSettings.currentLocale, AppLocale.en);
    expect((await config.get()).language, 'unsupported');
  });

  test(
    'startup preserves malformed configuration and reports the error',
    () async {
      await File(config.filePath).writeAsString('{');
      await expectLater(
        initI18n(languageConfig: language),
        throwsFormatException,
      );
      expect(LocaleSettings.currentLocale, AppLocale.en);
      expect(await File(config.filePath).readAsString(), '{');
    },
  );

  test(
    'help describes the use command without writing configuration',
    () async {
      final help = runner.commands['use']!.usage;
      expect(help, contains(t.use.description));
      expect(help, contains('openci use'));
      expect(await File(config.filePath).exists(), isFalse);
      expect(LocaleSettings.currentLocale, AppLocale.en);
    },
  );
}
