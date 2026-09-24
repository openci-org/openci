import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:openci_server/auth/internal_api_key_validator.dart';
import 'package:openci_server/auth/user_email_info.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import '../routes/_middleware.dart';

const _projectId = 'demo-openci';
const _emulatorHost = '127.0.0.1:9099';
const _apiKey = 'fake-api-key';
final _emulatorBase = Uri.parse('http://$_emulatorHost');

void main() {
  test(
    'Auth Emulator tokens pass through the server auth middleware',
    () async {
      _requireIsolatedEmulatorEnvironment();
      final health = await http.get(
        _emulatorBase.resolve('/emulator/v1/projects/$_projectId/config'),
      );
      expect(
        health.statusCode,
        HttpStatus.ok,
        reason: 'Auth Emulator is not ready',
      );

      final app = FirebaseApp.initializeApp(
        options: const AppOptions(projectId: _projectId),
        name: 'auth-emulator-integration',
      );
      final server = await _serveProtectedHandler(app);
      String? ownUserToken;

      try {
        final email = 'auth-2873-${const Uuid().v4()}@example.test';
        final password = 'local-test-password-${const Uuid().v4()}';
        final created = await _postAuth('signUp', {
          'email': email,
          'password': password,
          'returnSecureToken': true,
        });
        ownUserToken = created['idToken'] as String;
        final uid = created['localId'] as String;
        final apiUri = _protectedUri(server);

        await _expectIdentity(
          apiUri,
          ownUserToken,
          uid,
          email,
          verified: false,
        );

        final signedIn = await _postAuth('signInWithPassword', {
          'email': email,
          'password': password,
          'returnSecureToken': true,
        });
        expect(signedIn['localId'], uid);
        await _expectIdentity(
          apiUri,
          signedIn['idToken'] as String,
          uid,
          email,
          verified: false,
        );

        final refreshToken = signedIn['refreshToken'] as String;
        final refreshed = await _refreshIdToken(refreshToken);
        expect(refreshed['user_id'], uid);
        await _expectIdentity(
          apiUri,
          refreshed['id_token'] as String,
          uid,
          email,
          verified: false,
        );

        await _postAuth('sendOobCode', {
          'requestType': 'VERIFY_EMAIL',
          'idToken': signedIn['idToken'],
        });
        final codesResponse = await http.get(
          _emulatorBase.resolve('/emulator/v1/projects/$_projectId/oobCodes'),
        );
        expect(codesResponse.statusCode, HttpStatus.ok);
        final codes =
            (jsonDecode(codesResponse.body) as Map<String, dynamic>)['oobCodes']
                as List<dynamic>;
        final ownCode = codes.cast<Map<String, dynamic>>().singleWhere(
          (code) =>
              code['email'] == email && code['requestType'] == 'VERIFY_EMAIL',
        );
        await _postAuth('update', {'oobCode': ownCode['oobCode']});

        final afterVerification = await _refreshIdToken(refreshToken);
        expect(afterVerification['user_id'], uid);
        await _expectIdentity(
          apiUri,
          afterVerification['id_token'] as String,
          uid,
          email,
          verified: true,
        );

        await _expectRejected(apiUri, 'malformed-token');
        await _expectRejected(
          apiUri,
          _withWrongProject(afterVerification['id_token'] as String),
        );
        await _expectRejected(apiUri, null);

        final probeHome = await Directory.systemTemp.createTemp(
          'openci-auth-probe-',
        );
        try {
          final environment = Map<String, String>.of(Platform.environment)
            ..remove('FIREBASE_AUTH_EMULATOR_HOST')
            ..remove('GOOGLE_APPLICATION_CREDENTIALS')
            ..remove('GOOGLE_CLOUD_PROJECT')
            ..remove('FIREBASE_CONFIG')
            ..addAll({
              'GCLOUD_PROJECT': _projectId,
              'HOME': probeHome.path,
              'CLOUDSDK_CONFIG': probeHome.path,
              'XDG_CONFIG_HOME': probeHome.path,
            });
          final probe = await Process.run(
            Platform.resolvedExecutable,
            [
              'run',
              'integration_test/auth_production_probe.dart',
              ownUserToken,
            ],
            workingDirectory: Directory.current.path,
            environment: environment,
            includeParentEnvironment: false,
          );
          expect(probe.exitCode, 0, reason: '${probe.stdout}\n${probe.stderr}');
        } finally {
          await probeHome.delete(recursive: true);
        }
      } finally {
        try {
          if (ownUserToken != null) {
            await _postAuth('delete', {'idToken': ownUserToken});
          }
        } finally {
          await server.close(force: true);
          await FirebaseApp.deleteApp(app);
        }
      }
    },
  );
}

