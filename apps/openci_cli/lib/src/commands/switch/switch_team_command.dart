import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:openci_shared/openci_shared.dart';

import '../../credential_store/credential_config.dart';
import '../../credential_store/credential_store.dart';
import '../../credential_store/read_authenticated_profile.dart';
import '../../i18n/i18n.dart';
import 'fetch_teams.dart';
import 'select_team.dart';

class SwitchTeamCommand extends Command<int> {
  @override
  final String name = 'team';

  @override
  String get description => t.switchCommand.team.description;

  final Logger _logger;
  final CredentialStore _credentialStore;
  final TeamSelector _teamSelector;

  SwitchTeamCommand({
    required Logger logger,
    CredentialStore? credentialStore,
    TeamSelector teamSelector = selectTeam,
  }) : _logger = logger,
       _credentialStore = credentialStore ?? CredentialStore(),
       _teamSelector = teamSelector;

  @override
  Future<int> run() async {
    if (argResults!.rest.isNotEmpty) {
      usageException(t.switchCommand.team.noArguments);
    }

    final authenticated = await _readProfile();
    if (authenticated == null) return 1;
    final profile = authenticated.profile;

    final client = createOpenCIChopperClient(
      baseUrl: profile.serverUrl,
      tokenProvider: () => profile.token,
      services: [OpenCIApiService.create()],
    );
    final List<Team> teams;
    try {
      teams = await fetchTeams(client.getService<OpenCIApiService>());
    } on TeamsHttpException catch (error) {
      _logger.stderr(
        error.statusCode == HttpStatus.unauthorized ||
                error.statusCode == HttpStatus.forbidden
            ? t.switchCommand.team.loginRequired
            : t.switchCommand.team.requestFailed(status: error.statusCode),
      );
      return 1;
    } catch (_) {
      _logger.stderr(t.switchCommand.team.fetchFailed);
      return 1;
    } finally {
      client.dispose();
    }
    if (teams.isEmpty) {
      _logger.stderr(t.switchCommand.team.empty);
      return 1;
    }

    final Team? selected;
    try {
      selected = await _teamSelector(
        teams: teams,
        currentTeamId: profile.teamId,
      );
    } catch (_) {
      _logger.stderr(t.switchCommand.team.inputFailed);
      return 1;
    }
    if (selected == null) {
      _logger.stderr(t.switchCommand.team.cancelled);
      return 1;
    }
    return _saveTeam(authenticated, selected);
  }

  Future<int> _saveTeam(
    ({String name, AuthProfile profile}) authenticated,
    Team selected,
  ) async {
    final label = '${selected.name} (${selected.id})'.replaceAllMapped(
      RegExp(r'[\x00-\x1f\x7f-\x9f]'),
      (match) =>
          '\\x${match[0]!.codeUnitAt(0).toRadixString(16).padLeft(2, '0')}',
    );
    try {
      final current = await _credentialStore.get();
      if (current.activeProfile != authenticated.name ||
          current.profiles[authenticated.name] != authenticated.profile) {
        _logger.stderr(t.switchCommand.team.profileChanged);
        return 1;
      }
      if (selected.id == authenticated.profile.teamId) {
        _logger.stdout(t.switchCommand.team.alreadyCurrent(team: label));
        return 0;
      }
      await _credentialStore.set(
        current.copyWith(
          profiles: {
            ...current.profiles,
            authenticated.name: authenticated.profile.copyWith(
              teamId: selected.id,
            ),
          },
        ),
      );
    } catch (_) {
      // File errors can contain credentials; do not print their details.
      _logger.stderr(t.switchCommand.team.saveFailed);
      return 1;
    }
    _logger.stdout(t.switchCommand.team.success(team: label));
    return 0;
  }

  Future<({String name, AuthProfile profile})?> _readProfile() async {
    try {
      final profile = await readAuthenticatedProfile(_credentialStore);
      final server = Uri.tryParse(profile?.serverUrl ?? '');
      if (profile != null &&
          profile.authType == 'firebase' &&
          profile.token.trim().isNotEmpty &&
          server != null &&
          (server.scheme == 'http' || server.scheme == 'https') &&
          server.host.isNotEmpty &&
          server.userInfo.isEmpty &&
          !server.hasQuery &&
          !server.hasFragment) {
        final current = await _credentialStore.get();
        if (current.profiles[current.activeProfile] != profile) {
          _logger.stderr(t.switchCommand.team.profileChanged);
          return null;
        }
        return (name: current.activeProfile, profile: profile);
      }
    } catch (_) {
      // Credential errors can contain tokens; do not print them.
    }
    _logger.stderr(t.switchCommand.team.loginRequired);
    return null;
  }
}
