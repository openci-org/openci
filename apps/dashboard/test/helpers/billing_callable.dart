import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class TestBillingCallable extends Fake implements HttpsCallable {
  TestBillingCallable(this.respond);
  final Future<http.Response> Function(http.Request) respond;
  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async {
    final request = http.Request(
      'POST',
      Uri.parse('https://functions.test/teamBilling'),
    )..body = jsonEncode({'data': parameters});
    final response = await respond(request);
    if (response.statusCode != 200) {
      throw FirebaseFunctionsException(
        message: 'Test failure',
        code: switch (response.statusCode) {
          401 => 'unauthenticated',
          403 => 'permission-denied',
          404 => 'failed-precondition',
          _ => 'unavailable',
        },
        details: response.statusCode == 404
            ? {'reason': 'billing_disabled'}
            : null,
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

Map<String, dynamic> billingCallData(http.Request request) =>
    Map<String, dynamic>.from(jsonDecode(request.body)['data'] as Map);
