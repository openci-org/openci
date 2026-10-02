import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:openci_shared/openci_shared.dart';

import '../../credential_store/credential_config.dart';
import '../../credential_store/credential_store.dart';
import '../../credential_store/read_authenticated_profile.dart';
import '../../i18n/i18n.dart';
import 'fetch_teams.dart';

class SwitchTeamCommand extends Command<int> {
  @override
  final String name = 'team';

  @override
  String get description => t.switchCommand.team.description;

  final Logger _logger;
  final CredentialStore _credentialStore;

  SwitchTeamCommand({required Logger logger, CredentialStore? credentialStore})
    : _logger = logger,
      _credentialStore = credentialStore ?? CredentialStore();

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
    try {
      final teams = await fetchTeams(client.getService<OpenCIApiService>());
      if (teams.isEmpty) {
        _logger.stderr(t.switchCommand.team.empty);
        return 1;
      }

      _logger.stderr(t.switchCommand.team.unavailable);
    } on TeamsHttpException catch (error) {
      _logger.stderr(
        error.statusCode == HttpStatus.unauthorized ||
                error.statusCode == HttpStatus.forbidden
            ? t.switchCommand.team.loginRequired
            : t.switchCommand.team.requestFailed(status: error.statusCode),
      );
    } catch (_) {
      _logger.stderr(t.switchCommand.team.fetchFailed);
    } finally {
      client.dispose();
    }
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
