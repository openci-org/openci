import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

import '../quote_shell_argument.dart';
import 'firebase_app_distribution_client.dart';

Future<void> deployIpaToFirebaseAppDistribution({
  required Future<void> Function(String command, {String? workingDirectory})
  run,
  required String ipaPath,
  required String serviceAccountJsonBase64,
  String? appId,
  List<String> groups = const [],
  List<String> testers = const [],
  String? releaseNotes,
  String? dir,
}) async {
  if (ipaPath.trim().isEmpty || !ipaPath.endsWith('.ipa')) {
    throw ArgumentError.value(ipaPath, 'ipaPath', 'Must be an IPA file path.');
  }
  final credentials = _decodeServiceAccount(serviceAccountJsonBase64);
  if (appId != null) firebaseAppName(appId);
  final ipa = await _resolveIpa(run, ipaPath, dir);
  if (await ipa.length() == 0) {
    throw ArgumentError.value(ipaPath, 'ipaPath', 'Must not be empty.');
  }
  final firebaseAppId = appId ?? await _readAppId(run, ipa.path, dir);
  final appName = firebaseAppName(firebaseAppId);
  final baseClient = http.Client();
  AutoRefreshingAuthClient? client;
  try {
    try {
      client = await clientViaServiceAccount(
        credentials,
        ['https://www.googleapis.com/auth/cloud-platform'],
        baseClient: baseClient,
      ).timeout(const Duration(seconds: 60));
    } catch (_) {
      throw StateError('Could not authenticate the Firebase service account.');
    }
    stdout.writeln('Uploading IPA to Firebase App Distribution...');
    final release = await FirebaseAppDistributionClient(client).upload(
      ipa: ipa,
      appName: appName,
      groups: groups,
      testers: testers,
      releaseNotes: releaseNotes,
    );
    stdout.writeln('Firebase App Distribution upload complete: $release');
  } finally {
    client?.close();
    baseClient.close();
  }
}

ServiceAccountCredentials _decodeServiceAccount(String value) {
  try {
    final data = jsonDecode(utf8.decode(base64Decode(value)));
    if (data case {
      'type': 'service_account',
      'client_id': String clientId,
      'client_email': String email,
      'private_key': String key,
    } when clientId.isNotEmpty && email.isNotEmpty && key.isNotEmpty) {
      return ServiceAccountCredentials.fromJson(data);
    }
  } catch (_) {
    // JSON/key parsing errors can contain the supplied secret.
  }
  throw const FormatException(
    'serviceAccountJsonBase64 must contain a Base64-encoded service account '
    'JSON with client_id, client_email, and a valid private_key.',
  );
}

Future<File> _resolveIpa(
  Future<void> Function(String command, {String? workingDirectory}) run,
  String path,
  String? dir,
) async {
  final file = File(path);
  if (file.isAbsolute) return file;
  final temporary = await Directory.systemTemp.createTemp('openci-fad-path-');
  try {
    final cwd = File.fromUri(temporary.uri.resolve('cwd'));
    await run(
      r'''printf '%s' "$PWD" > ''' + quoteShellArgument(cwd.path),
      workingDirectory: dir,
    );
    return File('${await cwd.readAsString()}/$path');
  } finally {
    await temporary.delete(recursive: true);
  }
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
