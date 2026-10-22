import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/billing/billing_proxy.dart';

Future<Response> billingRoute(
  RequestContext context,
  String teamId,
  BillingOperation operation,
) async {
  final proxy = context.read<BillingProxy?>();
  if (proxy == null) return _error(HttpStatus.notFound, 'not_found');
  final method = switch (operation) {
    BillingOperation.status => HttpMethod.get,
    BillingOperation.deleteTeam => HttpMethod.delete,
    _ => HttpMethod.post,
  };
  if (context.request.method != method) {
    return _error(HttpStatus.methodNotAllowed, 'method_not_allowed');
  }
  final uid = context.read<String?>();
  if (uid == null || uid.isEmpty) {
    return _error(HttpStatus.unauthorized, 'authentication_required');
  }
  String? planId;
  if (operation != BillingOperation.status) {
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
      final body = bytes.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(utf8.decode(bytes));
      if (body is! Map<String, dynamic>) throw const FormatException();
      if (operation == BillingOperation.checkout) {
        if (body.length != 1 || !{'light', 'pro'}.contains(body['planId'])) {
          throw const FormatException();
        }
        planId = body['planId'] as String;
      } else if (body.isNotEmpty) {
        throw const FormatException();
      }
    } on TimeoutException {
      return _error(HttpStatus.requestTimeout, 'invalid_request');
    } catch (_) {
      return _error(HttpStatus.badRequest, 'invalid_request');
    }
  }
  return proxy.request(
    operation: operation,
    teamId: teamId,
    uid: uid,
    planId: planId,
  );
}

Response _error(int status, String code) => Response.json(
  statusCode: status,
  body: {'error': code},
  headers: const {'cache-control': 'no-store'},
);
