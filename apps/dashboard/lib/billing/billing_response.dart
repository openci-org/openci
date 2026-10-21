import 'dart:convert';

import 'package:chopper/chopper.dart';

class BillingException implements Exception {
  const BillingException(this.code);

  final String code;

  @override
  String toString() => code;
}

Map<String, dynamic> billingResponseBody(
  Response<Map<String, dynamic>> response,
) {
  if (response.isSuccessful && response.body != null) return response.body!;
  switch (response.statusCode) {
    case 401:
      throw const BillingException('authentication_required');
    case 403:
      throw const BillingException('forbidden');
    case 404:
      throw const BillingException('billing_disabled');
  }
  try {
    final error = response.error;
    final body = error is String ? jsonDecode(error) : error;
    if (body is Map &&
        const {
          'invalid_plan',
          'customer_missing',
          'subscription_exists',
          'checkout_conflict',
          'payment_pending',
          'billing_timeout',
        }.contains(body['error'])) {
      throw BillingException(body['error'] as String);
    }
  } on BillingException {
    rethrow;
  } catch (_) {}
  throw const BillingException('billing_unavailable');
}
