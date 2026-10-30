import 'dart:convert';

import 'package:http/http.dart' as http;

import '../credential_store/credential_config.dart';

class SecretResponse {
  const SecretResponse(this.statusCode, this.body);
  final int statusCode;
  final Map<String, dynamic>? body;
  bool get isSuccessful => statusCode >= 200 && statusCode < 300;
}

class SecretsApi {
  SecretsApi(this.profile, {http.Client? client})
    : _client = client ?? http.Client();
  final AuthProfile profile;
  final http.Client _client;

  Uri get endpoint => secretFunctionEndpoint(profile);

  Future<SecretResponse> _call(
    String action,
    String teamId, [
    Map<String, dynamic> data = const {},
  ]) async {
    final request = http.Request('POST', endpoint)
      ..followRedirects = false
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${profile.token}',
      })
      ..body = jsonEncode({
        'data': {'action': action, 'teamId': teamId, ...data},
      });
    final response = await _client
        .send(request)
        .then(http.Response.fromStream)
        .timeout(const Duration(seconds: 65));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return SecretResponse(response.statusCode, null);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid Functions response');
    }
    final result = decoded['result'] ?? decoded['data'];
    return SecretResponse(
      response.statusCode,
      result is Map<String, dynamic> ? result : null,
    );
  }

  Future<SecretResponse> getSecrets(String teamId) => _call('list', teamId);
  Future<SecretResponse> saveSecret(
    String teamId,
    Map<String, dynamic> value,
  ) => _call('save', teamId, value);
  Future<SecretResponse> deleteSecret(String teamId, String name) =>
      _call('delete', teamId, {'name': name});
  Future<SecretResponse> generateCertificateKey(String teamId) =>
      _call('generateCertificateKey', teamId);
  void dispose() => _client.close();
}

Uri secretFunctionEndpoint(AuthProfile profile) {
  var project = profile.firebaseProjectId;
  if (project.isEmpty) {
    final parts = profile.token.split('.');
    if (parts.length != 3) {
      throw const FormatException('Firebase login is required');
    }
    final claims = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    project = (claims as Map<String, dynamic>)['aud'] as String;
  }
  if (!RegExp(r'^[a-z][a-z0-9-]{4,62}$').hasMatch(project) ||
      !RegExp(r'^[a-z]+-[a-z]+[0-9]+$').hasMatch(profile.functionsRegion)) {
    throw const FormatException('Invalid Firebase Functions configuration');
  }
  final authEmulator = profile.firebaseAuthEmulatorHost;
  final emulator =
      profile.functionsEmulatorHost ??
      (authEmulator == null
          ? null
          : Uri.parse('http://$authEmulator').replace(port: 5001).authority);
  if (emulator != null) {
    final host = Uri.parse('http://$emulator');
    if (!{'localhost', '127.0.0.1', '::1'}.contains(host.host) ||
        host.userInfo.isNotEmpty ||
        host.path.isNotEmpty ||
        host.hasQuery ||
        host.hasFragment) {
      throw const FormatException(
        'Functions emulator must use a loopback address',
      );
    }
    return host.replace(
      path: '/$project/${profile.functionsRegion}/teamSecrets',
    );
  }
  return Uri.https(
    '${profile.functionsRegion}-$project.cloudfunctions.net',
    '/teamSecrets',
  );
}
