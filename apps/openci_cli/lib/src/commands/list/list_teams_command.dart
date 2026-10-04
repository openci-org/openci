import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:openci_shared/openci_shared.dart';

import '../../credential_store/credential_config.dart';
import '../../credential_store/credential_store.dart';
import '../../credential_store/read_authenticated_profile.dart';
import '../../i18n/i18n.dart';
import '../switch/fetch_teams.dart';

class ListTeamsCommand extends Command<int> {
  @override
  final String name = 'teams';

  @override
  String get description => t.list.teams.description;

  final Logger _logger;
  final CredentialStore _credentialStore;

  ListTeamsCommand({required Logger logger, CredentialStore? credentialStore})
    : _logger = logger,
      _credentialStore = credentialStore ?? CredentialStore();

  @override
  Future<int> run() async {
    if (argResults!.rest.isNotEmpty) {
      usageException(t.list.teams.noArguments);
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
        _logger.stdout(t.list.teams.empty);
      } else {
        for (final team in teams) {
          // Team names and IDs must not execute terminal control sequences.
          final label = '${team.name} (${team.id})'.replaceAllMapped(
            RegExp(r'[\x00-\x1f\x7f-\x9f]'),
            (match) =>
                '\\x${match[0]!.codeUnitAt(0).toRadixString(16).padLeft(2, '0')}',
          );
          final marker = team.id == profile.teamId ? '*' : ' ';
          _logger.stdout('$marker $label');
        }
      }
      return 0;
    } on TeamsHttpException catch (error) {
      _logger.stderr(
        error.statusCode == HttpStatus.unauthorized ||
                error.statusCode == HttpStatus.forbidden
            ? t.list.teams.loginRequired
            : t.list.teams.requestFailed(status: error.statusCode),
      );
    } catch (error) {
      _logger.stderr(
        error is FormatException || error is TypeError
            ? t.list.teams.invalidResponse
            : t.list.teams.fetchFailed,
      );
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
      // Credential errors can contain tokens; do not print their details.
    }
    _logger.stderr(t.list.teams.loginRequired);
    return null;
  }
}
