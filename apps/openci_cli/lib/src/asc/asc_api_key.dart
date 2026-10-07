import 'dart:io';

class AscApiKey {
  const AscApiKey({
    required this.keyId,
    required this.issuerId,
    required this.privateKeyFile,
  });

  final String keyId;
  final String issuerId;
  final File privateKeyFile;
}
