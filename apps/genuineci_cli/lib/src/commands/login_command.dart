import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../credential_store/credential_config.dart';
import '../credential_store/credential_store.dart';
import '../i18n/i18n.dart';

class LoginCommand extends Command<int> {
  @override
  final String name = 'login';

  @override
  String get description => t.login.description;

  final Logger _logger;
  final CredentialStore _credentialStore;
  final Future<ProcessResult> Function(String, List<String>) _processRunner;
  final http.Client? _client;
  final Duration _timeout;

  LoginCommand({
    Logger? logger,
    CredentialStore? credentialStore,
    @visibleForTesting
    Future<ProcessResult> Function(String, List<String>)? processRunner,
    @visibleForTesting http.Client? client,
    @visibleForTesting Duration timeout = const Duration(seconds: 10),
  }) : _logger = logger ?? Logger.standard(),
       _credentialStore = credentialStore ?? CredentialStore(),
       _processRunner = processRunner ?? Process.run,
       _client = client,
       _timeout = timeout {
    argParser.addFlag(
      'local',
      abbr: 'l',
      negatable: false,
      help: t.login.flags.local,
    );
  }

  @override
  Future<int> run() async {
    if (!argResults!.flag('local')) usageException(t.login.localOnly);
    if (argResults!.rest.isNotEmpty) usageException(t.login.noArguments);

    const serverUrl = 'http://localhost:8080';
    const teamId = 'test-team';
    const profileName = 'local';

    _logger.stdout(t.login.loggingIn);
    final String token;
    try {
      // Read only the running local server's key; never print Docker output.
      final result = await _processRunner('docker', [
        'exec',
        'genuineci-server',
        'printenv',
        'INTERNAL_API_KEY',
      ]).timeout(_timeout);
      token = (result.stdout as String).trim();
      if (result.exitCode != 0 ||
          token.isEmpty ||
          token.contains(RegExp(r'[\r\n]'))) {
        _logger.stderr(t.login.localServerUnavailable);
        return 1;
      }
    } on Exception {
      _logger.stderr(t.login.localServerUnavailable);
      return 1;
    }

    final client = _client ?? http.Client();
    try {
      final request = http.Request('GET', Uri.parse('$serverUrl/teams'))
        ..followRedirects = false
        ..headers['Authorization'] = 'Bearer $token';
      final response = await client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(_timeout);
      if (response.statusCode == HttpStatus.unauthorized ||
          response.statusCode == HttpStatus.forbidden) {
        _logger.stderr(t.login.authenticationFailed);
        return 1;
      }
      if (response.statusCode != HttpStatus.ok) {
        _logger.stderr(t.login.requestFailed(status: response.statusCode));
        return 1;
      }
      final teams = jsonDecode(response.body);
      if (teams is! List ||
          teams.any((team) => team is! Map || team['id'] is! String)) {
        throw const FormatException('Invalid teams response');
      }
      if (!teams.any((team) => team['id'] == teamId)) {
        _logger.stderr(t.login.seedRequired);
        return 1;
      }
    } on FormatException {
      _logger.stderr(t.login.invalidResponse);
      return 1;
    } on Exception {
      _logger.stderr(t.login.connectionFailed);
      return 1;
    } finally {
      client.close();
    }

    try {
      await _credentialStore.saveProfile(
        profileName,
        AuthProfile(serverUrl: serverUrl, token: token, teamId: teamId),
      );
    } catch (_) {
      _logger.stderr(t.login.saveFailed);
      return 1;
    }
    _logger.stdout(t.login.savedSuccess(profile: profileName));
    return 0;
  }
}
