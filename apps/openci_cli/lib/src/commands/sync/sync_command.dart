import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';

import '../../credential_store/credential_store.dart';
import '../../i18n/i18n.dart';
import 'sync_workspace.dart';

class SyncCommand extends Command<int> {
  @override
  final String name = 'sync';

  @override
  String get description => t.sync.description;

  final SyncWorkspace _sync;

  SyncCommand({
    required Logger logger,
    CredentialStore? credentialStore,
    Directory? workingDirectory,
  }) : _sync = SyncWorkspace(
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
    return _sync.run(
      paths: syncAll || arguments.flag('paths'),
      secrets: syncAll || arguments.flag('secrets'),
    );
  }
}
