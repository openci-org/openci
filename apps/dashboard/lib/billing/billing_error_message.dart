import 'package:dashboard/billing/billing_response.dart';

String billingErrorMessage(Object error) {
  final code = error is BillingException ? error.code : '';
  return switch (code) {
    'authentication_required' => 'もう一度サインインしてください。',
    'forbidden' => 'このチームの課金情報にアクセスできません。',
    'billing_disabled' => '現在、この接続先では課金機能を利用できません。',
    'context_changed' => '接続先またはアカウントが変わりました。画面を開き直してください。',
    'subscription_exists' => '契約がすでにあります。再読み込みして契約を確認してください。',
    'payment_pending' || 'checkout_conflict' => '決済を確認しています。時間をおいて再読み込みしてください。',
    'customer_missing' => '管理できる契約がありません。再読み込みしてください。',
    'launch_failed' => 'Stripeを開けませんでした。もう一度お試しください。',
    _ => '課金処理を完了できませんでした。時間をおいてもう一度お試しください。',
  };
}
