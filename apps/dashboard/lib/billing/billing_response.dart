class BillingException implements Exception {
  const BillingException(this.code);

  final String code;

  @override
  String toString() => code;
}
