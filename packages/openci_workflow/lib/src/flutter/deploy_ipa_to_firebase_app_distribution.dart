import 'dart:convert';
import 'dart:io';

import '../quote_shell_argument.dart';

Future<void> deployIpaToFirebaseAppDistribution({
  required Future<void> Function(String command, {String? workingDirectory})
  run,
  required String ipaPath,
  required String serviceAccountJsonBase64,
  String firebaseCliPath = 'firebase',
  String? appId,
  List<String> groups = const [],
  List<String> testers = const [],
  String? releaseNotes,
  String? dir,
}) async {
  if (ipaPath.trim().isEmpty || !ipaPath.endsWith('.ipa')) {
    throw ArgumentError.value(ipaPath, 'ipaPath', 'Must be an IPA file path.');
  }
  if (firebaseCliPath.trim().isEmpty) {
    throw ArgumentError.value(
      firebaseCliPath,
      'firebaseCliPath',
      'Must be a Firebase CLI executable path.',
    );
  }
  final credentials = _decodeServiceAccount(serviceAccountJsonBase64);
  final path = ipaPath.startsWith('/') ? ipaPath : './$ipaPath';
  final firebaseAppId = appId ?? await _readAppId(run, path, dir);
  if (!RegExp(r'^\d+:\d+:ios:[a-zA-Z0-9]+$').hasMatch(firebaseAppId)) {
    throw ArgumentError.value(
      firebaseAppId,
      'appId',
      'Must be an iOS Firebase App ID, such as 1:123456789:ios:abcdef.',
    );
  }
  final temporary = await Directory.systemTemp.createTemp(
    'openci-fad-credentials-',
  );
  try {
    final file = File.fromUri(temporary.uri.resolve('service-account.json'));
    await file.create();
    final permissions = await Process.run('chmod', ['600', file.path]);
    if (permissions.exitCode != 0) {
      throw ProcessException(
        'chmod',
        ['600', file.path],
        'Could not restrict Firebase service account file permissions.',
        permissions.exitCode,
      );
    }
    await file.writeAsBytes(credentials, flush: true);
    final command = [
      // Keep inherited CLI tokens and cached logins from overriding this key.
      "FIREBASE_TOKEN=''",
      'XDG_CONFIG_HOME=${quoteShellArgument(temporary.path)}',
      'GOOGLE_APPLICATION_CREDENTIALS=${quoteShellArgument(file.path)}',
      '${quoteShellArgument(firebaseCliPath)} '
          'appdistribution:distribute ${quoteShellArgument(path)}',
      '--app ${quoteShellArgument(firebaseAppId)}',
      '--non-interactive',
      if (groups.isNotEmpty) '--groups=${quoteShellArgument(groups.join(','))}',
      if (testers.isNotEmpty)
        '--testers=${quoteShellArgument(testers.join(','))}',
      if (releaseNotes != null)
        '--release-notes=${quoteShellArgument(releaseNotes)}',
    ].join(' ');
    // The command runner exits the workflow on failure, bypassing Dart finally.
    final cleanup = 'rm -rf -- ${quoteShellArgument(temporary.path)}';
    await run(
      'trap ${quoteShellArgument(cleanup)} 0\n$command',
      workingDirectory: dir,
    );
  } finally {
    if (await temporary.exists()) await temporary.delete(recursive: true);
  }
}

List<int> _decodeServiceAccount(String value) {
  try {
    final bytes = base64Decode(value);
    if (jsonDecode(utf8.decode(bytes)) case {
      'type': 'service_account',
      'client_email': String email,
      'private_key': String key,
    } when email.isNotEmpty && key.isNotEmpty) {
      return bytes;
    }
  } on FormatException {
    // Never include the supplied value or JSON parser context in errors.
  }
  throw const FormatException(
    'serviceAccountJsonBase64 must contain a Base64-encoded service account '
    'JSON with type, client_email, and private_key fields.',
  );
}

Future<String> _readAppId(
  Future<void> Function(String command, {String? workingDirectory}) run,
  String ipaPath,
  String? dir,
) async {
  final temporary = await Directory.systemTemp.createTemp('openci-fad-');
  final entries = File.fromUri(temporary.uri.resolve('entries'));
  final plist = File.fromUri(temporary.uri.resolve('GoogleService-Info.plist'));
  final appId = File.fromUri(temporary.uri.resolve('app-id'));
  try {
    await run(
      'unzip -Z1 ${quoteShellArgument(ipaPath)} '
      '> ${quoteShellArgument(entries.path)}',
      workingDirectory: dir,
    );
    final configs = (await entries.readAsLines())
        .where(
          RegExp(r'^Payload/[^/]+\.app/GoogleService-Info\.plist$').hasMatch,
        )
        .toList();
    if (configs.length != 1) {
      throw StateError(
        'Expected one app-level GoogleService-Info.plist in the IPA. '
        'Pass appId explicitly if the app does not bundle Firebase config.',
      );
    }
    // unzip interprets entry names as patterns, even when shell-quoted.
    final entry = configs.single.replaceAllMapped(
      RegExp(r'[*?\[\\]'),
      (match) => '\\${match[0]}',
    );
    await run(
      'unzip -p ${quoteShellArgument(ipaPath)} ${quoteShellArgument(entry)} '
      '> ${quoteShellArgument(plist.path)}',
      workingDirectory: dir,
    );
    await run(
      'plutil -extract GOOGLE_APP_ID raw -expect string '
      '-o ${quoteShellArgument(appId.path)} ${quoteShellArgument(plist.path)}',
      workingDirectory: dir,
    );
    return (await appId.readAsString()).trim();
  } finally {
    await temporary.delete(recursive: true);
  }
}
