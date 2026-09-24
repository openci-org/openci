import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:openci_shared/openci_shared.dart';

import '../../credential_store/credential_config.dart';
import '../../credential_store/credential_store.dart';
import '../../credential_store/read_authenticated_profile.dart';
import '../../i18n/i18n.dart';

class SecretRegistration {
  final Logger _logger;
  final CredentialStore _credentialStore;

  SecretRegistration({required Logger logger, CredentialStore? credentialStore})
    : _logger = logger,
      _credentialStore = credentialStore ?? CredentialStore();

  Future<AuthProfile?> readProfile() async {
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
    _logger.stderr(t.register.secret.loginRequired);
    return null;
  }

  Future<int> save(AuthProfile profile, String name, String value) async {
    final client = createOpenCIChopperClient(
      baseUrl: profile.serverUrl,
      tokenProvider: () => profile.token,
      services: [OpenCIApiService.create()],
    );
    try {
      final response = await client.getService<OpenCIApiService>().saveSecret(
        Uri.encodeComponent(profile.teamId),
        {'name': name, 'value': value},
      );
      if (!response.isSuccessful) {
        _logger.stderr(
          response.statusCode == HttpStatus.unauthorized ||
                  response.statusCode == HttpStatus.forbidden
              ? t.register.secret.loginRequired
              : t.register.secret.requestFailed(status: response.statusCode),
        );
        return 1;
      }
      _logger.stdout(
        t.register.secret.saved(name: name, teamId: profile.teamId),
      );
      return 0;
    } catch (_) {
      _logger.stderr(t.register.secret.saveFailed);
      return 1;
    } finally {
      client.dispose();
    }
  }
}
