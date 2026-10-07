import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';

import '../../i18n/i18n.dart';

class SetupAscKeysCommand extends Command<int> {
  @override
  final String name = 'asc-keys';

  @override
  String get description => t.setup.ascKeys.description;

  final Logger _logger;

  SetupAscKeysCommand({required Logger logger}) : _logger = logger;

  @override
  int run() {
    if (argResults!.rest.isNotEmpty) {
      usageException(t.setup.ascKeys.noArguments);
    }

    _logger.stderr(t.setup.ascKeys.notImplemented);
    return 1;
  }
}
