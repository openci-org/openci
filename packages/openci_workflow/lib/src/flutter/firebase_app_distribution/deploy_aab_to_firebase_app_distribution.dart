import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

import '../../quote_shell_argument.dart';

Future<void> deployAabToFirebaseAppDistribution({
  required Future<void> Function(String command, {String? workingDirectory})
  run,
  required String aabPath,
  required String appId,
  required String serviceAccountJsonBase64,
  String? dir,
}) async {
  if (aabPath.trim().isEmpty || !aabPath.endsWith('.aab')) {
    throw ArgumentError.value(aabPath, 'aabPath', 'Must be an AAB file path.');
  }
  final match = RegExp(r'^\d+:(\d+):android:[a-zA-Z0-9]+$').firstMatch(appId);
  if (match == null) {
    throw ArgumentError.value(
      appId,
      'appId',
      'Must be an Android Firebase App ID.',
    );
  }
  final credentials = _decodeServiceAccount(serviceAccountJsonBase64);
  final aab = await _resolveAab(run, aabPath, dir);
  if (await aab.length() == 0) {
    throw ArgumentError.value(aabPath, 'aabPath', 'Must not be empty.');
  }
  final appName = 'projects/${match[1]}/apps/$appId';
  final baseClient = _NoRedirectClient(http.Client());
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
    await _checkAabIntegration(client, appName);
    stdout.writeln('Uploading AAB to Firebase App Distribution...');
    final release = await _uploadAab(client, aab, appName);
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

Future<File> _resolveAab(
  Future<void> Function(String command, {String? workingDirectory}) run,
  String path,
  String? dir,
) async {
  final file = File(path);
  if (file.isAbsolute) return file;
  final temporary = await Directory.systemTemp.createTemp('openci-aab-path-');
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

Future<void> _checkAabIntegration(http.Client client, String appName) async {
  final info = await _request(
    client,
    http.Request('GET', _uri('/v1/$appName/aabInfo')),
    'check AAB integration',
    timeout: const Duration(seconds: 30),
  );
  if (info['name'] != '$appName/aabInfo') {
    throw StateError('Firebase returned invalid AAB integration information.');
  }
  final message = switch (info['integrationState']) {
    // Firebase CLI also attempts upload when Play's status is unavailable.
    'INTEGRATED' || 'AAB_STATE_UNAVAILABLE' => null,
    'PLAY_ACCOUNT_NOT_LINKED' =>
      'Link this Firebase project to Google Play before uploading AABs.',
    'NO_APP_WITH_GIVEN_BUNDLE_ID_IN_PLAY_ACCOUNT' =>
      'Google Play needs an app with the same package name as the Firebase app.',
    'APP_NOT_PUBLISHED' =>
      'Complete Google Play app review and publish the app to a testing or '
          'production track before uploading AABs to Firebase App Distribution.',
    'PLAY_IAS_TERMS_NOT_ACCEPTED' =>
      'Accept the Google Play internal app sharing terms before uploading AABs.',
    'ADHOC_SHARING_KEY_NOT_GENERATED' =>
      'Google Play has not generated an internal app sharing key for this app.',
    'ADHOC_SHARING_KEY_NOT_REGISTERED' =>
      'Register the internal app sharing key in Android Developer Verification.',
    'PLAY_ANDROID_DEVELOPER_CONSOLE_ACCOUNT_NOT_FOUND' =>
      'The linked Google Play developer account was not found or is not fully '
          'set up in Android Developer Console.',
    'PLAY_ANDROID_DEVELOPER_CONSOLE_PACKAGE_NOT_FOUND' =>
      'The app package was not found in Android Developer Console.',
    _ =>
      'Firebase returned an unknown AAB integration state. '
          'Check the Google Play integration in Firebase project settings.',
  };
  if (message != null) throw StateError(message);
}

Future<String> _uploadAab(http.Client client, File aab, String appName) async {
  var operation = await _request(
    client,
    _AabUploadRequest(
      _uri('/upload/v1/$appName/releases:upload'),
      aab,
      await aab.length(),
    ),
    'upload',
    timeout: const Duration(minutes: 10),
  );
  final operationName = operation['name'];
  if (operationName is! String ||
      !RegExp(
        '^${RegExp.escape(appName)}/releases/[a-zA-Z0-9_-]+/'
        r'operations/[a-zA-Z0-9_-]+$',
      ).hasMatch(operationName)) {
    throw StateError('Firebase returned an invalid upload operation.');
  }

  final elapsed = Stopwatch()..start();
  const operationTimeout = Duration(minutes: 5);
  while (operation['done'] != true) {
    final remaining = operationTimeout - elapsed.elapsed;
    if (remaining <= Duration.zero) {
      throw TimeoutException('Firebase AAB processing timed out.');
    }
    await Future<void>.delayed(
      Duration(
        microseconds: min(
          const Duration(seconds: 2).inMicroseconds,
          remaining.inMicroseconds,
        ),
      ),
    );
    final requestTimeout = operationTimeout - elapsed.elapsed;
    if (requestTimeout <= Duration.zero) {
      throw TimeoutException('Firebase AAB processing timed out.');
    }
    operation = await _request(
      client,
      http.Request('GET', _uri('/v1/$operationName')),
      'poll upload status',
      timeout: Duration(
        microseconds: min(
          const Duration(seconds: 30).inMicroseconds,
          requestTimeout.inMicroseconds,
        ),
      ),
    );
  }
  if (operation['error'] case final Map error) {
    final code = error['code'];
    throw StateError(
      'Firebase AAB processing failed${code is int ? ' (code $code)' : ''}.',
    );
  }
  final response = operation['response'];
  final release = response is Map ? response['release'] : null;
  final releaseName = release is Map ? release['name'] : null;
  if (releaseName is! String ||
      !RegExp(
        '^${RegExp.escape(appName)}/releases/[a-zA-Z0-9_-]+\$',
      ).hasMatch(releaseName)) {
    throw StateError('Firebase returned an invalid uploaded release.');
  }
  return releaseName;
}

Future<Map<String, dynamic>> _request(
  http.Client client,
  http.BaseRequest request,
  String action, {
  required Duration timeout,
}) async {
  final http.Response response;
  try {
    response = await client
        .send(request)
        .then(http.Response.fromStream)
        .timeout(timeout);
  } on TimeoutException {
    throw TimeoutException('Firebase App Distribution $action timed out.');
  } catch (_) {
    // HTTP/auth errors can contain tokens or response bodies.
    throw StateError('Firebase App Distribution $action request failed.');
  }
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw HttpException(
      'Firebase App Distribution $action failed (HTTP ${response.statusCode}).',
    );
  }
  try {
    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) return body;
  } on FormatException {
    // Keep raw server responses out of logs.
  }
  throw StateError('Firebase returned an invalid $action response.');
}

Uri _uri(String path) =>
    Uri.https('firebaseappdistribution.googleapis.com', path);

class _AabUploadRequest extends http.BaseRequest {
  _AabUploadRequest(Uri uri, this._aab, int length) : super('POST', uri) {
    contentLength = length;
    headers.addAll({
      'Content-Type': 'application/octet-stream',
      'X-Goog-Upload-Protocol': 'raw',
      'X-Goog-Upload-File-Name': Uri.encodeComponent(
        _aab.uri.pathSegments.last,
      ),
    });
  }

  final File _aab;

  @override
  http.ByteStream finalize() {
    super.finalize();
    return http.ByteStream(_aab.openRead());
  }
}

class _NoRedirectClient extends http.BaseClient {
  _NoRedirectClient(this._client);

  final http.Client _client;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    // googleapis_auth recreates requests without preserving followRedirects.
    request.followRedirects = false;
    return _client.send(request);
  }

  @override
  void close() => _client.close();
}
