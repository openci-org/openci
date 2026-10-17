import 'package:openci_server/secret/secret_crypter.dart';

Future<String> decryptGitHubConnectionToken(
  String encryptedAccessToken,
  Map<String, String> environment,
) async {
  try {
    final crypter = SecretCrypter(environment['SECRET_ENCRYPTION_KEY'] ?? '');
    return await crypter.decrypt(encryptedAccessToken);
  } catch (_) {
    throw StateError('Failed to decrypt GitHub connection token');
  }
}
