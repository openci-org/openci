import 'package:dashboard/api/openci_api_client.dart';
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
          final api = await ref.watch(openciApiServiceProvider.future);
          if (!ref.mounted) return null;
          if (api.client.baseUrl != Uri.tryParse(identity.connection.apiUrl)) {
            throw const BillingException('billing_unavailable');
          }
          final response = await api.getBillingStatus(teamId);
          if (!ref.mounted) return null;
          return BillingStatus.fromJson(billingResponseBody(response));
        } on BillingException {
          rethrow;
        } catch (_) {
          throw const BillingException('billing_unavailable');
        }
      },
      retry: (_, _) => null,
    );
