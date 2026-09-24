import 'dart:convert';

import 'package:http/http.dart' as http;

// Public Web API key for the dashboard's default Firebase project.
const defaultFirebaseApiKey = 'AIzaSyCvYYkNYRMsTzlei8rWRO0WTkT_YRq9LIs';

class FirebaseAuthClient {
  FirebaseAuthClient(
    this._client, {
    this.timeout = const Duration(seconds: 10),
    String? emulatorHost,
  }) : _emulatorUri = _parseEmulatorHost(emulatorHost);

  final http.Client _client;
  final Duration timeout;
  final Uri? _emulatorUri;

  Future<FirebaseSession> signIn({
    required String apiKey,
    required String email,
    required String password,
  }) {
    final request =
        http.Request(
            'POST',
            _endpoint(
              'identitytoolkit.googleapis.com',
              '/v1/accounts:signInWithPassword',
              apiKey,
            ),
          )
          ..headers['Content-Type'] = 'application/json; charset=utf-8'
          ..body = jsonEncode({
            'email': email,
            'password': password,
            'returnSecureToken': true,
          });
    return _send(request, isRefresh: false);
  }

  Future<FirebaseSession> refresh({
    required String apiKey,
    required String refreshToken,
  }) {
    final request =
        http.Request(
            'POST',
            _endpoint('securetoken.googleapis.com', '/v1/token', apiKey),
          )
          ..bodyFields = {
            'grant_type': 'refresh_token',
            'refresh_token': refreshToken,
          };
    return _send(request, isRefresh: true);
  }

  Uri _endpoint(String host, String path, String apiKey) =>
      _emulatorUri?.replace(
        path: '/$host$path',
        queryParameters: {'key': apiKey},
      ) ??
      Uri.https(host, path, {'key': apiKey});

  static Uri? _parseEmulatorHost(String? host) {
    if (host == null) return null;
    final uri = Uri.tryParse('//$host');
    if (!RegExp(
          r'^(?:[a-zA-Z0-9.-]+|\[[0-9a-fA-F:.]+\]):[0-9]+$',
        ).hasMatch(host) ||
        uri == null ||
        !uri.hasPort ||
        uri.port < 1 ||
        uri.port > 65535) {
      throw const FormatException(
        'Auth Emulator address must be host:port, for example 127.0.0.1:9099.',
      );
    }
    return uri.replace(scheme: 'http');
  }

  Future<FirebaseSession> _send(
    http.Request request, {
    required bool isRefresh,
  }) async {
    request.followRedirects = false;
    try {
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
      if (response.statusCode != 200) throw const FirebaseAuthException();
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) throw const FirebaseAuthException();
      final token = body[isRefresh ? 'id_token' : 'idToken'];
      final refreshToken = body[isRefresh ? 'refresh_token' : 'refreshToken'];
      final expiresIn = body[isRefresh ? 'expires_in' : 'expiresIn'];
      final seconds = expiresIn is String ? int.tryParse(expiresIn) : null;
      if (token is! String ||
          token.trim().isEmpty ||
          refreshToken is! String ||
          refreshToken.trim().isEmpty ||
          seconds == null ||
          seconds <= 0) {
        throw const FirebaseAuthException();
      }
      return FirebaseSession(
        token: token,
        refreshToken: refreshToken,
        expiresAt: DateTime.now().toUtc().add(Duration(seconds: seconds)),
      );
    } catch (_) {
      // HTTP errors and invalid responses can contain passwords or tokens.
      throw const FirebaseAuthException();
    }
  }
}

class FirebaseSession {
  const FirebaseSession({
    required this.token,
    required this.refreshToken,
    required this.expiresAt,
  });

  final String token;
  final String refreshToken;
  final DateTime expiresAt;
}

class FirebaseAuthException implements Exception {
  const FirebaseAuthException();

  @override
  String toString() => 'Firebase authentication failed. Please log in again.';
}
