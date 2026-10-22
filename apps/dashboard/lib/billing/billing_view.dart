import 'package:dashboard/billing/billing_status.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BillingView extends StatelessWidget {
  const BillingView({
    required this.teamName,
    required this.status,
    required this.onCheckout,
    required this.onPortal,
    required this.onReload,
    this.pending = false,
    this.returnedFromStripe = false,
    this.error,
    super.key,
  });

  final String teamName;
  final BillingStatus status;
  final ValueChanged<String> onCheckout;
  final VoidCallback onPortal;
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
          const Text('現在、この接続先では課金機能を利用できません。')
        else ...[
          if (returnedFromStripe) ...[
            const Text(
              'Stripeから戻りました。変更の反映には時間がかかることがあります。反映されない場合は「再読み込み」を押してください。',
            ),
            const SizedBox(height: 16),
          ],
          Text(
            status.canStartCi ? 'CIを利用できます' : _blockMessage(status),
            style: theme.textTheme.titleMedium,
          ),
          if (status.paidUntil != null) ...[
            const SizedBox(height: 8),
            Text(
              '${status.cancelAtPeriodEnd ? '利用期限' : '支払い済み期間の終了'}（UTC）: ${DateFormat('yyyy/MM/dd HH:mm').format(status.paidUntil!.toUtc())}',
            ),
          ],
          const SizedBox(height: 24),
          for (final plan in [
            (id: 'light', name: 'Light', price: 'US\$10 / 月', minutes: '600'),
            (id: 'pro', name: 'Pro', price: 'US\$100 / 月', minutes: '6,000'),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card.outlined(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.name, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(plan.price, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('チーム共有 ${plan.minutes}分 / 月'),
                      const SizedBox(height: 16),
                      if (status.planId == plan.id)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text('現在のプラン'),
                        ),
                      if (status.canCheckout)
                        FilledButton(
                          onPressed: pending ? null : () => onCheckout(plan.id),
                          child: Text('${plan.name}を選ぶ'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          const Text('プラン・チーム単位の同時実行数制限はありません。実行開始はワーカーの空き状況に依存します。'),
          const SizedBox(height: 8),
          const Text('7日間返金保証。初回から決済が発生します。'),
          const SizedBox(height: 8),
          const Text(
            '初回決済の成功から168時間以内の申請で全額返金します。更新・再契約は対象外です。'
            '返金時に即時解約となり、新しいCIは開始できません。実行中のCIは完了まで継続します。',
          ),
          if (status.canManageBilling) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: pending ? null : onPortal,
              icon: const Icon(Icons.open_in_new),
              label: const Text('契約を管理'),
            ),
          ],
        ],
        if (pending) ...[
          const SizedBox(height: 16),
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          const Text('Stripeを開く準備をしています…'),
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
          label: const Text('再読み込み'),
        ),
      ],
    );
  }
}

String _blockMessage(BillingStatus status) => switch (status.blockReason) {
  'payment_required' when !status.canCheckout && status.canManageBilling =>
    'CIを利用するには、「契約を管理」からお支払いを確認してください。',
  'payment_required' => 'CIの利用にはプランの購入が必要です。',
  'allowance_exhausted' => '新しいCIを開始できる利用枠がありません。',
  'subscription_ended' => '契約が終了しています。',
  'payment_pending' => '決済を確認しています。時間をおいて再読み込みしてください。',
  _ => '現在、CIを開始できません。時間をおいて再読み込みしてください。',
};
