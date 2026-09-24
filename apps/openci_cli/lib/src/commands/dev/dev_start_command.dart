import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:meta/meta.dart';

import '../../i18n/i18n.dart';
import 'check_tart_base_image.dart';
import 'find_project_root.dart';
import 'seed_local_data.dart';
import 'setup_orchard_context.dart';
import 'start_docker_compose.dart';
import 'start_orchard_worker.dart';

typedef ProjectRootFinder = Directory? Function();
typedef TartBaseImageChecker = Future<bool> Function(Logger logger);
typedef DockerComposeStarter =
    Future<bool> Function(
      Logger logger,
      Directory projectRoot, {
      DockerComposeStep step,
    });
typedef OrchardContextSetup = Future<bool> Function(Logger logger);
typedef LocalDataSeeder = Future<bool> Function(Logger logger);
typedef OrchardWorkerStarter = Future<OrchardWorker?> Function(Logger logger);

class DevStartCommand extends Command<int> {
  @override
  final String name = 'start';

  @override
  String get description => t.dev.start.description;

  final Logger _logger;
  final ProjectRootFinder _projectRootFinder;
  final TartBaseImageChecker _tartBaseImageChecker;
  final DockerComposeStarter _dockerComposeStarter;
  final OrchardContextSetup _orchardContextSetup;
  final LocalDataSeeder _localDataSeeder;
  final OrchardWorkerStarter _orchardWorkerStarter;

  DevStartCommand({
    required Logger logger,
    @visibleForTesting ProjectRootFinder projectRootFinder = findProjectRoot,
    @visibleForTesting
    TartBaseImageChecker tartBaseImageChecker = checkTartBaseImage,
    @visibleForTesting
    DockerComposeStarter dockerComposeStarter = startDockerCompose,
    @visibleForTesting
    OrchardContextSetup orchardContextSetup = setupOrchardContext,
    @visibleForTesting LocalDataSeeder localDataSeeder = seedLocalData,
    @visibleForTesting
    OrchardWorkerStarter orchardWorkerStarter = startOrchardWorker,
  }) : _logger = logger,
       _projectRootFinder = projectRootFinder,
       _tartBaseImageChecker = tartBaseImageChecker,
       _dockerComposeStarter = dockerComposeStarter,
       _orchardContextSetup = orchardContextSetup,
       _localDataSeeder = localDataSeeder,
       _orchardWorkerStarter = orchardWorkerStarter {
    argParser.addFlag('seed', negatable: false, help: t.dev.start.flags.seed);
  }

  @override
  Future<int> run() async {
    _logger.stdout(t.dev.start.starting);

    final projectRoot = _projectRootFinder();
    if (projectRoot == null) {
      _logger.stderr(t.dev.start.projectRootNotFound);
      return 1;
    }

    final hasTartImage = await _tartBaseImageChecker(_logger);
    if (!hasTartImage) {
      return 1;
    }

    final didStartController = await _dockerComposeStarter(
      _logger,
      projectRoot,
      step: DockerComposeStep.startOrchardController,
    );
    if (!didStartController) {
      return 1;
    }

    final didSetupOrchardContext = await _orchardContextSetup(_logger);
    if (!didSetupOrchardContext) {
      return 1;
    }

    final worker = await _orchardWorkerStarter(_logger);
    if (worker == null) {
      return 1;
    }

    try {
      final shouldSeedLocalData = argResults?['seed'] as bool? ?? false;
      for (final start in [
        () => _dockerComposeStarter(
          _logger,
          projectRoot,
          step: DockerComposeStep.stopBuildJobWorker,
        ),
        () => _dockerComposeStarter(_logger, projectRoot),
        if (shouldSeedLocalData) () => _localDataSeeder(_logger),
      ]) {
        if (!worker.isRunning) {
          final code = await worker.exitCode;
          return code == 0 ? 1 : code;
        }
        if (!await start()) {
          return 1;
        }
      }

      return await worker.exitCode;
    } finally {
      await worker.stop();
    }
  }
}
