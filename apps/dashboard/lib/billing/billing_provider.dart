import 'package:dashboard/billing/billing_api.dart';
import 'package:dashboard/billing/billing_identity.dart';
import 'package:dashboard/billing/billing_response.dart';
import 'package:dashboard/billing/billing_status.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final billingStatusProvider = FutureProvider.autoDispose
    .family<BillingStatus?, String>(
      (ref, teamId) async {
        final identity = ref.watch(billingIdentityProvider);
        if (identity == null || teamId.isEmpty) return null;
        try {
          final api = await ref.watch(billingApiProvider.future);
          if (!ref.mounted) return null;
          final response = await api.call('status', teamId);
          if (!ref.mounted) return null;
          return BillingStatus.fromJson(response);
        } on BillingException {
          rethrow;
        } catch (_) {
          throw const BillingException('billing_unavailable');
        }
      },
      retry: (_, _) => null,
    );
