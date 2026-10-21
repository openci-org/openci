import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/billing/billing_proxy.dart';

Future<Response> workerBillingRoute(
  RequestContext context,
  WorkerBillingOperation operation,
) async {
  final proxy = context.read<BillingProxy?>();
  if (proxy == null) return _error(HttpStatus.notFound, 'not_found');
  if (context.request.method != HttpMethod.post) {
    return _error(HttpStatus.methodNotAllowed, 'method_not_allowed');
  }
  try {
    final bytes = <int>[];
    await for (final chunk in context.request.bytes().timeout(
      const Duration(seconds: 5),
    )) {
      if (bytes.length + chunk.length > 4096) {
        return _error(HttpStatus.requestEntityTooLarge, 'invalid_request');
      }
      bytes.addAll(chunk);
    }
    final body = jsonDecode(utf8.decode(bytes));
    if (body is! Map<String, dynamic>) throw const FormatException();
    const identityKeys = {'admissionId', 'jobId', 'runId', 'workerHost'};
    for (final key in identityKeys) {
      final value = body[key];
      if (value is! String || value.trim().isEmpty || value.length > 255) {
        throw const FormatException();
      }
    }
    final allowedKeys = {
      ...identityKeys,
      if (operation == WorkerBillingOperation.report) 'outcome',
    };
    if (body.keys.any((key) => !allowedKeys.contains(key))) {
      throw const FormatException();
    }
    if (body.containsKey('outcome') &&
        !{
          '',
          'success',
          'failure',
          'cancelled',
          'timed_out',
        }.contains(body['outcome'])) {
      throw const FormatException();
    }
    return proxy.workerRequest(operation: operation, payload: body);
  } on TimeoutException {
    return _error(HttpStatus.requestTimeout, 'invalid_request');
  } catch (_) {
    return _error(HttpStatus.badRequest, 'invalid_request');
  }
}

Response _error(int status, String code) => Response.json(
  statusCode: status,
  body: {'error': code},
  headers: const {'cache-control': 'no-store'},
);
