import 'dart:async';
import 'dart:io';

import '../../app_store_connect_keys.dart';
import 'app_store_connect_client.dart';
import 'read_testflight_ipa.dart';

Future<void> deployIpaToTestFlight({
  required Future<void> Function(String command, {String? workingDirectory})
  run,
  required String ipaPath,
  required AppStoreConnectKeys ascKeys,
  String? dir,
  Duration processingTimeout = const Duration(minutes: 30),
}) async {
  if (ipaPath.trim().isEmpty || !ipaPath.endsWith('.ipa')) {
    throw ArgumentError.value(ipaPath, 'ipaPath', 'Must be an IPA file path.');
  }
  if (processingTimeout <= Duration.zero) {
    throw ArgumentError.value(
      processingTimeout,
      'processingTimeout',
      'Must be positive.',
    );
  }
  final client = AppStoreConnectClient(ascKeys);
  try {
    final ipa = await readTestFlightIpa(run: run, ipaPath: ipaPath, dir: dir);
    final appId = await _findApp(client, ipa.bundleId);
    stdout.writeln('Uploading IPA to App Store Connect...');
    final upload = _resource(
      await client.request(
        'POST',
        '/v1/buildUploads',
        'create build upload',
        body: {
          'data': {
            'type': 'buildUploads',
            'attributes': {
              'cfBundleShortVersionString': ipa.version,
              'cfBundleVersion': ipa.buildNumber,
              'platform': 'IOS',
            },
            'relationships': {
              'app': {
                'data': {'type': 'apps', 'id': appId},
              },
            },
          },
        },
      ),
      'buildUploads',
    );
    final uploadId = upload['id'] as String;
    final length = await ipa.file.length();
    final reservation = _resource(
      await client.request(
        'POST',
        '/v1/buildUploadFiles',
        'reserve IPA upload',
        body: {
          'data': {
            'type': 'buildUploadFiles',
            'attributes': {
              'assetType': 'ASSET',
              'fileName': ipa.file.uri.pathSegments.last,
              'fileSize': length,
              'uti': 'com.apple.ipa',
            },
            'relationships': {
              'buildUpload': {
                'data': {'type': 'buildUploads', 'id': uploadId},
              },
            },
          },
        },
      ),
      'buildUploadFiles',
    );
    final fileId = reservation['id'] as String;
    final parts = _uploadParts(reservation, length);
    final elapsed = Stopwatch()..start();
    for (final part in parts) {
      final remaining = const Duration(minutes: 20) - elapsed.elapsed;
      if (remaining <= Duration.zero) {
        throw TimeoutException('App Store Connect IPA upload timed out.');
      }
      await client.uploadPart(
        ipa: ipa.file,
        uri: part.uri,
        offset: part.offset,
        length: part.length,
        headers: part.headers,
        timeout: remaining,
      );
    }
    _resource(
      await client.request(
        'PATCH',
        '/v1/buildUploadFiles/$fileId',
        'commit IPA upload',
        body: {
          'data': {
            'type': 'buildUploadFiles',
            'id': fileId,
            'attributes': {'uploaded': true},
          },
        },
      ),
      'buildUploadFiles',
      id: fileId,
    );
    stdout.writeln('Waiting for App Store Connect processing: $uploadId');
    await waitForTestFlightProcessing(
      client,
      uploadId,
      timeout: processingTimeout,
    );
    stdout.writeln('TestFlight upload processing complete: $uploadId');
  } finally {
    client.close();
  }
}

Future<String> _findApp(AppStoreConnectClient client, String bundleId) async {
  final response = await client.request(
    'GET',
    '/v1/apps',
    'find app',
    query: {
      'filter[bundleId]': bundleId,
      'fields[apps]': 'bundleId',
      'limit': '2',
    },
  );
  if (response['data'] case [
    {
      'type': 'apps',
      'id': String id,
      'attributes': {'bundleId': String foundBundleId},
    },
  ] when foundBundleId == bundleId && RegExp(r'^\d+$').hasMatch(id)) {
    return id;
  }
  throw StateError(
    'Expected one App Store Connect app matching the IPA Bundle ID.',
  );
}

