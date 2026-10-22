class BillingStatus {
  const BillingStatus({
    required this.billingEnabled,
    required this.planId,
    required this.canStartCi,
    required this.blockReason,
    required this.paidUntil,
    required this.canCheckout,
    required this.canManageBilling,
    required this.cancelAtPeriodEnd,
  });

  factory BillingStatus.fromJson(Map<String, dynamic> json) {
    final planId = json['planId'] as String?;
    if (planId != null && !{'light', 'pro'}.contains(planId)) {
      throw const FormatException('Unknown billing plan');
    }
    final paidUntil = json['paidUntil'] as String?;
    return BillingStatus(
      billingEnabled: json['billingEnabled'] as bool,
      planId: planId,
      canStartCi: json['canStartCi'] as bool,
      blockReason: json['blockReason'] as String,
      paidUntil: paidUntil == null ? null : DateTime.parse(paidUntil).toUtc(),
      canCheckout: json['canCheckout'] as bool,
      canManageBilling: json['canManageBilling'] as bool,
      cancelAtPeriodEnd: json['cancelAtPeriodEnd'] as bool,
    );
  }

  final bool billingEnabled;
  final String? planId;
  final bool canStartCi;
  final String blockReason;
  final DateTime? paidUntil;
  final bool canCheckout;
  final bool canManageBilling;
  final bool cancelAtPeriodEnd;
}
