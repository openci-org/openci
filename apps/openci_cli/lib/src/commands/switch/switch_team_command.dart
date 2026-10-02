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

    final profile = await _readProfile();
    if (profile == null) return 1;

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
    _logger.stderr(t.switchCommand.team.unavailable);
    return 1;
  }

  Future<AuthProfile?> _readProfile() async {
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
        return profile;
      }
    } catch (_) {
      // Credential errors can contain tokens; do not print them.
    }
    _logger.stderr(t.switchCommand.team.loginRequired);
    return null;
  }
}
