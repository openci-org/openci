import 'ios_signing_keychain_path.dart';

Future<void> importIosSigningCertificates({
  required Future<void> Function(String command, {String? workingDirectory})
  run,
  String? dir,
}) async {
  await run(
    'keychain add-certificates --path $iosSigningKeychainPath',
    workingDirectory: dir,
  );
}
