class AppStoreConnectKeys {
  const AppStoreConnectKeys({
    required this.issuerId,
    required this.keyId,
    required this.privateKeyBase64,
  });

  final String issuerId;
  final String keyId;
  final String privateKeyBase64;
}
