class IosSigningCredentials {
  const IosSigningCredentials({
    required this.issuerId,
    required this.keyId,
    required this.ascPrivateKeyPath,
    required this.certificatePrivateKeyPath,
  });

  final String issuerId;
  final String keyId;
  final String ascPrivateKeyPath;
  final String certificatePrivateKeyPath;
}
