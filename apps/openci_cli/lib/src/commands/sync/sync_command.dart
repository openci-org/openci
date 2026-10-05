import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';

import '../../credential_store/credential_store.dart';
import '../../i18n/i18n.dart';
import 'sync_paths.dart';
import 'sync_secrets.dart';

class SyncCommand extends Command<int> {
  @override
  final String name = 'sync';

  @override
  String get description => t.sync.description;

  final SyncPaths _paths;
  final SyncSecrets _secrets;

  SyncCommand({
    required Logger logger,
    CredentialStore? credentialStore,
    Directory? workingDirectory,
  }) : _paths = SyncPaths(logger: logger, workingDirectory: workingDirectory),
       _secrets = SyncSecrets(
         logger: logger,
         credentialStore: credentialStore,
         workingDirectory: workingDirectory,
       ) {
    argParser
      ..addFlag('secrets', negatable: false, help: t.sync.secrets.description)
      ..addFlag('paths', negatable: false, help: t.sync.paths.description);
  }

  @override
  Future<int> run() async {
    final arguments = argResults!;
    if (arguments.rest.isNotEmpty) {
      usageException(t.sync.noArguments);
    }
    final syncAll = !arguments.flag('secrets') && !arguments.flag('paths');
    final pathsExitCode = syncAll || arguments.flag('paths')
        ? await _paths.run()
        : 0;
    final secretsExitCode = syncAll || arguments.flag('secrets')
        ? await _secrets.run()
        : 0;
    return pathsExitCode != 0 ? pathsExitCode : secretsExitCode;
  }
}
