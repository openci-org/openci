Future<void> initializeIosKeychain({
  required Future<void> Function(String command, {String? workingDirectory})
  run,
  String? dir,
}) async {
  const keychainPath = '/tmp/openci-signing.keychain-db';
  await run(
    'keychain initialize --path $keychainPath',
    workingDirectory: dir,
  );
}