Future<void> waitForTestFlightProcessing(
  AppStoreConnectClient client,
  String uploadId, {
  required Duration timeout,
  Duration pollInterval = const Duration(seconds: 15),
}) async {
  final elapsed = Stopwatch()..start();
  while (true) {
    final remaining = timeout - elapsed.elapsed;
    if (remaining <= Duration.zero) {
      throw TimeoutException(
        'App Store Connect processing timed out for build upload $uploadId. '
        'The build may still finish processing in App Store Connect.',
      );
    }
    final upload = _resource(
      await client.request(
        'GET',
        '/v1/buildUploads/$uploadId',
        'read build upload status',
        timeout: remaining < const Duration(seconds: 60)
            ? remaining
            : const Duration(seconds: 60),
      ),
      'buildUploads',
      id: uploadId,
    );
    final attributes = upload['attributes'];
    final state = attributes is Map ? attributes['state'] : null;
    switch (state is Map ? state['state'] : null) {
      case 'COMPLETE':
        return;
      case 'FAILED':
        throw StateError(
          'App Store Connect processing failed for build upload $uploadId. '
          'Check the build upload errors in App Store Connect.',
        );
      case 'AWAITING_UPLOAD':
      case 'PROCESSING':
        final remaining = timeout - elapsed.elapsed;
        if (remaining > Duration.zero) {
          await Future<void>.delayed(
            pollInterval < remaining ? pollInterval : remaining,
          );
        }
      default:
        throw StateError(
          'App Store Connect returned an unknown build upload state.',
        );
    }
  }
}

Map<String, dynamic> _resource(
  Map<String, dynamic> response,
  String type, {
  String? id,
}) {
  if (response['data'] case final Map<String, dynamic> data
      when data['type'] == type &&
          data['id'] is String &&
          RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(data['id'] as String) &&
          (id == null || data['id'] == id)) {
    return data;
  }
  throw StateError('App Store Connect returned an invalid $type resource.');
}

typedef _UploadPart = ({
  Uri uri,
  int offset,
  int length,
  Map<String, String> headers,
});

List<_UploadPart> _uploadParts(Map<String, dynamic> reservation, int fileSize) {
  final attributes = reservation['attributes'];
  final operations = attributes is Map ? attributes['uploadOperations'] : null;
  if (operations is! List || operations.isEmpty) {
    throw StateError('App Store Connect returned no IPA upload operations.');
  }
  final parts = <_UploadPart>[];
  try {
    for (final operation in operations) {
      if (operation case {
        'method': 'PUT',
        'url': String url,
        'offset': int offset,
        'length': int length,
      } when offset >= 0 && length > 0 && offset + length <= fileSize) {
        final uri = Uri.parse(url);
        if (uri.scheme != 'https' ||
            uri.host.isEmpty ||
            uri.userInfo.isNotEmpty ||
            uri.hasFragment) {
          throw const FormatException();
        }
        final headers = <String, String>{};
        for (final header in (operation['requestHeaders'] as List? ?? [])) {
          if (header case {'name': String name, 'value': String value}
              when name.isNotEmpty &&
                  !RegExp(r'[\r\n]').hasMatch('$name$value')) {
            headers[name] = value;
          } else {
            throw const FormatException();
          }
        }
        parts.add((uri: uri, offset: offset, length: length, headers: headers));
      } else {
        throw const FormatException();
      }
    }
    parts.sort((a, b) => a.offset.compareTo(b.offset));
    var offset = 0;
    for (final part in parts) {
      if (part.offset != offset) throw const FormatException();
      offset += part.length;
    }
    if (offset != fileSize) throw const FormatException();
  } catch (_) {
    throw StateError(
      'App Store Connect returned invalid IPA upload operations.',
    );
  }
  return parts;
}
