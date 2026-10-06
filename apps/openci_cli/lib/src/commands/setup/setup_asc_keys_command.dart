import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:openci_shared/openci_shared.dart';

import '../../asc/asc_cli.dart';
import '../../asc/asc_release.dart';
import '../../credential_store/credential_config.dart';
import '../../credential_store/credential_store.dart';
import '../../credential_store/read_authenticated_profile.dart';
import '../../i18n/i18n.dart';
import '../../secrets/fetch_secret_names.dart';
import '../switch/fetch_teams.dart';

// Reserved for the JSON bundle containing the ASC key ID, issuer ID and P8.
const _ascApiKeySecretName = 'OPENCI_ASC_API_KEY';

class SetupAscKeysCommand extends Command<int> {
  @override
  final String name = 'asc-keys';

  @override
  String get description => t.setup.ascKeys.description;

  final Logger _logger;
  final CredentialStore _credentialStore;
  final Future<File> Function() _prepareAsc;

  SetupAscKeysCommand({
    required Logger logger,
    CredentialStore? credentialStore,
    Future<File> Function()? prepareAsc,
  }) : _logger = logger,
       _credentialStore = credentialStore ?? CredentialStore(),
       _prepareAsc = prepareAsc ?? AscCli().ensureAvailable;

  @override
  Future<int> run() async {
    if (argResults!.rest.isNotEmpty) {
      usageException(t.setup.ascKeys.noArguments);
    }
    final profile = await _readProfile();
    if (profile == null) return 1;
    if (profile.teamId.trim().isEmpty) {
      _logger.stderr(t.setup.ascKeys.noTeamSelected);
      return 1;
    }

    final client = createOpenCIChopperClient(
      baseUrl: profile.serverUrl,
      tokenProvider: () => profile.token,
      services: [OpenCIApiService.create()],
    );
    try {
      final api = client.getService<OpenCIApiService>();
      final teams = await fetchTeams(api);
      final team = teams.where((team) => team.id == profile.teamId).firstOrNull;
      if (team == null) {
        _logger.stderr(t.setup.ascKeys.teamNotFound);
        return 1;
      }
      final names = await fetchSecretNames(api, profile.teamId);

      _logger.stdout(
        t.setup.ascKeys.server(value: _display(profile.serverUrl)),
      );
      _logger.stdout(
        t.setup.ascKeys.team(name: _display(team.name), id: _display(team.id)),
      );
      if (names.contains(_ascApiKeySecretName)) {
        _logger.stdout(t.setup.ascKeys.registered);
        return 0;
      }

      _logger.stdout(t.setup.ascKeys.notRegistered);
    } on TeamsHttpException catch (error) {
      _reportHttpError(error.statusCode);
      return 1;
    } on SecretNamesHttpException catch (error) {
      _reportHttpError(error.statusCode);
      return 1;
    } catch (error) {
      // Responses and exceptions may contain credentials or secret values.
      _logger.stderr(
        error is FormatException || error is TypeError
            ? t.setup.ascKeys.invalidResponse
            : t.setup.ascKeys.checkFailed,
      );
      return 1;
    } finally {
      client.dispose();
    }
    return _prepareCli();
  }

  Future<int> _prepareCli() async {
    _logger.stdout(t.setup.ascKeys.preparingAsc(version: AscRelease.version));
    try {
      final executable = await _prepareAsc();
      _logger.stdout(
        t.setup.ascKeys.ascReady(
          version: AscRelease.version,
          path: _display(executable.path),
        ),
      );
      _logger.stderr(t.setup.ascKeys.creationUnavailable);
    } on AscCliException catch (error) {
      _logger.stderr(switch (error.failure) {
        AscCliFailure.unsupportedPlatform => t.setup.ascKeys.ascUnsupported,
        AscCliFailure.cache => t.setup.ascKeys.ascCacheFailed,
        AscCliFailure.download => t.setup.ascKeys.ascDownloadFailed,
        AscCliFailure.checksum => t.setup.ascKeys.ascChecksumFailed,
        AscCliFailure.permission => t.setup.ascKeys.ascPermissionFailed,
      });
    } catch (_) {
      _logger.stderr(t.setup.ascKeys.ascPreparationFailed);
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
    _logger.stderr(t.setup.ascKeys.loginRequired);
    return null;
  }

  void _reportHttpError(int status) {
    _logger.stderr(
      status == HttpStatus.unauthorized || status == HttpStatus.forbidden
          ? t.setup.ascKeys.loginRequired
          : t.setup.ascKeys.requestFailed(status: status),
    );
  }
}

String _display(String value) => value.replaceAllMapped(
  RegExp(r'[\x00-\x1f\x7f-\x9f]'),
  (match) => '\\x${match[0]!.codeUnitAt(0).toRadixString(16).padLeft(2, '0')}',
);
