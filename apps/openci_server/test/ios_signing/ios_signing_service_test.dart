import 'package:openci_server/ios_signing/ios_signing_service.dart';
import 'package:test/test.dart';

void main() {
  group('IosSigningService', () {
    test('generatePrivateKey generates a valid RSA private key PEM', () async {
      final key = await IosSigningService.generatePrivateKey();
      expect(key, isNotEmpty);
      expect(key, contains('-----BEGIN PRIVATE KEY-----'));
      expect(key, contains('-----END PRIVATE KEY-----'));
    });
  });
}
