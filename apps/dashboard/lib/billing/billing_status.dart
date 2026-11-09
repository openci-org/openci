class BillingStatus {
  const BillingStatus({
    required this.billingEnabled,
    this.monthlyUsage,
    this.monthlyUsageUnavailable = false,
    required this.planId,
    required this.canStartCi,
    required this.blockReason,
    required this.paidUntil,
    required this.canCheckout,
    required this.canManageBilling,
    required this.cancelAtPeriodEnd,
  });

  factory BillingStatus.fromJson(Map<String, dynamic> json) {
    final monthlyUsage = BillingMonthlyUsage.tryParse(json['monthlyUsage']);
    final planId = json['planId'] as String?;
    if (planId != null && !{'light', 'pro'}.contains(planId)) {
      throw const FormatException('Unknown billing plan');
    }
    final paidUntil = json['paidUntil'] as String?;
    return BillingStatus(
      billingEnabled: json['billingEnabled'] as bool,
      monthlyUsage: monthlyUsage,
      monthlyUsageUnavailable:
          json.containsKey('monthlyUsage') && monthlyUsage == null,
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
  final BillingMonthlyUsage? monthlyUsage;
  final bool monthlyUsageUnavailable;
  bool get showsMonthlyUsage => monthlyUsage != null || monthlyUsageUnavailable;
  final String? planId;
  final bool canStartCi;
  final String blockReason;
  final DateTime? paidUntil;
  final bool canCheckout;
  final bool canManageBilling;
  final bool cancelAtPeriodEnd;
}

class BillingMonthlyUsage {
  const BillingMonthlyUsage({
    required this.month,
    required this.billableMinutes,
    required this.amountJpyTaxIncluded,
    required this.nextInvoiceDate,
  });

  final String month;
  final String billableMinutes;
  final String amountJpyTaxIncluded;
  final String nextInvoiceDate;

  static BillingMonthlyUsage? tryParse(Object? value) {
    if (value case {
      'month': final String month,
      'billableMinutes': final String minutes,
      'amountJpyTaxIncluded': final String amount,
      'nextInvoiceDate': final String nextDate,
    }) {
      if (RegExp(r'^\d{4}-(0[1-9]|1[012])$').hasMatch(month) &&
          RegExp(r'^\d{4}-(0[1-9]|1[012])-01$').hasMatch(nextDate) &&
          RegExp(r'^\d+$').hasMatch(minutes) &&
          RegExp(r'^\d+$').hasMatch(amount)) {
        return BillingMonthlyUsage(
          month: month,
          billableMinutes: minutes,
          amountJpyTaxIncluded: amount,
          nextInvoiceDate: nextDate,
        );
      }
    }
    return null;
  }
}
