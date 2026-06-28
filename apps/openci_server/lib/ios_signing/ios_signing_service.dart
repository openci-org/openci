import 'dart:io';

class IosSigningService {
  static Future<String> generatePrivateKey() async {
    final result = await Process.run('openssl', ['genrsa', '2048']);
    if (result.exitCode != 0) {
      throw ProcessException(
        'openssl',
        ['genrsa', '2048'],
        'openssl genrsa failed: ${result.stderr}',
      );
    }

    final privateKeyPem = result.stdout.toString().trim();
    if (privateKeyPem.isEmpty) {
      throw const FormatException('Generated private key is empty');
    }

    return privateKeyPem;
  }
}
