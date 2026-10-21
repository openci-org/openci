import 'package:dashboard/api/openci_api_client.dart';
import 'package:dashboard/billing/billing_identity.dart';
import 'package:dashboard/billing/billing_provider.dart';
import 'package:dashboard/billing/billing_response.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final billingActionsProvider = Provider.autoDispose
    .family<BillingActions?, String>(
      (ref, teamId) {
        final identity = ref.watch(billingIdentityProvider);
        return identity == null || teamId.isEmpty
            ? null
            : BillingActions._(ref, identity, teamId);
      },
    );

class BillingActions {
  BillingActions._(this._ref, this._identity, this.teamId);

  final Ref _ref;
  final BillingIdentity _identity;
  final String teamId;
  bool _pending = false;

  Future<Uri> checkout(String planId) {
    if (!{'light', 'pro'}.contains(planId)) {
      throw const BillingException('invalid_plan');
    }
    return _create(planId: planId);
  }

  Future<Uri> portal() => _create();

  Future<Uri> _create({String? planId}) async {
    _requireCurrentIdentity();
    if (_pending) throw const BillingException('request_in_progress');
    final status = _ref.read(billingStatusProvider(teamId));
    final data = status.asData?.value;
    if (status.isLoading ||
        status.hasError ||
        data?.billingEnabled != true ||
        (planId == null ? !data!.canManageBilling : !data!.canCheckout)) {
      throw const BillingException('forbidden');
    }
    _pending = true;
    try {
      final api = await _ref.read(openciApiServiceProvider.future);
      _requireCurrentIdentity();
      if (api.client.baseUrl != Uri.tryParse(_identity.connection.apiUrl)) {
        throw const BillingException('billing_unavailable');
      }
      final response = planId == null
          ? await api.createBillingPortal(teamId)
          : await api.createBillingCheckout(teamId, planId);
      _requireCurrentIdentity();
      final body = billingResponseBody(response);
      final url = body['url'];
      final uri = url is String ? Uri.tryParse(url) : null;
      final host = planId == null
          ? 'billing.stripe.com'
          : 'checkout.stripe.com';
      final path = planId == null ? '/p/session/' : '/c/pay/';
      final hasPortalQuerySession =
          planId == null &&
          uri?.path == '/p/session' &&
          (uri?.queryParameters['secret']?.trim().isNotEmpty ?? false);
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host != host ||
          uri.userInfo.isNotEmpty ||
          uri.port != 443 ||
          (!hasPortalQuerySession &&
              (!uri.path.startsWith(path) || uri.path.length == path.length))) {
        throw const BillingException('invalid_redirect');
      }
      return uri;
    } on BillingException {
      rethrow;
    } catch (_) {
      throw const BillingException('billing_unavailable');
    } finally {
      _pending = false;
    }
  }

  void _requireCurrentIdentity() {
    if (!_ref.mounted || _ref.read(billingIdentityProvider) != _identity) {
      throw const BillingException('context_changed');
    }
  }
}
