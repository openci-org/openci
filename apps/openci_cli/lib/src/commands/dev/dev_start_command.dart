import 'dart:async';
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
typedef LocalDataSeeder =
    Future<bool> Function(Logger logger, {required Directory projectRoot});
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
  final Stream<ProcessSignal>? _interruptSignals;
  final Stream<ProcessSignal>? _terminateSignals;

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
    @visibleForTesting Stream<ProcessSignal>? interruptSignals,
    @visibleForTesting Stream<ProcessSignal>? terminateSignals,
  }) : _logger = logger,
       _projectRootFinder = projectRootFinder,
       _tartBaseImageChecker = tartBaseImageChecker,
       _dockerComposeStarter = dockerComposeStarter,
       _orchardContextSetup = orchardContextSetup,
       _localDataSeeder = localDataSeeder,
       _orchardWorkerStarter = orchardWorkerStarter,
       _interruptSignals = interruptSignals,
       _terminateSignals = terminateSignals {
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

    final interrupted = Completer<int>();
    void onSignal(ProcessSignal signal) {
      if (!interrupted.isCompleted) {
        interrupted.complete(128 + signal.signalNumber);
      }
    }

    final subscriptions = [
      (_interruptSignals ?? ProcessSignal.sigint.watch()).listen(onSignal),
      if (_terminateSignals != null || !Platform.isWindows)
        (_terminateSignals ?? ProcessSignal.sigterm.watch()).listen(onSignal),
    ];
    OrchardWorker? worker;
    var composeAttempted = false;

    Future<int> runUntilExit() async {
      final shouldSeedLocalData = argResults?['seed'] as bool? ?? false;
      final steps = <Future<bool> Function()>[
        () => _tartBaseImageChecker(_logger),
        () {
          // A failed `up` can still leave partially started containers.
          composeAttempted = true;
          return _dockerComposeStarter(
            _logger,
            projectRoot,
            step: DockerComposeStep.startAuthEmulator,
          );
        },
        () => _dockerComposeStarter(
          _logger,
          projectRoot,
          step: DockerComposeStep.startOrchardController,
        ),
        () => _orchardContextSetup(_logger),
        () async {
          worker = await _orchardWorkerStarter(_logger);
          return worker != null;
        },
        () => _dockerComposeStarter(
          _logger,
          projectRoot,
          step: DockerComposeStep.stopBuildJobWorker,
        ),
        () => _dockerComposeStarter(_logger, projectRoot),
        if (shouldSeedLocalData)
          () => _localDataSeeder(_logger, projectRoot: projectRoot),
      ];

      for (final step in steps) {
        if (interrupted.isCompleted) return interrupted.future;
        if (worker != null && !worker!.isRunning) {
          final code = await worker!.exitCode;
          return code == 0 ? 1 : code;
        }
        if (!await step()) return 1;
      }

      return Future.any([worker!.exitCode, interrupted.future]);
    }

    Future<bool> cleanup() async {
      var succeeded = true;
      // Request the worker stop before bringing the Compose stack down.
      final workerStopping = worker?.stop().then(
        (_) => true,
        onError: (Object error) {
          _logger.stderr('${t.dev.start.stepOrchardWorkerFailed}\n$error');
          return false;
        },
      );
      if (composeAttempted) {
        try {
          if (!await _dockerComposeStarter(
            _logger,
            projectRoot,
            step: DockerComposeStep.down,
          )) {
            succeeded = false;
          }
        } catch (error) {
          _logger.stderr('${t.dev.start.stepDockerComposeDownFailed}\n$error');
          succeeded = false;
        }
      }
      if (workerStopping != null && !await workerStopping) succeeded = false;
      return succeeded;
    }

    late final int result;
    late final bool cleanedUp;
    try {
      result = await runUntilExit();
    } finally {
      try {
        cleanedUp = await cleanup();
      } finally {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      }
    }

    if (!cleanedUp) return 1;
    return interrupted.isCompleted ? interrupted.future : result;
  }
}
