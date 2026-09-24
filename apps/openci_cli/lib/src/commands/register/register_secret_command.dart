import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:meta/meta.dart';

import '../../credential_store/credential_store.dart';
import '../../i18n/i18n.dart';
import 'read_secret_input.dart';
import 'secret_registration.dart';

class RegisterSecretCommand extends Command<int> {
  @override
  final String name = 'secret';

  @override
  String get description => t.register.secret.description;

  final Logger _logger;
  final SecretRegistration _registration;
  final Future<SecretInput?> Function() _readInput;

  RegisterSecretCommand({
    required Logger logger,
    CredentialStore? credentialStore,
    @visibleForTesting
    Future<SecretInput?> Function() readInput = readSecretInput,
  }) : _logger = logger,
       _registration = SecretRegistration(
         logger: logger,
         credentialStore: credentialStore,
       ),
       _readInput = readInput;

  @override
  Future<int> run() async {
    if (argResults!.rest.isNotEmpty) {
      usageException(t.register.secret.noArguments);
    }

    final profile = await _registration.readProfile();
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
    return _registration.save(profile, secret.name, secret.value);
  }
}
