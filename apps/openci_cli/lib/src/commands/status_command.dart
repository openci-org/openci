import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';

import '../credential_store/credential_config.dart';
import '../credential_store/credential_store.dart';
import '../i18n/i18n.dart';

class StatusCommand extends Command<int> {
  @override
  final String name = 'status';

  @override
  String get description => t.status.description;

  final Logger _logger;
  final CredentialStore _credentialStore;

  StatusCommand({required Logger logger, CredentialStore? credentialStore})
    : _logger = logger,
      _credentialStore = credentialStore ?? CredentialStore();

  @override
  Future<int> run() async {
    if (argResults!.rest.isNotEmpty) {
      usageException(t.status.noArguments);
    }

    final CredentialConfig config;
    try {
      config = await _credentialStore.get();
    } catch (_) {
      // Parsing and file errors can contain credentials; omit their details.
      _logger.stderr(t.status.readFailed);
      return 1;
    }

    if (config.profiles.isEmpty) {
      _logger.stdout(t.status.noActiveProfile);
      return 0;
    }

    final profile = config.profiles[config.activeProfile];
    if (profile == null) {
      _logger.stderr(
        t.status.profileMissing(profile: _displayValue(config.activeProfile)),
      );
      return 1;
    }

    _logger.stdout(
      t.status.profile(value: _displayValue(config.activeProfile)),
    );
    _logger.stdout(t.status.server(value: _displayServer(profile.serverUrl)));
    _logger.stdout(t.status.team(value: _displayValue(profile.teamId)));
    return 0;
  }
}

String _displayValue(String value) => value.trim().isEmpty
    ? t.status.notSet
    : value.replaceAllMapped(
        RegExp(r'[\x00-\x1f\x7f-\x9f]'),
        (match) =>
            '\\x${match[0]!.codeUnitAt(0).toRadixString(16).padLeft(2, '0')}',
      );

String _displayServer(String value) {
  if (value.trim().isEmpty) return t.status.notSet;
  final server = Uri.tryParse(value);
  if (server == null ||
      (server.scheme != 'http' && server.scheme != 'https') ||
      server.host.isEmpty ||
      server.userInfo.isNotEmpty ||
      server.hasQuery ||
      server.hasFragment) {
    return t.status.invalidServer;
  }
  return _displayValue(value);
}
