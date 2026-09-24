import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:openci_shared/openci_shared.dart';

import '../../credential_store/credential_config.dart';
import '../../credential_store/credential_store.dart';
import '../../credential_store/read_authenticated_profile.dart';
import '../../extensions/file_extensions.dart';
import '../../i18n/i18n.dart';
import '../../secrets/fetch_secret_names.dart';
import 'find_workflow_directory.dart';
import 'generate_secret_definitions.dart';

class SyncSecretsCommand extends Command<int> {
  @override
  final String name = 'secrets';

  @override
  String get description => t.sync.secrets.description;

  final Logger _logger;
  final CredentialStore _credentialStore;
  final Directory? _workingDirectory;

  SyncSecretsCommand({
    required Logger logger,
    CredentialStore? credentialStore,
    Directory? workingDirectory,
  }) : _logger = logger,
       _credentialStore = credentialStore ?? CredentialStore(),
       _workingDirectory = workingDirectory;

  @override
  Future<int> run() async {
    if (argResults!.rest.isNotEmpty) {
      usageException(t.sync.secrets.noArguments);
    }
    final profile = await _readProfile();
    if (profile == null) return 1;

    try {
      final directory = findWorkflowDirectory(_workingDirectory);
      if (directory == null) {
        _logger.stderr(t.sync.secrets.workflowDirectoryNotFound);
        return 1;
      }
      final names = await _fetchNames(profile);
      return await _writeDefinitions(directory, names);
    } on SecretNamesHttpException catch (error) {
      _logger.stderr(
        error.statusCode == HttpStatus.unauthorized ||
                error.statusCode == HttpStatus.forbidden
            ? t.sync.secrets.loginRequired
            : t.sync.secrets.requestFailed(status: error.statusCode),
      );
    } catch (_) {
      _logger.stderr(t.sync.secrets.fetchFailed);
    }
    return 1;
  }

  Future<AuthProfile?> _readProfile() async {
    try {
      final profile = await readAuthenticatedProfile(_credentialStore);
      final server = Uri.tryParse(profile?.serverUrl ?? '');
      if (profile != null &&
          profile.token.trim().isNotEmpty &&
          profile.teamId.trim().isNotEmpty &&
          server != null &&
          (server.scheme == 'http' || server.scheme == 'https') &&
          server.host.isNotEmpty) {
        return profile;
      }
    } catch (_) {
      // Invalid credential files can contain tokens; do not print their errors.
    }
    _logger.stderr(t.sync.secrets.loginRequired);
    return null;
  }

  Future<List<String>> _fetchNames(AuthProfile profile) async {
    final client = createOpenCIChopperClient(
      baseUrl: profile.serverUrl,
      tokenProvider: () => profile.token,
      services: [OpenCIApiService.create()],
    );
    try {
      return await fetchSecretNames(
        client.getService<OpenCIApiService>(),
        profile.teamId,
      );
    } finally {
      client.dispose();
    }
  }

  Future<int> _writeDefinitions(Directory directory, List<String> names) async {
    try {
      final source = generateSecretDefinitions(names);
      final file = File('${directory.path}/secrets.g.dart');
      await file.writeAsStringAtomic(source);
      _logger.stdout(t.sync.secrets.saved(path: file.path));
      return 0;
    } on FormatException catch (error) {
      _logger.stderr(t.common.error(error: error.message));
    } on FileSystemException {
      _logger.stderr(t.sync.secrets.saveFailed);
    }
    return 1;
  }
}
