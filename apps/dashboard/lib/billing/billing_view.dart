import 'package:dashboard/app_strings.dart';
import 'package:dashboard/billing/billing_status.dart';
import 'package:flutter/material.dart';

class BillingView extends StatelessWidget {
  const BillingView({
    required this.teamName,
    required this.status,
    required this.onPortal,
    required this.onSetupCard,
    required this.onReload,
    this.pending = false,
    this.returnedFromStripe = false,
    this.error,
    super.key,
  });

  final String teamName;
  final BillingStatus status;
  final VoidCallback onPortal;
  final VoidCallback onSetupCard;
  final VoidCallback onReload;
  final bool pending;
  final bool returnedFromStripe;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(teamName, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        if (!status.billingEnabled)
          Text(context.t.billing.disabled)
        else ...[
          if (returnedFromStripe) ...[
            Text(
              context.t.billing.returnedFromStripe,
            ),
            const SizedBox(height: 16),
          ],
          Text(
            status.canStartCi
                ? context.t.billing.ciAvailable
                : _blockMessage(context, status),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          if (status.cardSetupStatus != null) ...[
            Text(
              context.t.billing.monthlyPostpaid,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(context.t.billing.monthlyExplanation),
            if (status.canSetupCard)
              OutlinedButton(
                onPressed: pending ? null : () => _confirmCardSetup(context),
                child: Text(
                  status.cardSetupStatus == CardSetupStatus.pending
                      ? context.t.billing.continueCardSetup
                      : context.t.billing.setupCard,
                ),
              )
            else
              Text(
                status.cardSetupStatus == CardSetupStatus.registered
                    ? context.t.billing.cardRegistered
                    : context.t.billing.setCardInPortal,
              ),
            const SizedBox(height: 24),
          ],
          if (status.canManageBilling) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: pending ? null : onPortal,
              icon: const Icon(Icons.open_in_new),
              label: Text(context.t.billing.openPortal),
            ),
          ],
        ],
        if (status.billingEnabled && status.showsMonthlyUsage) ...[
          const SizedBox(height: 24),
          if (status.monthlyUsage case final usage?) ...[
            Text(
              context.t.billing.monthlyUsage(month: usage.month),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(context.t.billing.minutes(minutes: usage.billableMinutes)),
            Text(
              context.t.billing.estimatedAmount(
                amount: usage.amountJpyTaxIncluded,
              ),
            ),
            Text(
              context.t.billing.nextInvoiceDate(
                date: usage.nextInvoiceDate.replaceAll('-', '/'),
              ),
            ),
            Text(context.t.billing.usdExplanation),
          ] else
            Text(context.t.billing.usageUnavailable),
        ],
        if (pending) ...[
          const SizedBox(height: 16),
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text(context.t.billing.openingStripe),
        ],
        if (error != null) ...[
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Text(
              error!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: pending ? null : onReload,
          icon: const Icon(Icons.refresh),
          label: Text(context.t.common.reload),
        ),
      ],
    );
  }

  Future<void> _confirmCardSetup(BuildContext context) async {
    final agreed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(context.t.billing.consentTitle),
        content: Text(
          context.t.billing.consentMessage(teamName: teamName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(context.t.common.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(context.t.billing.agreeAndContinue),
          ),
        ],
      ),
    );
    if (agreed == true && context.mounted) onSetupCard();
  }
}

String _blockMessage(BuildContext context, BillingStatus status) =>
    switch (status.blockReason) {
      'payment_required' => context.t.billing.paymentRequired,
      'allowance_exhausted' => context.t.billing.allowanceExhausted,
      'subscription_ended' => context.t.billing.subscriptionEnded,
      'payment_pending' => context.t.billing.paymentPending,
      _ => context.t.billing.ciUnavailable,
    };
