import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:openci_shared/openci_shared.dart';

import '../../credential_store/credential_config.dart';
import '../../credential_store/credential_store.dart';
import '../../credential_store/read_authenticated_profile.dart';
import '../../i18n/i18n.dart';
import '../../secrets/fetch_secret_names.dart';

class ListSecretsCommand extends Command<int> {
  @override
  final String name = 'secrets';

  @override
  String get description => t.list.secrets.description;

  final Logger _logger;
  final CredentialStore _credentialStore;

  ListSecretsCommand({required Logger logger, CredentialStore? credentialStore})
    : _logger = logger,
      _credentialStore = credentialStore ?? CredentialStore();

  @override
  Future<int> run() async {
    if (argResults!.rest.isNotEmpty) {
      usageException(t.list.secrets.noArguments);
    }
    final profile = await _readProfile();
    if (profile == null) return 1;

    final client = createOpenCIChopperClient(
      baseUrl: profile.serverUrl,
      tokenProvider: () => profile.token,
      services: [OpenCIApiService.create()],
    );
    try {
      final names = await fetchSecretNames(
        client.getService<OpenCIApiService>(),
        profile.teamId,
      );
      names.sort();
      if (names.isEmpty) {
        _logger.stdout(t.list.secrets.empty);
      } else {
        for (final name in names) {
          // Names from the API must not execute terminal control sequences.
          final displayName = name.replaceAllMapped(
            RegExp(r'[\x00-\x1f\x7f-\x9f]'),
            (match) =>
                '\\x${match[0]!.codeUnitAt(0).toRadixString(16).padLeft(2, '0')}',
          );
          _logger.stdout(displayName);
        }
      }
      return 0;
    } on SecretNamesHttpException catch (error) {
      _logger.stderr(
        error.statusCode == HttpStatus.unauthorized ||
                error.statusCode == HttpStatus.forbidden
            ? t.list.secrets.loginRequired
            : t.list.secrets.requestFailed(status: error.statusCode),
      );
    } catch (_) {
      _logger.stderr(t.list.secrets.fetchFailed);
    } finally {
      client.dispose();
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
          server.host.isNotEmpty &&
          server.userInfo.isEmpty &&
          !server.hasQuery &&
          !server.hasFragment) {
        return profile;
      }
    } catch (_) {
      // Credential errors can contain tokens; do not print them.
    }
    _logger.stderr(t.list.secrets.loginRequired);
    return null;
  }
}
