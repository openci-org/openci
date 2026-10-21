import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:openci_server/billing/billing_proxy_config.dart';

enum BillingOperation { status, checkout, portal, deleteTeam }

enum WorkerBillingOperation { claim, start, report }

class BillingProxy {
  BillingProxy(this.config, this.client);

  final BillingProxyConfig config;
  final http.Client client;

  Future<Response> request({
    required BillingOperation operation,
    required String teamId,
    required String uid,
    String? planId,
  }) => _send(
    path: [
      'internal',
      'billing',
      'teams',
      teamId,
      if (operation == BillingOperation.checkout ||
          operation == BillingOperation.portal)
        operation.name,
    ],
    method: switch (operation) {
      BillingOperation.status => 'GET',
      BillingOperation.deleteTeam => 'DELETE',
      _ => 'POST',
    },
    uid: uid,
    payload: operation == BillingOperation.checkout ? {'planId': planId} : null,
    decode: (body) => _decodeMemberResponse(operation, body),
  );

  Future<Response> workerRequest({
    required WorkerBillingOperation operation,
    required Map<String, Object?> payload,
  }) => _send(
    path: ['internal', 'billing', 'worker', operation.name],
    method: 'POST',
    payload: payload,
    decode: (body) {
      if (operation == WorkerBillingOperation.claim) {
        if (!body.containsKey('claim')) throw const FormatException();
        final claim = body['claim'];
        if (claim == null) return _json(HttpStatus.ok, {'claim': null});
        if (claim is! Map<String, dynamic>) throw const FormatException();
        for (final key in ['jobId', 'admissionId']) {
          final value = claim[key];
          if (value is! String || value.trim().isEmpty || value.length > 255) {
            throw const FormatException();
          }
        }
        return _json(HttpStatus.ok, {
          'claim': {
            'jobId': claim['jobId'],
            'admissionId': claim['admissionId'],
          },
        });
      }
      if (body['active'] is! bool || body['measurementIncomplete'] is! bool) {
        throw const FormatException();
      }
      return _json(HttpStatus.ok, {
        'active': body['active'],
        'measurementIncomplete': body['measurementIncomplete'],
      });
    },
  );

  Future<Response> _send({
    required List<String> path,
    required String method,
    required Response Function(Map<String, dynamic>) decode,
    String? uid,
    Map<String, Object?>? payload,
  }) async {
    final abort = Completer<void>();
    final timer = Timer(const Duration(seconds: 60), abort.complete);
    try {
      final request =
          http.AbortableRequest(
              method,
              config.serverUri.replace(pathSegments: path),
              abortTrigger: abort.future,
            )
            ..followRedirects = false
            ..headers.addAll({
              'authorization': 'Bearer ${config.internalToken}',
              'x-genuineci-user-id': ?uid,
              'content-type': 'application/json',
            });
      if (payload != null) request.body = jsonEncode(payload);
      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 60));
      final bytes = <int>[];
      await for (final chunk in response.stream.timeout(
        const Duration(seconds: 5),
      )) {
        if (bytes.length + chunk.length > 65536) throw const FormatException();
        bytes.addAll(chunk);
      }
      final body = jsonDecode(utf8.decode(bytes));
      if (body is! Map<String, dynamic>) throw const FormatException();
      if (response.statusCode != HttpStatus.ok) {
        return _upstreamError(response.statusCode, body['error']);
      }
      return decode(body);
    } on TimeoutException {
      return _json(HttpStatus.gatewayTimeout, {'error': 'billing_timeout'});
    } on http.RequestAbortedException {
      return _json(HttpStatus.gatewayTimeout, {'error': 'billing_timeout'});
    } catch (_) {
      return _json(HttpStatus.serviceUnavailable, {
        'error': 'billing_unavailable',
      });
    } finally {
      timer.cancel();
      if (!abort.isCompleted) abort.complete();
    }
  }

  Response _decodeMemberResponse(
    BillingOperation operation,
    Map<String, dynamic> body,
  ) {
    if (operation == BillingOperation.deleteTeam) {
      if (body['success'] != true) throw const FormatException();
      return _json(HttpStatus.ok, {'success': true});
    }
    if (operation == BillingOperation.status) {
      for (final key in [
        'billingEnabled',
        'canStartCi',
        'canCheckout',
        'canManageBilling',
        'cancelAtPeriodEnd',
      ]) {
        if (body[key] is! bool) throw const FormatException();
      }
      if (body['blockReason'] is! String ||
          (body['planId'] != null && body['planId'] is! String) ||
          (body['paidUntil'] != null && body['paidUntil'] is! String)) {
        throw const FormatException();
      }
      return _json(HttpStatus.ok, {
        for (final key in [
          'billingEnabled',
          'planId',
          'canStartCi',
          'blockReason',
          'paidUntil',
          'canCheckout',
          'canManageBilling',
          'cancelAtPeriodEnd',
        ])
          key: body[key],
      });
    }
    final url = body['url'];
    final destination = url is String ? Uri.tryParse(url) : null;
    if (destination == null ||
        destination.scheme != 'https' ||
        destination.host.isEmpty ||
        destination.userInfo.isNotEmpty) {
      throw const FormatException();
    }
    return _json(HttpStatus.ok, {'url': url});
  }

  Response _upstreamError(int status, Object? code) {
    const allowed = {
      'invalid_plan': HttpStatus.badRequest,
      'invalid_request': HttpStatus.badRequest,
      'forbidden': HttpStatus.forbidden,
      'customer_missing': HttpStatus.conflict,
      'subscription_exists': HttpStatus.conflict,
      'checkout_conflict': HttpStatus.conflict,
      'payment_pending': HttpStatus.conflict,
      'admission_not_current': HttpStatus.conflict,
      'billing_timeout': HttpStatus.gatewayTimeout,
    };
    if (allowed[code] == status) return _json(status, {'error': code});
    return _json(HttpStatus.serviceUnavailable, {
      'error': 'billing_unavailable',
    });
  }

  Response _json(int status, Map<String, Object?> body) => Response.json(
    statusCode: status,
    body: body,
    headers: const {'cache-control': 'no-store'},
  );
}
