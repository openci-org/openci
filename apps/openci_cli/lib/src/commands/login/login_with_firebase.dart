import 'dart:convert';

import 'package:cli_util/cli_logging.dart';
import 'package:http/http.dart' as http;

import '../../auth/firebase_auth_client.dart';
import '../../credential_store/credential_config.dart';
import '../../credential_store/credential_store.dart';
import '../../i18n/i18n.dart';
import 'read_login_credentials.dart';

Future<int> loginWithFirebase({
  required String serverUrl,
  required String firebaseApiKey,
  required String? teamId,
  required CredentialStore store,
  required Logger logger,
  required Future<LoginCredentials?> Function() readCredentials,
  required http.Client client,
  required Duration timeout,
  String? emulatorHost,
}) async {
  final isLocal = emulatorHost != null;
  final profileName = isLocal ? 'local' : 'remote';
  try {
    final credentials = await readCredentials();
    if (credentials == null) {
      logger.stderr(t.login.inputRequired);
      return 1;
    }
    logger.stdout(t.login.loggingIn);
    final session =
        await FirebaseAuthClient(
          client,
          timeout: timeout,
          emulatorHost: emulatorHost,
        ).signIn(
          apiKey: firebaseApiKey,
          email: credentials.email,
          password: credentials.password,
        );

    final request = http.Request('GET', Uri.parse('$serverUrl/teams'))
      ..followRedirects = false
      ..headers['Authorization'] = 'Bearer ${session.token}';
    final response = await client
        .send(request)
        .then(http.Response.fromStream)
        .timeout(timeout);
    if (response.statusCode != 200) {
      logger.stderr(
        isLocal && (response.statusCode == 401 || response.statusCode == 403)
            ? t.login.authenticationFailed
            : t.login.requestFailed(status: response.statusCode),
      );
      return 1;
    }
    final teams = jsonDecode(utf8.decode(response.bodyBytes));
    if (teams is! List ||
        teams.any(
          (team) =>
              team is! Map ||
              team['id'] is! String ||
              (team['id'] as String).trim().isEmpty,
        )) {
      throw const FormatException('Invalid teams response');
    }
    if (teams.isEmpty) {
      logger.stderr(isLocal ? t.login.localTeamRequired : t.login.noTeams);
      return 1;
    }
    if (teamId == null && teams.length > 1) {
      for (final team in teams) {
        logger.stdout('${team['id']}: ${team['name'] ?? ''}');
      }
      logger.stderr(t.login.teamRequired);
      return 1;
    }
    final selectedTeamId = teamId ?? teams.single['id'] as String;
    if (!teams.any((team) => team['id'] == selectedTeamId)) {
      logger.stderr(isLocal ? t.login.localTeamRequired : t.login.teamNotFound);
      return 1;
    }
    try {
      await store.saveProfile(
        profileName,
        AuthProfile(
          serverUrl: serverUrl,
          token: session.token,
          teamId: selectedTeamId,
          authType: 'firebase',
          refreshToken: session.refreshToken,
          firebaseApiKey: firebaseApiKey,
          firebaseAuthEmulatorHost: emulatorHost,
          expiresAt: session.expiresAt,
        ),
      );
    } catch (_) {
      logger.stderr(t.login.saveFailed);
      return 1;
    }
    logger.stdout(t.login.savedSuccess(profile: profileName));
    return 0;
  } on FirebaseAuthException {
    logger.stderr(
      isLocal
          ? t.login.emulatorAuthenticationFailed
          : t.login.firebaseAuthenticationFailed,
    );
    return 1;
  } on FormatException {
    logger.stderr(t.login.invalidResponse);
    return 1;
  } catch (_) {
    logger.stderr(
      isLocal ? t.login.connectionFailed : t.login.remoteConnectionFailed,
    );
    return 1;
  }
}