void _requireIsolatedEmulatorEnvironment() {
  if (Platform.environment['FIREBASE_AUTH_EMULATOR_HOST'] != _emulatorHost ||
      Platform.environment['GCLOUD_PROJECT'] != _projectId) {
    throw StateError(
      'Run with FIREBASE_AUTH_EMULATOR_HOST=$_emulatorHost and '
      'GCLOUD_PROJECT=$_projectId.',
    );
  }
  for (final key in [
    'GOOGLE_APPLICATION_CREDENTIALS',
    'GOOGLE_CLOUD_PROJECT',
    'FIREBASE_CONFIG',
  ]) {
    if (Platform.environment.containsKey(key)) {
      throw StateError('Unset $key before running this integration test.');
    }
  }
}

Future<HttpServer> _serveProtectedHandler(FirebaseApp app) {
  final handler =
      authProvider(app)((context) {
        final uid = context.read<String?>();
        if (uid == null) return Response(statusCode: HttpStatus.unauthorized);

        final info = context.read<UserEmailInfo?>();
        return Response.json(
          body: {
            'uid': uid,
            'email': info?.email,
            'emailVerified': info?.emailVerified,
          },
        );
      }).use(
        provider<InternalApiKeyValidator>(
          (_) => const InternalApiKeyValidator.forTesting(environment: {}),
        ),
      );
  return serve(handler, InternetAddress.loopbackIPv4, 0);
}

Uri _protectedUri(HttpServer server) =>
    Uri.parse('http://127.0.0.1:${server.port}/protected');

Future<void> _expectIdentity(
  Uri uri,
  String token,
  String uid,
  String email, {
  required bool verified,
}) async {
  final response = await http.get(
    uri.replace(queryParameters: {'email': 'spoof@example.test'}),
    headers: {
      'Authorization': 'Bearer $token',
      'email': 'spoof@example.test',
    },
  );
  expect(response.statusCode, HttpStatus.ok, reason: response.body);
  expect(jsonDecode(response.body), {
    'uid': uid,
    'email': email,
    'emailVerified': verified,
  });
}

Future<void> _expectRejected(Uri uri, String? token) async {
  final response = await http.get(
    uri,
    headers: {if (token != null) 'Authorization': 'Bearer $token'},
  );
  expect(response.statusCode, HttpStatus.unauthorized);
}

Future<Map<String, dynamic>> _postAuth(
  String action,
  Map<String, Object?> body,
) async {
  final response = await http.post(
    _emulatorBase.resolve(
      '/identitytoolkit.googleapis.com/v1/accounts:$action?key=$_apiKey',
    ),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );
  expect(response.statusCode, HttpStatus.ok, reason: response.body);
  return jsonDecode(response.body) as Map<String, dynamic>;
}

Future<Map<String, dynamic>> _refreshIdToken(String refreshToken) async {
  final response = await http.post(
    _emulatorBase.resolve('/securetoken.googleapis.com/v1/token?key=$_apiKey'),
    body: {'grant_type': 'refresh_token', 'refresh_token': refreshToken},
  );
  expect(response.statusCode, HttpStatus.ok, reason: response.body);
  return jsonDecode(response.body) as Map<String, dynamic>;
}

String _withWrongProject(String token) {
  final parts = token.split('.');
  expect(parts, hasLength(3));
  final claims =
      jsonDecode(
            utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
          )
          as Map<String, dynamic>;
  final payload = base64Url
      .encode(utf8.encode(jsonEncode({...claims, 'aud': 'another-project'})))
      .replaceAll('=', '');
  return '${parts[0]}.$payload.${parts[2]}';
}
