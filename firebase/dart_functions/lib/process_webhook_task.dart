import 'dart:convert';

import 'package:shelf/shelf.dart';

typedef ProcessTask = Future<String> Function(String taskId);

/// The private endpoint accepts only an ID and loads all inputs from FSC.
Future<Response> processWebhookTask(
  Request request,
  ProcessTask process,
) async {
  if (request.method != 'POST') {
    return Response(405, headers: {'allow': 'POST'});
  }
  String? taskId;
  try {
    final bytes = <int>[];
    await for (final chunk in request.read()) {
      if (bytes.length + chunk.length > 4096) {
        return _json(413, {'error': 'request_too_large'});
      }
      bytes.addAll(chunk);
    }
    final Object? value = jsonDecode(utf8.decode(bytes));
    if (value is! Map<String, dynamic> ||
        value.length != 1 ||
        value['taskId'] is! String ||
        !RegExp(r'^[\x21-\x7e]{1,255}$').hasMatch(value['taskId'] as String)) {
      return _json(400, {'error': 'invalid_request'});
    }
    taskId = value['taskId'] as String;
  } on FormatException {
    return _json(400, {'error': 'invalid_request'});
  }
  try {
    return _json(200, {'result': await process(taskId)});
  } catch (_) {
    // Never print SDK/HTTP exceptions; they may carry credentials or payloads.
    print(
      jsonEncode({
        'severity': 'ERROR',
        'message': 'Build job planning failed',
        'taskId': taskId,
      }),
    );
    return _json(503, {'error': 'planning_unavailable'});
  }
}

Response _json(int status, Map<String, Object?> value) => Response(
  status,
  body: jsonEncode(value),
  headers: {'content-type': 'application/json'},
);
