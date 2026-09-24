import 'package:args/command_runner.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../auth/firebase_auth_client.dart';
import '../credential_store/credential_store.dart';
import '../i18n/i18n.dart';
import 'login/login_with_firebase.dart';
import 'login/read_login_credentials.dart';

class LoginCommand extends Command<int> {
  @override
  final String name = 'login';

  @override
  String get description => t.login.description;

  final Logger _logger;
  final CredentialStore _credentialStore;
  final http.Client? _client;
  final Duration _timeout;
  final Future<LoginCredentials?> Function() _readCredentials;

  LoginCommand({
    Logger? logger,
    CredentialStore? credentialStore,
    @visibleForTesting http.Client? client,
    @visibleForTesting Duration timeout = const Duration(seconds: 10),
    @visibleForTesting
    Future<LoginCredentials?> Function() readCredentials = readLoginCredentials,
  }) : _logger = logger ?? Logger.standard(),
       _credentialStore = credentialStore ?? CredentialStore(),
       _client = client,
       _timeout = timeout,
       _readCredentials = readCredentials {
    argParser.addFlag(
      'local',
      abbr: 'l',
      negatable: false,
      help: t.login.flags.local,
    );
    argParser
      ..addOption(
        'server',
        defaultsTo: 'https://openci-worker-01.tail4beb18.ts.net',
        help: t.login.flags.server,
      )
      ..addOption('team-id', help: t.login.flags.teamId)
      ..addOption(
        'firebase-api-key',
        defaultsTo: defaultFirebaseApiKey,
        help: t.login.flags.firebaseApiKey,
      );
  }

  @override
  Future<int> run() async {
    if (argResults!.rest.isNotEmpty) usageException(t.login.noArguments);
    final String serverUrl;
    final String apiKey;
    final String? teamId;
    final String? emulatorHost;
    if (argResults!.flag('local')) {
      if ([
        'server',
        'team-id',
        'firebase-api-key',
      ].any(argResults!.wasParsed)) {
        usageException(t.login.localOptionsConflict);
      }
      serverUrl = 'http://localhost:8080';
      apiKey = 'demo-openci-api-key';
      teamId = 'test-team';
      emulatorHost = '127.0.0.1:9099';
    } else {
      final server = Uri.tryParse(argResults!.option('server')!.trim());
      if (server == null ||
          server.scheme != 'https' ||
          server.host.isEmpty ||
          server.userInfo.isNotEmpty ||
          server.hasQuery ||
          server.hasFragment) {
        usageException(t.login.serverRequired);
      }
      serverUrl = server.toString().replaceFirst(RegExp(r'/+$'), '');
      apiKey = argResults!.option('firebase-api-key')!.trim();
      teamId = argResults!.option('team-id')?.trim();
      emulatorHost = null;
      if (apiKey.isEmpty || teamId == '') {
        usageException(t.login.emptyOptions);
      }
    }
    final client = _client ?? http.Client();
    try {
      return await loginWithFirebase(
        serverUrl: serverUrl,
        firebaseApiKey: apiKey,
        teamId: teamId,
        emulatorHost: emulatorHost,
        store: _credentialStore,
        logger: _logger,
        readCredentials: _readCredentials,
        client: client,
        timeout: _timeout,
      );
    } finally {
      client.close();
    }
  }
}
