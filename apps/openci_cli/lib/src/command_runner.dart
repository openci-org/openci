import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';

import 'commands/dev/dev_command.dart';
import 'commands/list/list_command.dart';
import 'commands/login_command.dart';
import 'commands/register/register_command.dart';
import 'commands/sync/sync_command.dart';
import 'commands/use_command.dart';
import 'i18n/i18n.dart';

const String openCIVersion = '0.0.1';

class OpenCICommandRunner extends CommandRunner<int> {
  final Logger _logger;

  OpenCICommandRunner({Logger? logger})
    : _logger = logger ?? Logger.standard(),
      super('openci', t.cli.description) {
    argParser
      ..addFlag(
        'version',
        abbr: 'v',
        negatable: false,
        help: t.cli.flags.version,
      )
      ..addFlag('verbose', negatable: false, help: t.cli.flags.verbose);

    addCommand(LoginCommand(logger: _logger));
    addCommand(ListCommand(logger: _logger));
    addCommand(RegisterCommand(logger: _logger));
    addCommand(UseCommand(logger: _logger));
    addCommand(DevCommand(logger: _logger));
    addCommand(SyncCommand(logger: _logger));
  }

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults['version'] == true) {
      _logger.stdout(t.cli.version(version: openCIVersion));
      return 0;
    }
    return await super.runCommand(topLevelResults);
  }
}
