import 'package:dashboard/app_strings.dart';
import 'package:dashboard/billing/billing_provider.dart';
import 'package:dashboard/responsive/desktop_max_width.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MonthlyUsageTile extends ConsumerWidget {
  const MonthlyUsageTile({required this.teamId, super.key});

  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = billingStatusProvider(teamId);
    final result = ref.watch(provider);
    if (result.isLoading) return const SizedBox.shrink();
    final status = result.asData?.value;
    if (!result.hasError &&
        (status == null ||
            !status.billingEnabled ||
            !status.showsMonthlyUsage)) {
      return const SizedBox.shrink();
    }

    final usage = status?.monthlyUsage;
    final billing = context.t.billing;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: desktopMaxWidth),
        child: ListTile(
          title: Text(
            usage == null
                ? billing.usageUnavailable
                : billing.monthlyUsage(month: usage.month),
          ),
          subtitle: usage == null
              ? null
              : Text(
                  billing.estimatedAmount(amount: usage.amountJpyTaxIncluded),
                ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: context.t.common.reload,
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.invalidate(provider),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: () => context.go(
            Uri(
              path: '/billing',
              queryParameters: {'teamId': teamId},
            ).toString(),
          ),
        ),
      ),
    );
  }
}
