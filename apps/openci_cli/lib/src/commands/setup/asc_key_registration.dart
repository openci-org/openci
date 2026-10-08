import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:openci_shared/openci_shared.dart';

import '../../asc/asc_api_key.dart';
import '../../asc/asc_api_key_secret.dart';
import '../../credential_store/credential_config.dart';
import '../../credential_store/credential_store.dart';
import '../../i18n/i18n.dart';
import '../../secrets/fetch_secret_names.dart';
import '../register/secret_registration.dart';

class AscKeySaveTarget {
  const AscKeySaveTarget({required this.profileName, required this.profile});

  final String profileName;
  final AuthProfile profile;
}

class AscKeyRegistration {
  AscKeyRegistration({required Logger logger, CredentialStore? credentialStore})
    : _logger = logger,
      _store = credentialStore ?? CredentialStore();

  final Logger _logger;
  final CredentialStore _store;
  late final _registration = SecretRegistration(
    logger: _logger,
    credentialStore: _store,
  );

  /// Checks server access before issuing a key and shows the save destination.
  Future<AscKeySaveTarget?> prepare() async {
    final profile = await _registration.readProfile();
    if (profile == null) return null;
    final AscKeySaveTarget target;
    try {
      final config = await _store.get();
      if (config.profiles[config.activeProfile] != profile) {
        _logger.stderr(t.setup.ascKeys.saveProfileChanged);
        return null;
      }
      target = AscKeySaveTarget(
        profileName: config.activeProfile,
        profile: profile,
      );
    } catch (_) {
      _logger.stderr(t.register.secret.loginRequired);
      return null;
    }

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
      _logger.stdout(
        t.setup.ascKeys.saveDestination(
          server: _escapeControls(profile.serverUrl),
          team: _escapeControls(profile.teamId),
          names: [
            ...ascApiKeySecretNames,
            iosCertificatePrivateKeySecretName,
          ].join('\n    '),
        ),
      );
      for (final name in ascApiKeySecretNames) {
        if (names.contains(name)) {
          _logger.stdout(t.setup.ascKeys.secretWillReplace(name: name));
        }
      }
      _logger.stdout(
        names.contains(iosCertificatePrivateKeySecretName)
            ? t.setup.ascKeys.certificateKeyWillReuse
            : t.setup.ascKeys.certificateKeyWillCreate,
      );
      return target;
    } on SecretNamesHttpException catch (error) {
      _logger.stderr(
        error.statusCode == HttpStatus.unauthorized ||
                error.statusCode == HttpStatus.forbidden
            ? t.register.secret.loginRequired
            : t.setup.ascKeys.savePreflightFailed,
      );
    } catch (_) {
      _logger.stderr(t.setup.ascKeys.savePreflightFailed);
    } finally {
      client.dispose();
    }
    return null;
  }

  Future<int> save(AscKeySaveTarget target, AscApiKey key) async {
    final Map<String, String> secrets;
    try {
      secrets = await encodeAscApiKeySecrets(key);
    } catch (_) {
      _logger.stderr(t.setup.ascKeys.savedKeyInvalid);
      return 1;
    }

    // Apple login may take a while. Refresh credentials without silently
    // following a concurrent profile/account/team change to a new destination.
    try {
      final before = await _store.get();
      if (before.activeProfile != target.profileName ||
          before.profiles[target.profileName] != target.profile) {
        _logger.stderr(t.setup.ascKeys.saveProfileChanged);
        return 1;
      }
      final profile = await _registration.readProfile();
      if (profile == null) return 1;
      final current = await _store.get();
      if (current.activeProfile != target.profileName ||
          current.profiles[target.profileName] != profile ||
          profile.serverUrl != target.profile.serverUrl ||
          profile.teamId != target.profile.teamId) {
        _logger.stderr(t.setup.ascKeys.saveProfileChanged);
        return 1;
      }
      for (final secret in secrets.entries) {
        final code = await _registration.save(
          profile,
          secret.key,
          secret.value,
        );
        if (code != 0) return code;
      }
      return await _ensureCertificateKey(profile);
    } catch (_) {
      _logger.stderr(t.register.secret.saveFailed);
      return 1;
    }
  }

  Future<int> _ensureCertificateKey(AuthProfile profile) async {
    final client = createOpenCIChopperClient(
      baseUrl: profile.serverUrl,
      tokenProvider: () => profile.token,
      services: [OpenCIApiService.create()],
    );
    try {
      final api = client.getService<OpenCIApiService>();
      // Recheck after Apple login and credential storage: another setup may
      // have prepared the key since preflight. Never overwrite it via saveSecret.
      final names = await fetchSecretNames(api, profile.teamId);
      if (names.contains(iosCertificatePrivateKeySecretName)) {
        _logger.stdout(t.setup.ascKeys.certificateKeyReused);
        return 0;
      }

      final response = await api.generateCertificateKey(
        Uri.encodeComponent(profile.teamId),
      );
      if (!response.isSuccessful) {
        throw SecretNamesHttpException(response.statusCode);
      }
      final savedNames = await fetchSecretNames(api, profile.teamId);
      if (!savedNames.contains(iosCertificatePrivateKeySecretName)) {
        _logger.stderr(t.setup.ascKeys.certificateKeySetupFailed);
        return 1;
      }
      _logger.stdout(t.setup.ascKeys.certificateKeyReady);
      return 0;
    } on SecretNamesHttpException catch (error) {
      _logger.stderr(
        error.statusCode == HttpStatus.unauthorized ||
                error.statusCode == HttpStatus.forbidden
            ? t.register.secret.loginRequired
            : t.setup.ascKeys.certificateKeyRequestFailed(
                status: error.statusCode,
              ),
      );
      return 1;
    } catch (_) {
      // Responses and transport errors can contain credentials or key material.
      _logger.stderr(t.setup.ascKeys.certificateKeySetupFailed);
      return 1;
    } finally {
      client.dispose();
    }
  }
}

String _escapeControls(String text) => text.replaceAllMapped(
  RegExp(r'[\x00-\x1f\x7f-\x9f]'),
  (match) => '\\x${match[0]!.codeUnitAt(0).toRadixString(16).padLeft(2, '0')}',
);
