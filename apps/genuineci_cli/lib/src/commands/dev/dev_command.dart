import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';

import '../../i18n/i18n.dart';

class DevCommand extends Command<int> {
  @override
  final String name = 'dev';

  @override
  String get description => t.dev.description;

  DevCommand({Logger? logger}) {
    // Subcommands can be added here
  }
}
