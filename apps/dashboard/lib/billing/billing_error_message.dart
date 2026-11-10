import 'package:dashboard/app_strings.dart';
import 'package:dashboard/billing/billing_response.dart';

String billingErrorMessage(Object error, {Translations? strings}) {
  strings ??= t;
  final code = error is BillingException ? error.code : '';
  return switch (code) {
    'authentication_required' => strings.billing.authenticationRequired,
    'forbidden' => strings.billing.forbidden,
    'billing_disabled' => strings.billing.disabled,
    'card_consent_required' => strings.billing.cardConsentRequired,
    'context_changed' => strings.billing.contextChanged,
    'subscription_exists' => strings.billing.subscriptionExists,
    'payment_pending' || 'checkout_conflict' => strings.billing.checkoutPending,
    'customer_missing' => strings.billing.customerMissing,
    'launch_failed' => strings.billing.launchFailed,
    _ => strings.billing.operationFailed,
  };
}
