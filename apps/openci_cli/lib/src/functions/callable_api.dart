import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/firebase_project_id.dart';
import '../credential_store/credential_config.dart';

class FunctionResponse {
  const FunctionResponse(this.statusCode, this.body);
  final int statusCode;
  final Map<String, dynamic>? body;
  bool get isSuccessful => statusCode >= 200 && statusCode < 300;
}

class CallableApi {
  CallableApi(
    this.profile,
    this.functionName, {
    http.Client? client,
    this.timeout = const Duration(seconds: 65),
  }) : _client = client ?? http.Client();
  final AuthProfile profile;
  final String functionName;
  final http.Client _client;
  final Duration timeout;

  Uri get endpoint => firebaseFunctionEndpoint(profile, functionName);

  Future<FunctionResponse> call(Map<String, dynamic> data) async {
    final request = http.Request('POST', endpoint)
      ..followRedirects = false
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${profile.token}',
      })
      ..body = jsonEncode({'data': data});
    final response = await _client
        .send(request)
        .then(http.Response.fromStream)
        .timeout(timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return FunctionResponse(response.statusCode, null);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid Functions response');
    }
    final result = decoded['result'] ?? decoded['data'];
    return FunctionResponse(
      response.statusCode,
      result is Map<String, dynamic> ? result : null,
    );
  }

  void dispose() => _client.close();
}

Uri firebaseFunctionEndpoint(AuthProfile profile, String functionName) {
  final project = firebaseProjectId(profile);
  if (!RegExp(r'^[a-z]+-[a-z]+[0-9]+$').hasMatch(profile.functionsRegion)) {
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
      path: '/$project/${profile.functionsRegion}/$functionName',
    );
  }
  return Uri.https(
    '${profile.functionsRegion}-$project.cloudfunctions.net',
    '/$functionName',
  );
}
