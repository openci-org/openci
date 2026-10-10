import 'dart:io';

import 'package:cli_util/cli_logging.dart';

import '../../credential_store/credential_store.dart';
import 'sync_paths.dart';
import 'sync_secrets.dart';

class SyncWorkspace {
  final SyncPaths _paths;
  final SyncSecrets _secrets;

  SyncWorkspace({
    required Logger logger,
    CredentialStore? credentialStore,
    Directory? workingDirectory,
  }) : _paths = SyncPaths(logger: logger, workingDirectory: workingDirectory),
       _secrets = SyncSecrets(
         logger: logger,
         credentialStore: credentialStore,
         workingDirectory: workingDirectory,
       );

  Future<int> run({bool paths = true, bool secrets = true}) async {
    final pathsExitCode = paths ? await _paths.run() : 0;
    final secretsExitCode = secrets ? await _secrets.run() : 0;
    return pathsExitCode != 0 ? pathsExitCode : secretsExitCode;
  }
}
