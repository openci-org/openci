import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';

import '../i18n/i18n.dart';
import '../update/cli_updater.dart';

class UpdateCommand extends Command<int> {
  @override
  final String name = 'update';

  @override
  String get description => t.update.description;

  final Logger _logger;
  final CliUpdater _updater;

  UpdateCommand({Logger? logger, CliUpdater? updater})
    : _logger = logger ?? Logger.standard(),
      _updater = updater ?? CliUpdater();

  @override
  Future<int> run() async {
    if (argResults!.rest.isNotEmpty) usageException(t.update.noArguments);

    final String? version;
    try {
      version = await _updater.getLatestUpdate(
        timeout: const Duration(seconds: 10),
      );
    } catch (_) {
      _logger.stderr(t.update.checkFailed);
      return 1;
    }
    if (version == null) {
      _logger.stdout(t.update.upToDate(version: _updater.currentVersion));
      return 0;
    }
    return _updater.install(version, _logger);
  }
}
