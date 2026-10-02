import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';

import '../../i18n/i18n.dart';

class SwitchTeamCommand extends Command<int> {
  @override
  final String name = 'team';

  @override
  String get description => t.switchCommand.team.description;

  final Logger _logger;

  SwitchTeamCommand({required Logger logger}) : _logger = logger;

  @override
  int run() {
    if (argResults!.rest.isNotEmpty) {
      usageException(t.switchCommand.team.noArguments);
    }

    _logger.stderr(t.switchCommand.team.unavailable);
    return 1;
  }
}
