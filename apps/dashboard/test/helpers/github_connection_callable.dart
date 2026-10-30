import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

// Reuse HTTP response fixtures for the Firebase SDK boundary. Requests use the
// callable wire shape, and production code never constructs this HTTP request.
class TestGitHubCallable extends Fake implements HttpsCallable {
  TestGitHubCallable(this.respond);
  final Future<http.Response> Function(http.Request) respond;

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async {
    final request = http.Request(
      'POST',
      Uri.parse('https://functions.test/githubConnection'),
    )..body = jsonEncode({'data': parameters});
    final response = await respond(request);
    if (response.statusCode != 200) {
      throw FirebaseFunctionsException(
        code: switch (response.statusCode) {
          401 => 'unauthenticated',
          403 => 'permission-denied',
          409 => 'failed-precondition',
          _ => 'unavailable',
        },
        message: 'Fixture failure',
      );
    }
    return _Result<T>(jsonDecode(response.body) as T);
  }
}

class _Result<T> extends Fake implements HttpsCallableResult<T> {
  _Result(this.data);
  @override
  final T data;
}

Map<String, dynamic> callableData(http.Request request) =>
    Map<String, dynamic>.from(jsonDecode(request.body)['data'] as Map);
