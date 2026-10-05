import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';

import '../i18n/i18n.dart';

class UseCommand extends Command<int> {
  static const languages = {
    'japanese': (code: 'ja', name: 'Japanese'),
    'english': (code: 'en', name: 'English'),
  };

  @override
  final String name = 'use';

  @override
  String get description => t.use.description;

  final EditLanguageConfig _languageConfig;
  final Logger _logger;

  UseCommand({EditLanguageConfig? languageConfig, Logger? logger})
    : _languageConfig = languageConfig ?? EditLanguageConfig(),
      _logger = logger ?? Logger.standard();

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? [];
    if (rest.isEmpty) {
      _logger.stderr('Usage: genuineci use <japanese|english>');
      return 64; // EX_USAGE
    }

    final input = rest.first.toLowerCase().trim();
    final language = languages[input];
    if (language == null) {
      _logger.stderr(t.use.invalidLanguage(input: input));
      return 1;
    }

    await _languageConfig.setLanguage(language.code);
    _logger.stdout(t.use.success(language: language.name));
    return 0;
  }
}
