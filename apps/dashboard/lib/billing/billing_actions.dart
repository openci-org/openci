import 'package:dashboard/billing/billing_api.dart';
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

  Future<Uri> portal() async => (await _create('portal'))!;

  Future<Uri?> setupCard() => _create('setupCard');

  Future<Uri?> _create(String action) async {
    _requireCurrentIdentity();
    if (_pending) throw const BillingException('request_in_progress');
    final status = _ref.read(billingStatusProvider(teamId));
    final data = status.asData?.value;
    final allowed = switch (action) {
      'portal' => data?.canManageBilling,
      'setupCard' => data?.canSetupCard,
      _ => false,
    };
    if (status.isLoading ||
        status.hasError ||
        data?.billingEnabled != true ||
        allowed != true) {
      throw const BillingException('forbidden');
    }
    _pending = true;
    try {
      final api = await _ref.read(billingApiProvider.future);
      _requireCurrentIdentity();
      final body = await api.call(
        action,
        teamId,
        termsVersion: action == 'setupCard'
            ? 'ci-jpy1-tax-included-monthly-v1'
            : null,
      );
      _requireCurrentIdentity();
      if (action == 'setupCard' && body['registered'] == true) return null;
      final url = body['url'];
      final uri = url is String ? Uri.tryParse(url) : null;
      final portal = action == 'portal';
      final host = portal ? 'billing.stripe.com' : 'checkout.stripe.com';
      final path = portal ? '/p/session/' : '/c/pay/';
      final hasPortalQuerySession =
          portal &&
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
