import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';

import '../../i18n/i18n.dart';
import 'check_tart_base_image.dart';
import 'find_project_root.dart';
import 'start_docker_compose.dart';

class DevStartCommand extends Command<int> {
  @override
  final String name = 'start';

  @override
  String get description => t.dev.start.description;

  final Logger _logger;

  DevStartCommand({required Logger logger}) : _logger = logger;

  @override
  Future<int> run() async {
    _logger.stdout(t.dev.start.starting);

    final projectRoot = findProjectRoot();
    if (projectRoot == null) {
      _logger.stderr(t.dev.start.projectRootNotFound);
      return 1;
    }

    final hasTartImage = await checkTartBaseImage(_logger);
    if (!hasTartImage) {
      return 1;
    }

    final didStartDockerCompose = await startDockerCompose(
      _logger,
      projectRoot,
    );
    if (!didStartDockerCompose) {
      return 1;
    }

    return 0;
  }
}
