import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/revenue_cat/subscription_provider.dart';
import 'package:dashboard/utilities/async_error_widget.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionPage extends HookConsumerWidget {
  const SubscriptionPage({super.key});

  static const _privacyPolicyUrl = 'https://openci.org/privacy-policy';
  static const _termsOfServiceUrl = 'https://openci.org/terms-of-service';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offerings = ref.watch(offeringsProvider);
    final customerInfo = ref.watch(customerInfoProvider);
    final isPurchasing = useState(false);
    final subT = t.subscription;

    return Scaffold(
      appBar: AppBar(title: Text(subT.title)),
      body: Stack(
        children: [
          offerings.when(
            data: (data) {
              final current = data.current;
              if (current == null) {
                return Center(
                  child: Text(subT.noOfferings),
                );
              }

              final packages = current.availablePackages;
              if (packages.isEmpty) {
                return Center(
                  child: Text(subT.noPackages),
                );
              }

              return customerInfo.when(
                data: (info) {
                  final activeEntitlements = info.entitlements.active;
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (activeEntitlements.isNotEmpty) ...[
                        _ActiveSubscriptionCard(
                          entitlements: activeEntitlements,
                        ),
                        const SizedBox(height: 24),
                      ],
                      Text(
                        subT.plans,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 12),
                      ...packages.map(
                        (package) => _PackageCard(
                          package: package,
                          isActive: _isPackageActive(
                            package,
                            activeEntitlements,
                          ),
                          onTap: () => _purchase(
                            context,
                            ref,
                            package,
                            isPurchasing,
                          ),
                        ),
                      ),
                      if (!kIsWeb) ...[
                        const SizedBox(height: 24),
                        Center(
                          child: TextButton(
                            onPressed: () => _restorePurchases(context, ref),
                            child: Text(subT.restorePurchases),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const _SubscriptionTermsFooter(),
                    ],
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator.adaptive(),
                ),
                error: (error, _) => Center(
                  child: Text(t.common.error(error: error.toString())),
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator.adaptive(),
            ),
            error: asyncErrorWidget,
          ),
          if (isPurchasing.value) ...[
            const ModalBarrier(dismissible: false, color: Colors.black26),
            const Center(child: CircularProgressIndicator.adaptive()),
          ],
        ],
      ),
    );
  }

  bool _isPackageActive(
    Package package,
    Map<String, EntitlementInfo> activeEntitlements,
  ) {
    return activeEntitlements.values.any(
      (e) => e.productIdentifier == package.storeProduct.identifier,
    );
  }

  Future<void> _purchase(
    BuildContext context,
    WidgetRef ref,
    Package package,
    ValueNotifier<bool> isPurchasing,
  ) async {
    isPurchasing.value = true;
    final subT = t.subscription;
    try {
      await Purchases.purchase(PurchaseParams.package(package));
      ref.invalidate(customerInfoProvider);
      if (!context.mounted) return;
      context.showSnackBarMessage(subT.purchaseSuccess);
    } on PlatformException catch (e) {
      if (!context.mounted) return;
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        context.showSnackBarMessage(
          subT.purchaseFailed(error: e.message ?? ''),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      context.showSnackBarMessage(
        subT.purchaseFailed(error: e.toString()),
      );
    } finally {
      isPurchasing.value = false;
    }
  }

  Future<void> _restorePurchases(BuildContext context, WidgetRef ref) async {
    if (kIsWeb) return;
    final subT = t.subscription;
    try {
      await Purchases.restorePurchases();
      ref.invalidate(customerInfoProvider);
      if (!context.mounted) return;
      context.showSnackBarMessage(subT.restoreSuccess);
    } on PlatformException catch (e) {
      if (!context.mounted) return;
      context.showSnackBarMessage(
        subT.restoreFailed(error: e.message ?? ''),
      );
    } catch (e) {
      if (!context.mounted) return;
      context.showSnackBarMessage(
        subT.restoreFailed(error: e.toString()),
      );
    }
  }
}

class _SubscriptionTermsFooter extends StatelessWidget {
  const _SubscriptionTermsFooter();

  @override
  Widget build(BuildContext context) {
    final subT = t.subscription;
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Text(
          kIsWeb ? subT.subscriptionTermsWeb : subT.subscriptionTerms,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => _launchUrl(SubscriptionPage._termsOfServiceUrl),
              child: Text(
                subT.termsOfUse,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '|',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade400,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _launchUrl(SubscriptionPage._privacyPolicyUrl),
              child: Text(
                subT.privacyPolicy,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _ActiveSubscriptionCard extends StatelessWidget {
  const _ActiveSubscriptionCard({required this.entitlements});

  final Map<String, EntitlementInfo> entitlements;

  @override
  Widget build(BuildContext context) {
    final subT = t.subscription;
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subT.activeSubscription,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  ...entitlements.entries.map(
                    (e) => Text(
                      e.value.productIdentifier,
                      style: TextStyle(color: Colors.green.shade600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.isActive,
    required this.onTap,
  });

  final Package package;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final product = package.storeProduct;
    final periodLabel = _subscriptionPeriodLabel(product.subscriptionPeriod);
    final subT = t.subscription;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isActive
            ? BorderSide(color: Colors.green, width: 2)
            : BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isActive ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (product.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        product.description,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (isActive)
                Chip(
                  label: Text(subT.active),
                  backgroundColor: Colors.green.shade50,
                  labelStyle: TextStyle(color: Colors.green.shade700),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      product.priceString,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    if (periodLabel != null)
                      Text(
                        periodLabel,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String? _subscriptionPeriodLabel(String? period) {
    if (period == null) return null;
    final subT = t.subscription;
    return switch (period) {
      'P1W' => subT.perWeek,
      'P1M' => subT.perMonth,
      'P3M' => subT.per3Months,
      'P6M' => subT.per6Months,
      'P1Y' => subT.perYear,
      _ => null,
    };
  }
}
