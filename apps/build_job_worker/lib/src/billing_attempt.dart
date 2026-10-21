class BillingAttempt {
  const BillingAttempt({
    required this.admissionId,
    required this.runId,
    required this.workerHost,
  });

  final String admissionId;
  final String runId;
  final String workerHost;

  Map<String, dynamic> toJson() => {
    'billingAdmissionId': admissionId,
    'runId': runId,
    'workerHost': workerHost,
  };
}
