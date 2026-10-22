import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:openci_server/billing/billing_proxy_config.dart';

enum BillingOperation { status, checkout, portal, deleteTeam }

class BillingProxy {
  BillingProxy(this.config, this.client);

  final BillingProxyConfig config;
  final http.Client client;

  Future<Response> request({
    required BillingOperation operation,
    required String teamId,
    required String uid,
    String? planId,
  }) async {
    final abort = Completer<void>();
    final timer = Timer(const Duration(seconds: 60), abort.complete);
    try {
      final uri = config.serverUri.replace(
        pathSegments: [
          'internal',
          'billing',
          'teams',
          teamId,
          if (operation == BillingOperation.checkout ||
              operation == BillingOperation.portal)
            operation.name,
        ],
      );
      final request =
          http.AbortableRequest(
              switch (operation) {
                BillingOperation.status => 'GET',
                BillingOperation.deleteTeam => 'DELETE',
                _ => 'POST',
              },
              uri,
              abortTrigger: abort.future,
            )
            ..followRedirects = false
            ..headers.addAll({
              'authorization': 'Bearer ${config.internalToken}',
              'x-genuineci-user-id': uid,
              'content-type': 'application/json',
            });
      if (operation == BillingOperation.checkout) {
        request.body = jsonEncode({'planId': planId});
      }
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

  Response _upstreamError(int status, Object? code) {
    const allowed = {
      'invalid_plan': HttpStatus.badRequest,
      'invalid_request': HttpStatus.badRequest,
      'forbidden': HttpStatus.forbidden,
      'customer_missing': HttpStatus.conflict,
      'subscription_exists': HttpStatus.conflict,
      'checkout_conflict': HttpStatus.conflict,
      'payment_pending': HttpStatus.conflict,
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
