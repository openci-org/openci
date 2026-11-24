import 'dart:convert';

import 'package:http/http.dart' as http;

import '../credential_store/credential_config.dart';

class DataConnectHttpException implements Exception {
  const DataConnectHttpException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'DataConnectHttpException(HTTP $statusCode)';
}

class DataConnectGraphQLException implements Exception {
  const DataConnectGraphQLException(this.messages);

  final List<String> messages;

  @override
  String toString() => messages.isEmpty
      ? 'DataConnectGraphQLException'
      : 'DataConnectGraphQLException(${messages.join('; ')})';
}

class DataConnectApi {
  DataConnectApi(
    this.profile, {
    http.Client? client,
    this.emulatorHost,
    this.timeout = const Duration(seconds: 30),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  final AuthProfile profile;
  final http.Client _client;
  final bool _ownsClient;
  final String? emulatorHost;
  final Duration timeout;

  Uri queryEndpoint(String connector) =>
      dataConnectQueryEndpoint(profile, connector, emulatorHost: emulatorHost);

  Future<Map<String, dynamic>> executeQuery({
    required String connector,
    required String operationName,
    Map<String, Object?> variables = const {},
  }) async {
    final connectorName = dataConnectConnectorName(profile, connector);
    final endpoint = queryEndpoint(connector);
    final request = http.Request('POST', endpoint)
      ..followRedirects = false
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Firebase-Auth-Token': profile.token,
      })
      ..body = jsonEncode({
        'name': connectorName,
        'operationName': operationName,
        if (variables.isNotEmpty) 'variables': variables,
      });

    final response = await _client
        .send(request)
        .then(http.Response.fromStream)
        .timeout(timeout);

    if (response.statusCode != 200) {
      throw DataConnectHttpException(response.statusCode);
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid Data Connect response');
    }

    final errors = decoded['errors'];
    if (errors is List && errors.isNotEmpty) {
      final messages = <String>[];
      for (final error in errors) {
        if (error is Map && error['message'] is String) {
          final message = (error['message'] as String).trim();
          if (message.isNotEmpty) messages.add(message);
        }
      }
      throw DataConnectGraphQLException(
        messages.isEmpty ? const ['Data Connect query failed'] : messages,
      );
    }

    final data = decoded['data'];
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Missing Data Connect response data');
    }
    return data;
  }

  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }
}

String firebaseProjectIdFromProfile(AuthProfile profile) {
  var project = profile.firebaseProjectId;
  if (project.isEmpty) {
    final parts = profile.token.split('.');
    if (parts.length != 3) {
      throw const FormatException('Firebase login is required');
    }
    final claims = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    if (claims is! Map<String, dynamic> || claims['aud'] is! String) {
      throw const FormatException('Firebase login is required');
    }
    project = claims['aud'] as String;
  }
  if (!RegExp(r'^[a-z][a-z0-9-]{4,62}$').hasMatch(project)) {
    throw const FormatException('Invalid Firebase project ID');
  }
  return project;
}

String dataConnectServiceId(String projectId) => projectId.startsWith('demo-')
    ? 'openci-b1b91-service'
    : '$projectId-service';

String dataConnectConnectorName(AuthProfile profile, String connector) {
  final project = firebaseProjectIdFromProfile(profile);
  final location = profile.functionsRegion;
  if (!RegExp(r'^[a-z]+-[a-z]+[0-9]+$').hasMatch(location) ||
      !RegExp(r'^[a-z][a-z0-9_-]*$').hasMatch(connector)) {
    throw const FormatException('Invalid Data Connect configuration');
  }
  final serviceId = dataConnectServiceId(project);
  return 'projects/$project/locations/$location/services/$serviceId/connectors/$connector';
}

Uri dataConnectQueryEndpoint(
  AuthProfile profile,
  String connector, {
  String? emulatorHost,
}) {
  final connectorName = dataConnectConnectorName(profile, connector);
  final authEmulator = profile.firebaseAuthEmulatorHost;
  final emulator =
      emulatorHost ??
      (authEmulator == null
          ? null
          : Uri.parse('http://$authEmulator').replace(port: 9399).authority);
  if (emulator != null) {
    final host = Uri.parse('http://$emulator');
    if (!{'localhost', '127.0.0.1', '::1'}.contains(host.host) ||
        host.userInfo.isNotEmpty ||
        host.path.isNotEmpty ||
        host.hasQuery ||
        host.hasFragment) {
      throw const FormatException(
        'Data Connect emulator must use a loopback address',
      );
    }
    return host.replace(path: '/v1/$connectorName:executeQuery');
  }
  return Uri.https(
    'firebasedataconnect.googleapis.com',
    '/v1/$connectorName:executeQuery',
  );
}
