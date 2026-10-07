import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:openci_shared/openci_shared.dart';

import '../../credential_store/credential_config.dart';
import '../../credential_store/credential_store.dart';
import '../../credential_store/read_authenticated_profile.dart';
import '../../i18n/i18n.dart';

class DeleteSecretCommand extends Command<int> {
  @override
  final String name = 'secret';

  @override
  String get description => t.delete.secret.description;

  @override
  String get invocation =>
      '${runner!.executableName} delete secret SECRET_NAME';

  final Logger _logger;
  final CredentialStore _credentialStore;

  DeleteSecretCommand({
    required Logger logger,
    CredentialStore? credentialStore,
  }) : _logger = logger,
       _credentialStore = credentialStore ?? CredentialStore();

  @override
  Future<int> run() async {
    final arguments = argResults!.rest;
    if (arguments.length != 1 || arguments.single.trim().isEmpty) {
      usageException(t.delete.secret.nameRequired);
    }
    final secretName = arguments.single;
    // URI normalization would turn these names into a different endpoint.
    if (secretName == '.' || secretName == '..') {
      usageException(t.delete.secret.invalidName);
    }

    final profile = await _readProfile();
    if (profile == null) return 1;

    final client = createOpenCIChopperClient(
      baseUrl: profile.serverUrl,
      tokenProvider: () => profile.token,
      services: [OpenCIApiService.create()],
    );
    try {
      final response = await client.getService<OpenCIApiService>().deleteSecret(
        Uri.encodeComponent(profile.teamId),
        Uri.encodeComponent(secretName),
      );
      if (!response.isSuccessful) {
        _logger.stderr(switch (response.statusCode) {
          HttpStatus.unauthorized ||
          HttpStatus.forbidden => t.delete.secret.loginRequired,
          HttpStatus.notFound => t.delete.secret.notFound(
            name: _escapeControls(secretName),
            teamId: _escapeControls(profile.teamId),
          ),
          _ => t.delete.secret.requestFailed(status: response.statusCode),
        });
        return 1;
      }
      _logger.stdout(
        t.delete.secret.deleted(
          name: _escapeControls(secretName),
          teamId: _escapeControls(profile.teamId),
        ),
      );
      return 0;
    } catch (_) {
      _logger.stderr(t.delete.secret.deleteFailed);
      return 1;
    } finally {
      client.dispose();
    }
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
    _logger.stderr(t.delete.secret.loginRequired);
    return null;
  }
}

String _escapeControls(String text) => text.replaceAllMapped(
  RegExp(r'[\x00-\x1f\x7f-\x9f]'),
  (match) => '\\x${match[0]!.codeUnitAt(0).toRadixString(16).padLeft(2, '0')}',
);
