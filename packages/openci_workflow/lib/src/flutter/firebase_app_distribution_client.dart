import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

String firebaseAppName(String appId) {
  final match = RegExp(r'^\d+:(\d+):ios:[a-zA-Z0-9]+$').firstMatch(appId);
  if (match == null) {
    throw ArgumentError.value(
      appId,
      'appId',
      'Must be an iOS Firebase App ID.',
    );
  }
  return 'projects/${match[1]}/apps/$appId';
}

class FirebaseAppDistributionClient {
  FirebaseAppDistributionClient(
    this._client, {
    this.pollInterval = const Duration(seconds: 2),
    this.operationTimeout = const Duration(minutes: 5),
  });

  final http.Client _client;
  final Duration pollInterval;
  final Duration operationTimeout;

  Future<String> upload({
    required File ipa,
    required String appName,
    List<String> groups = const [],
    List<String> testers = const [],
    String? releaseNotes,
  }) async {
    final upload = _IpaUploadRequest(
      _uri('/upload/v1/$appName/releases:upload'),
      ipa,
      await ipa.length(),
    );
    var operation = await _request(
      upload,
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
    while (operation['done'] != true) {
      final remaining = operationTimeout - elapsed.elapsed;
      if (remaining <= Duration.zero) {
        throw TimeoutException('Firebase IPA processing timed out.');
      }
      await Future<void>.delayed(
        Duration(
          microseconds: min(
            pollInterval.inMicroseconds,
            remaining.inMicroseconds,
          ),
        ),
      );
      final requestTimeout = operationTimeout - elapsed.elapsed;
      if (requestTimeout <= Duration.zero) {
        throw TimeoutException('Firebase IPA processing timed out.');
      }
      operation = await _request(
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
        'Firebase IPA processing failed${code is int ? ' (code $code)' : ''}.',
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

    if (releaseNotes != null) {
      await _request(
        _jsonRequest(
          'PATCH',
          _uri('/v1/$releaseName', {'updateMask': 'releaseNotes.text'}),
          {
            'name': releaseName,
            'releaseNotes': {'text': releaseNotes},
          },
        ),
        'update release notes',
      );
    }
    if (groups.isNotEmpty || testers.isNotEmpty) {
      await _request(
        _jsonRequest('POST', _uri('/v1/$releaseName:distribute'), {
          'testerEmails': testers,
          'groupAliases': groups,
        }),
        'distribute release',
      );
    }
    return releaseName;
  }

  Future<Map<String, dynamic>> _request(
    http.BaseRequest request,
    String action, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    request.followRedirects = false;
    final http.Response response;
    try {
      response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
    } on TimeoutException {
      throw TimeoutException('Firebase App Distribution $action timed out.');
    } catch (_) {
      // HTTP/auth errors can include tokens or response bodies.
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
}

Uri _uri(String path, [Map<String, String>? query]) =>
    Uri.https('firebaseappdistribution.googleapis.com', path, query);

http.Request _jsonRequest(String method, Uri uri, Map<String, Object> body) =>
    http.Request(method, uri)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode(body);

class _IpaUploadRequest extends http.BaseRequest {
  _IpaUploadRequest(Uri uri, this._ipa, int length) : super('POST', uri) {
    contentLength = length;
    headers.addAll({
      'Content-Type': 'application/octet-stream',
      'X-Goog-Upload-Protocol': 'raw',
      'X-Goog-Upload-File-Name': Uri.encodeComponent(
        _ipa.uri.pathSegments.last,
      ),
    });
  }

  final File _ipa;

  @override
  http.ByteStream finalize() {
    super.finalize();
    return http.ByteStream(_ipa.openRead());
  }
}
