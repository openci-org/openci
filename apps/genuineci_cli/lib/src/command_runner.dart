import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';

import 'commands/login_command.dart';
import 'commands/use_command.dart';
import 'i18n/i18n.dart';

const String genuineCiVersion = '0.0.1';

class GenuineCiCommandRunner extends CommandRunner<int> {
  final Logger _logger;

  GenuineCiCommandRunner({Logger? logger})
    : _logger = logger ?? Logger.standard(),
      super('genuineci', t.cli.description) {
    argParser
      ..addFlag(
        'version',
        abbr: 'v',
        negatable: false,
        help: t.cli.flags.version,
      )
      ..addFlag('verbose', negatable: false, help: t.cli.flags.verbose);

    addCommand(LoginCommand());
    addCommand(UseCommand(logger: _logger));
  }

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults['version'] == true) {
      _logger.stdout(t.cli.version(version: genuineCiVersion));
      return 0;
    }
    return await super.runCommand(topLevelResults);
  }
}
