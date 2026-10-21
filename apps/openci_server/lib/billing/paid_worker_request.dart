import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/auth/internal_api_key_validator.dart';
import 'package:openci_server/billing/billing_admission_store.dart';
import 'package:openci_shared/openci_shared.dart';

bool isPaidWorkerRequest(RequestContext context) {
  Map<String, String> environment;
  try {
    environment = context.read<Map<String, String>>();
  } catch (_) {
    environment = Platform.environment;
  }
  return environment['SERVER_ACCESS_MODE'] == 'cloud' &&
      environment['BILLING_ENABLED'] == 'true';
}

BillingWorkerAttempt readPaidWorkerAttempt(
  RequestContext context,
  String jobId,
  Map<String, dynamic> payload,
) {
  if (!context.read<InternalApiKeyValidator>().isValid(context)) {
    throw const PaidWorkerAuthenticationRequired();
  }
  try {
    return BillingWorkerAttempt.fromJson(jobId, payload);
  } on FormatException catch (error) {
    throw PaidWorkerRequestInvalid(error.message);
  }
}

BuildJobStatus paidCompletionStatus(Object? value) => switch (value) {
  'SUCCESS' || 'success' => BuildJobStatus.SUCCESS,
  'FAILURE' || 'failure' => BuildJobStatus.FAILURE,
  'CANCELLED' || 'cancelled' => BuildJobStatus.CANCELLED,
  'TIMED_OUT' || 'timed_out' => BuildJobStatus.TIMED_OUT,
  _ => throw const PaidWorkerRequestInvalid('terminal_status_required'),
};

class PaidWorkerAuthenticationRequired implements Exception {
  const PaidWorkerAuthenticationRequired();
}

class PaidWorkerRequestInvalid implements Exception {
  const PaidWorkerRequestInvalid(this.message);
  final String message;
}
