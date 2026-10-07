class AscAuthenticationStatus {
  const AscAuthenticationStatus({
    required this.authenticated,
    this.providerId,
    this.publicProviderId,
  });

  final bool authenticated;
  final int? providerId;
  final String? publicProviderId;
}
