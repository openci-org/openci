import 'package:cloud_functions/cloud_functions.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../auth/auth_provider.dart';
import '../connections/active_connection_firebase_auth.dart';
import '../connections/local_development_connection.dart';
import 'billing_response.dart';

// Deletion also runs outside the billing page. Keep the client alive while a
// caller awaits Stripe; auth/connection dependencies still invalidate it.
final billingApiProvider = FutureProvider<BillingApi>((ref) async {
  final user = await ref.watch(authStateChangesProvider.future);
  if (user == null) throw const BillingException('authentication_required');
  final auth = await ref.watch(activeConnectionFirebaseAuthProvider.future);
  final local = ref.watch(localDevelopmentConnectionProvider);
  bool isCurrent() => ref.mounted && auth.currentUser?.uid == user.uid;
  if (!isCurrent()) throw const BillingException('context_changed');
  final functions = FirebaseFunctions.instanceFor(
    app: auth.app,
    region: 'asia-northeast1',
  );
  if (local != null) functions.useFunctionsEmulator(local.emulatorHost, 5001);
  return BillingApi(
    callable: functions.httpsCallable(
      'teamBilling',
      options: HttpsCallableOptions(timeout: const Duration(minutes: 5)),
    ),
    isCurrent: isCurrent,
  );
});

class BillingApi {
  BillingApi({required this.callable, required this.isCurrent});
  final HttpsCallable callable;
  final bool Function() isCurrent;

  void _requireCurrent() {
    if (!isCurrent()) throw const BillingException('context_changed');
  }

  Future<Map<String, dynamic>> call(
    String action,
    String teamId, {
    String? planId,
  }) async {
    _requireCurrent();
    try {
      final result = await callable.call<Map<String, dynamic>>({
        'action': action,
        'teamId': teamId,
        'planId': ?planId,
      });
      _requireCurrent();
      return result.data;
    } on FirebaseFunctionsException catch (error) {
      _requireCurrent();
      final details = error.details;
      final reason = details is Map ? details['reason'] : null;
      if (error.code == 'unauthenticated') {
        throw const BillingException('authentication_required');
      }
      if (error.code == 'permission-denied') {
        throw const BillingException('forbidden');
      }
      if (const {
        'invalid_plan',
        'customer_missing',
        'subscription_exists',
        'checkout_conflict',
        'payment_pending',
        'billing_disabled',
      }.contains(reason)) {
        throw BillingException(reason as String);
      }
      throw const BillingException('billing_unavailable');
    } on BillingException {
      rethrow;
    } catch (_) {
      _requireCurrent();
      throw const BillingException('billing_unavailable');
    }
  }

  Future<void> deleteTeam(String teamId) async {
    if ((await call('deleteTeam', teamId))['success'] != true) {
      throw const BillingException('billing_unavailable');
    }
  }
}
