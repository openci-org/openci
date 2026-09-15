import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:meta/meta.dart';
import 'package:openci_shared/openci_shared.dart';

import '../../credential_store/credential_config.dart';
import '../../credential_store/credential_store.dart';
import '../../credential_store/read_authenticated_profile.dart';
import '../../i18n/i18n.dart';
import 'read_secret_input.dart';

class RegisterSecretCommand extends Command<int> {
  @override
  final String name = 'secret';

  @override
  String get description => t.register.secret.description;

  final Logger _logger;
  final CredentialStore _credentialStore;
  final Future<SecretInput?> Function() _readInput;

  RegisterSecretCommand({
    required Logger logger,
    CredentialStore? credentialStore,
    @visibleForTesting
    Future<SecretInput?> Function() readInput = readSecretInput,
  }) : _logger = logger,
       _credentialStore = credentialStore ?? CredentialStore(),
       _readInput = readInput;

  @override
  Future<int> run() async {
    if (argResults!.rest.isNotEmpty) {
      usageException(t.register.secret.noArguments);
    }

    final profile = await _readProfile();
    if (profile == null) return 1;

    final SecretInput? secret;
    try {
      secret = await _readInput();
    } catch (_) {
      _logger.stderr(t.register.secret.inputFailed);
      return 1;
    }
    if (secret == null || secret.value.trim().isEmpty) {
      _logger.stderr(t.register.secret.inputRequired);
      return 1;
    }
    if (RegExp(r'[A-Za-z_][A-Za-z0-9_]*').matchAsPrefix(secret.name)?.end !=
        secret.name.length) {
      _logger.stderr(t.register.secret.invalidName);
      return 1;
    }
    return _saveSecret(profile, secret.name, secret.value);
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
    _logger.stderr(t.register.secret.loginRequired);
    return null;
  }

  Future<int> _saveSecret(
    AuthProfile profile,
    String secretName,
    String value,
  ) async {
    final client = createOpenCiChopperClient(
      baseUrl: profile.serverUrl,
      tokenProvider: () => profile.token,
      services: [OpenCiApiService.create()],
    );
    try {
      final response = await client.getService<OpenCiApiService>().saveSecret(
        Uri.encodeComponent(profile.teamId),
        {'name': secretName, 'value': value},
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
        t.register.secret.saved(name: secretName, teamId: profile.teamId),
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
