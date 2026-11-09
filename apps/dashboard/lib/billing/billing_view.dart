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
          const SizedBox(height: 24),
          if (status.cardSetupStatus != null) ...[
            Text('CIの月次後払い', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text('CI実行1分につき税込1円。利用料は月ごとに集計し、翌月に登録カードで自動決済します。'),
            if (status.canSetupCard)
              OutlinedButton(
                onPressed: pending ? null : () => _confirmCardSetup(context),
                child: Text(
                  status.cardSetupStatus == CardSetupStatus.pending
                      ? 'カード登録を続ける'
                      : '支払い方法を登録',
                ),
              )
            else
              Text(
                status.cardSetupStatus == CardSetupStatus.registered
                    ? '後払い用のカードは登録済みです。'
                    : '「支払い方法を管理」から請求用のカードを設定してください。',
              ),
            const SizedBox(height: 24),
          ],
          if (status.canManageBilling) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: pending ? null : onPortal,
              icon: const Icon(Icons.open_in_new),
              label: const Text('支払い方法を管理'),
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

  Future<void> _confirmCardSetup(BuildContext context) async {
    final agreed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('月次後払いに同意しますか？'),
        content: Text(
          'チーム「$teamName」のCI利用料は1分1円（税込）です。月の利用時間を合計し、翌月に登録カードから自動決済します。カード登録時の利用料は0円です。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('同意してStripeへ'),
          ),
        ],
      ),
    );
    if (agreed == true && context.mounted) onSetupCard();
  }
}

String _blockMessage(BillingStatus status) => switch (status.blockReason) {
  'payment_required' => 'CIを開始するには、このチームの請求用カードを登録してください。',
  'allowance_exhausted' => '新しいCIを開始できる利用枠がありません。',
  'subscription_ended' => '契約が終了しています。',
  'payment_pending' => 'カード登録の完了を待っています。',
  _ => '現在、CIを開始できません。時間をおいて再読み込みしてください。',
};
