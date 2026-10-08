import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';

import '../../asc/asc_api_key_secret.dart';
import '../../credential_store/credential_store.dart';
import '../../i18n/i18n.dart';
import '../register/secret_registration.dart';
import 'ensure_ios_certificate_key.dart';

class SetupIosCertificateKeyCommand extends Command<int> {
  SetupIosCertificateKeyCommand({
    required Logger logger,
    CredentialStore? credentialStore,
  }) : _logger = logger,
       _registration = SecretRegistration(
         logger: logger,
         credentialStore: credentialStore,
       );

  @override
  final String name = 'ios-certificate-key';

  @override
  String get description => t.setup.iosCertificateKey.description;

  final Logger _logger;
  final SecretRegistration _registration;

  @override
  Future<int> run() async {
    if (argResults!.rest.isNotEmpty) {
      usageException(t.setup.iosCertificateKey.noArguments);
    }
    final profile = await _registration.readProfile();
    if (profile == null) return 1;

    _logger.stdout(
      t.setup.iosCertificateKey.saveDestination(
        server: _escapeControls(profile.serverUrl),
        team: _escapeControls(profile.teamId),
        name: iosCertificatePrivateKeySecretName,
      ),
    );
    return ensureIosCertificateKey(profile: profile, logger: _logger);
  }
}

String _escapeControls(String text) => text.replaceAllMapped(
  RegExp(r'[\x00-\x1f\x7f-\x9f]'),
  (match) => '\\x${match[0]!.codeUnitAt(0).toRadixString(16).padLeft(2, '0')}',
);
