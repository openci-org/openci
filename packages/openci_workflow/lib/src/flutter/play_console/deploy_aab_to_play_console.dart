import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

import '../../quote_shell_argument.dart';

Future<void> deployAabToPlayConsole({
  required Future<void> Function(String command, {String? workingDirectory})
  run,
  required String aabPath,
  required String packageName,
  required String serviceAccountJsonBase64,
  required String track,
  required bool draft,
  String? dir,
}) async {
  if (aabPath.trim().isEmpty || !aabPath.endsWith('.aab')) {
    throw ArgumentError.value(
      aabPath,
      'aabPath',
      'Must be an AAB file path.',
    );
  }
  if (!RegExp(
    r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$',
  ).hasMatch(packageName)) {
    throw ArgumentError.value(
      packageName,
      'packageName',
      'Must be an Android application ID.',
    );
  }
  if (track.trim().isEmpty ||
      track == '.' ||
      track == '..' ||
      RegExp(r'[/\\\x00-\x1f\x7f]').hasMatch(track)) {
    throw ArgumentError.value(track, 'track', 'Must be a Play track ID.');
  }
  final credentials = _decodeServiceAccount(serviceAccountJsonBase64);
  final file = await _resolveFile(run, aabPath, dir);
  final length = await file.length();
  if (length == 0) {
    throw ArgumentError.value(
      aabPath,
      'aabPath',
      'Must not be empty.',
    );
  }

  final baseClient = _NoRedirectClient(http.Client());
  AutoRefreshingAuthClient? client;
  String? editId;
  var committed = false;
  final appPath = ['applications', packageName, 'edits'];
  try {
    try {
      client = await clientViaServiceAccount(
        credentials,
        ['https://www.googleapis.com/auth/androidpublisher'],
        baseClient: baseClient,
      ).timeout(const Duration(seconds: 60));
    } catch (_) {
      throw StateError(
        'Could not authenticate the Google Play service account.',
      );
    }

    final edit = await _request(
      client,
      _jsonRequest('POST', _uri(appPath), {}),
      'create edit',
    );
    final id = edit['id'];
    if (id is! String || !RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id)) {
      throw StateError('Google Play returned an invalid edit ID.');
    }
    editId = id;
    final editPath = [...appPath, editId];

    stdout.writeln('Uploading AAB to Google Play...');
    final uploaded = await _request(
      client,
      _AabUploadRequest(
        _uri([...editPath, 'bundles'], upload: true),
        file,
        length,
      ),
      'upload AAB',
      timeout: const Duration(minutes: 10),
    );
    final versionCode = uploaded['versionCode'];
    if (versionCode is! int || versionCode <= 0) {
      throw StateError(
        'Google Play returned an invalid uploaded version code.',
      );
    }

    final status = draft ? 'draft' : 'completed';
    final updated = await _request(
      client,
      _jsonRequest('PUT', _uri([...editPath, 'tracks', track]), {
        'track': track,
        'releases': [
          {
            'versionCodes': ['$versionCode'],
            'status': status,
          },
        ],
      }),
      'update track',
    );
    final releases = updated['releases'];
    if (updated['track'] != track ||
        releases is! List ||
        !releases.any(
          (release) =>
              release is Map &&
              release['status'] == status &&
              release['versionCodes'] is List &&
              (release['versionCodes'] as List).contains('$versionCode'),
        )) {
      throw StateError('Google Play did not confirm the requested release.');
    }

    final result = await _request(
      client,
      http.Request(
        'POST',
        _uri([
          ...appPath,
          '$editId:commit',
        ]).replace(
          queryParameters: {'changesInReviewBehavior': 'ERROR_IF_IN_REVIEW'},
        ),
      ),
      'commit edit',
    );
    if (result['id'] != editId) {
      throw StateError(
        'Google Play returned an invalid commit response. '
        'Check Play Console before retrying.',
      );
    }
    committed = true;
    stdout.writeln(
      'Google Play edit committed: $packageName, version $versionCode, '
      'track $track, status $status. '
      'Review and publishing status can be checked in Play Console.',
    );
  } finally {
    if (client != null && editId != null && !committed) {
      try {
        await _request(
          client,
          http.Request('DELETE', _uri([...appPath, editId])),
          'discard edit',
          allowEmpty: true,
        );
      } catch (_) {
        // Cleanup must not replace the original failure or expose credentials.
        stderr.writeln('Could not discard the Google Play edit.');
      }
    }
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

Future<File> _resolveFile(
  Future<void> Function(String command, {String? workingDirectory}) run,
  String path,
  String? dir,
) async {
  final file = File(path);
  if (file.isAbsolute) return file;
  final temporary = await Directory.systemTemp.createTemp('openci-play-path-');
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

Uri _uri(List<String> path, {bool upload = false}) => Uri(
  scheme: 'https',
  host: 'androidpublisher.googleapis.com',
  pathSegments: [if (upload) 'upload', 'androidpublisher', 'v3', ...path],
  queryParameters: upload ? {'uploadType': 'media'} : null,
);

http.Request _jsonRequest(String method, Uri uri, Object body) =>
    http.Request(method, uri)
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode(body);

Future<Map<String, dynamic>> _request(
  http.Client client,
  http.BaseRequest request,
  String action, {
  Duration timeout = const Duration(seconds: 60),
  bool allowEmpty = false,
}) async {
  final http.Response response;
  try {
    response = await client
        .send(request)
        .then(http.Response.fromStream)
        .timeout(timeout);
  } on TimeoutException {
    throw TimeoutException('Google Play $action timed out.');
  } catch (_) {
    throw StateError('Google Play $action request failed.');
  }
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw HttpException(
      'Google Play $action failed (HTTP ${response.statusCode}).'
      '${_errorHint(response)}',
    );
  }
  if (allowEmpty && response.body.isEmpty) return {};
  try {
    final body = jsonDecode(response.body);
    if (body is Map<String, dynamic>) return body;
  } on FormatException {
    // Keep raw server responses out of logs.
  }
  throw StateError('Google Play returned an invalid $action response.');
}

String _errorHint(http.Response response) {
  try {
    final data = jsonDecode(response.body);
    if (data case {'error': {'details': List details}}
        when details.any(
          (detail) =>
              detail is Map && detail['reason'] == 'CHANGES_ALREADY_IN_REVIEW',
        )) {
      return ' The app already has changes in review. Wait for that review '
          'to finish before deploying again.';
    }
  } on FormatException {
    // Only known errors get fixed hints; never return server-provided text.
  }
  return '';
}

class _AabUploadRequest extends http.BaseRequest {
  _AabUploadRequest(Uri uri, this._file, int length) : super('POST', uri) {
    contentLength = length;
    headers['Content-Type'] = 'application/octet-stream';
  }

  final File _file;

  @override
  http.ByteStream finalize() {
    super.finalize();
    return http.ByteStream(_file.openRead());
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
