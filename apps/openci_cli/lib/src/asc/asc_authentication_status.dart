class AscAuthenticationStatus {
  const AscAuthenticationStatus({
    required this.authenticated,
    this.providerName,
    this.providerId,
    this.publicProviderId,
  });

  final bool authenticated;
  final String? providerName;
  final int? providerId;
  final String? publicProviderId;
}
