import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:openci_shared/openci_shared.dart';

import '../credential_store/credential_config.dart';
import '../credential_store/credential_store.dart';
import '../credential_store/read_authenticated_profile.dart';
import '../i18n/i18n.dart';
import 'switch/fetch_teams.dart';

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
    final savedProfile = config.profiles[config.activeProfile];
    if (savedProfile == null) {
      _logger.stderr(
        t.status.profileMissing(profile: _displayValue(config.activeProfile)),
      );
      return 1;
    }

    // Keep the saved context visible even if fetching the team name fails.
    _logger.stdout(
      t.status.profile(value: _displayValue(config.activeProfile)),
    );
    _logger.stdout(
      t.status.server(value: _displayServer(savedProfile.serverUrl)),
    );
    _logger.stdout(t.status.team(value: _displayValue(savedProfile.teamId)));
    if (savedProfile.teamId.trim().isEmpty) {
      _logger.stderr(t.status.noTeamSelected);
      return 1;
    }
    final profile = await _readProfile(config.activeProfile, savedProfile);
    if (profile == null) return 1;

    final client = createOpenCIChopperClient(
      baseUrl: profile.serverUrl,
      tokenProvider: () => profile.token,
      services: [OpenCIApiService.create()],
    );
    try {
      final teams = await fetchTeams(client.getService<OpenCIApiService>());
      final team = teams.where((team) => team.id == profile.teamId).firstOrNull;
      if (team == null) {
        _logger.stderr(
          teams.isEmpty ? t.status.noTeams : t.status.teamNotFound,
        );
        return 1;
      }

      _logger.stdout(t.status.teamName(value: _displayValue(team.name)));
      return 0;
    } on TeamsHttpException catch (error) {
      _logger.stderr(
        error.statusCode == HttpStatus.unauthorized ||
                error.statusCode == HttpStatus.forbidden
            ? t.status.loginRequired
            : t.status.requestFailed(status: error.statusCode),
      );
    } catch (error) {
      _logger.stderr(
        error is FormatException || error is TypeError
            ? t.status.invalidResponse
            : t.status.fetchFailed,
      );
    } finally {
      client.dispose();
    }
    return 1;
  }

  Future<AuthProfile?> _readProfile(
    String profileName,
    AuthProfile savedProfile,
  ) async {
    try {
      final profile = await readAuthenticatedProfile(_credentialStore);
      final current = await _credentialStore.get();
      if (current.activeProfile != profileName ||
          current.profiles[profileName] != profile ||
          (profile != null &&
              (profile.teamId != savedProfile.teamId ||
                  profile.serverUrl != savedProfile.serverUrl))) {
        _logger.stderr(t.status.profileChanged);
        return null;
      }
      if (profile != null &&
          profile.authType == 'firebase' &&
          profile.token.trim().isNotEmpty &&
          _isValidServer(profile.serverUrl)) {
        return profile;
      }
    } catch (_) {
      // Credential errors can contain tokens; do not print them.
    }
    _logger.stderr(t.status.loginRequired);
    return null;
  }
}

String _displayValue(String value) => value.trim().isEmpty
    ? t.status.notSet
    : value.replaceAllMapped(
        RegExp(r'[\x00-\x1f\x7f-\x9f]'),
        (match) =>
            '\\x${match[0]!.codeUnitAt(0).toRadixString(16).padLeft(2, '0')}',
      );

bool _isValidServer(String value) {
  final server = Uri.tryParse(value);
  return server != null &&
      (server.scheme == 'http' || server.scheme == 'https') &&
      server.host.isNotEmpty &&
      server.userInfo.isEmpty &&
      !server.hasQuery &&
      !server.hasFragment;
}

String _displayServer(String value) {
  if (value.trim().isEmpty) return t.status.notSet;
  return _isValidServer(value) ? _displayValue(value) : t.status.invalidServer;
}
