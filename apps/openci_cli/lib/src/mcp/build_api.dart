import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/firebase_project_id.dart';
import '../credential_store/credential_config.dart';

/// A message safe to return to an MCP client.
class BuildReadException implements Exception {
  const BuildReadException(this.message);
  final String message;
}

class BuildQueryUnavailable extends BuildReadException {
  BuildQueryUnavailable(String operation)
    : super('The OpenCI connector does not yet provide $operation.');
}

class BuildApi {
  BuildApi(this.profile, this.client) : project = firebaseProjectId(profile);

  final AuthProfile profile;
  final http.Client client;
  final String project;

  String? dashboardUrl(String jobId) {
    if (project != 'openci-b1b91' || profile.firebaseAuthEmulatorHost != null) {
      return null;
    }
    return Uri(
      scheme: 'https',
      host: 'dashboard.openci.org',
      pathSegments: ['runs', jobId],
    ).toString();
  }

  Future<Map<String, dynamic>> query(
    String connector,
    String operation,
    Map<String, Object?> variables,
  ) async {
    final service = project.startsWith('demo-')
        ? 'openci-b1b91-service'
        : '$project-service';
    final name =
        'projects/$project/locations/asia-northeast1/services/$service/connectors/$connector';
    final path = '/v1/$name:executeQuery';
    final uri = profile.firebaseAuthEmulatorHost == null
        ? Uri.https('firebasedataconnect.googleapis.com', path)
        : Uri.http('127.0.0.1:9399', path);
    final request = http.Request('POST', uri)
      ..followRedirects = false
      ..headers.addAll({
        'Content-Type': 'application/json',
        'X-Firebase-Auth-Token': profile.token,
      })
      ..body = jsonEncode({'operationName': operation, 'variables': variables});
    final response = await client
        .send(request)
        .then(http.Response.fromStream)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode == 401) {
      throw const BuildReadException('Sign in again with openci login.');
    }
    if (response.statusCode == 403) {
      throw const BuildReadException(
        'Access denied for the active OpenCI team.',
      );
    }
    if (response.statusCode == 404) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body case {
        'error': {'status': 'NOT_FOUND', 'message': final String message},
      } when message == 'operation "$operation" not found') {
        throw BuildQueryUnavailable(operation);
      }
    }
    if (response.statusCode != 200) {
      throw BuildReadException(
        'OpenCI could not run $operation (HTTP ${response.statusCode}).',
      );
    }
    final result = jsonDecode(utf8.decode(response.bodyBytes)) as Map;
    if (result['errors'] case final List errors when errors.isNotEmpty) {
      // GraphQL can return partial data alongside an authorization error.
      // Only relay known messages; raw backend errors may contain request data.
      for (final error in errors.whereType<Map>()) {
        final message = error['message'];
        if (message is String && message.contains('Team access denied')) {
          throw const BuildReadException(
            'Access denied for the active OpenCI team.',
          );
        }
        if (message is String && message.contains('Run not found')) {
          throw const BuildReadException(
            'Run not found for this job and team.',
          );
        }
      }
      throw BuildReadException('OpenCI could not complete $operation.');
    }
    return result['data'] as Map<String, dynamic>;
  }
}
