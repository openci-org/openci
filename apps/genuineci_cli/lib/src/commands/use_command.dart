import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';

import '../config/cli_config.dart';
import '../i18n/i18n.dart';

class UseCommand extends Command<int> {
  @override
  final String name = 'use';

  @override
  String get description => t.use.description;

  final CliConfig _config;
  final Logger _logger;

  UseCommand({CliConfig? config, Logger? logger})
    : _config = config ?? CliConfig(),
      _logger = logger ?? Logger.standard();

  @override
  Future<int> run() async {
    final rest = argResults?.rest ?? [];
    if (rest.isEmpty) {
      _logger.stderr('Usage: genuineci use <japanese|english>');
      return 64; // EX_USAGE
    }

    final input = rest.first.toLowerCase().trim();
    final String targetCode;
    final String languageName;

    switch (input) {
      case 'japanese':
        targetCode = 'ja';
        languageName = 'Japanese';
        break;
      case 'english':
        targetCode = 'en';
        languageName = 'English';
        break;
      default:
        _logger.stderr(t.use.invalidLanguage(input: input));
        return 1;
    }

    _config.setLanguage(targetCode);
    LocaleSettings.setLocaleSync(AppLocaleUtils.parse(targetCode));

    _logger.stdout(t.use.success(language: languageName));
    return 0;
  }
}
