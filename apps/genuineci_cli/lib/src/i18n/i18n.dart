import '../config/cli_config.dart';
import '../gen/strings.g.dart';

export '../gen/strings.g.dart';

/// Initializes i18n / slang translations.
/// Defaults to English, unless Japanese ('ja') is configured.
void initI18n({CliConfig? config}) {
  final cliConfig = config ?? CliConfig();
  final configuredLang = cliConfig.getLanguage();

  if (configuredLang == 'ja') {
    LocaleSettings.setLocaleSync(AppLocale.ja);
  } else {
    LocaleSettings.setLocaleSync(AppLocale.en);
  }
}
