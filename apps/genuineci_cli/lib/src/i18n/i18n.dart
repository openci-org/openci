import '../config/cli_config.dart';
import '../gen/strings.g.dart';

export '../gen/strings.g.dart';

Future<void> initI18n({EditLanguageConfig? languageConfig}) async {
  final langConfig = languageConfig ?? EditLanguageConfig();
  final configuredLang = await langConfig.getLanguage();

  if (configuredLang == 'ja') {
    LocaleSettings.setLocaleSync(AppLocale.ja);
  } else {
    LocaleSettings.setLocaleSync(AppLocale.en);
  }
}

class EditLanguageConfig {
  final CliConfig _config;

  EditLanguageConfig({CliConfig? config}) : _config = config ?? CliConfig();

  Future<String?> getLanguage() async {
    final data = await _config.read();
    return data['language'] as String?;
  }

  Future<void> setLanguage(String languageCode) async {
    final data = await _config.read();
    data['language'] = languageCode;
    await _config.write(data);

    final locale = AppLocaleUtils.parse(languageCode);
    LocaleSettings.setLocaleSync(locale);
  }
}
