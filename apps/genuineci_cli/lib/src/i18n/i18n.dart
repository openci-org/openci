import '../config/cli_config.dart';
import '../gen/strings.g.dart';

export '../gen/strings.g.dart';

/// Initializes i18n / slang translations.
/// Defaults to English, unless Japanese ('ja') is configured.
void initI18n({EditLanguageConfig? languageConfig}) {
  final langConfig = languageConfig ?? EditLanguageConfig();
  final configuredLang = langConfig.getLanguage();

  if (configuredLang == 'ja') {
    LocaleSettings.setLocaleSync(AppLocale.ja);
  } else {
    LocaleSettings.setLocaleSync(AppLocale.en);
  }
}

class EditLanguageConfig {
  final CliConfig _config;

  EditLanguageConfig({CliConfig? config}) : _config = config ?? CliConfig();

  String? getLanguage() {
    final data = _config.readSync();
    return data['language'] as String?;
  }

  void setLanguage(String languageCode) {
    final data = _config.readSync();
    data['language'] = languageCode;
    _config.writeSync(data);

    final locale = AppLocaleUtils.parse(languageCode);
    LocaleSettings.setLocaleSync(locale);
  }
}
