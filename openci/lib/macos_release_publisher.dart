import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

const releaseBucket = 'openci-b1b91-releases';
const releasePrefix = 'macos/stable';
const releaseFeedObject = '$releasePrefix/appcast.xml';

Uri releaseUrl(String object) => Uri.https(
  'storage.googleapis.com',
  '/$releaseBucket/$object',
);

String archiveObject(int buildNumber, String fileName) =>
    '$releasePrefix/releases/$buildNumber/$fileName';

/// Publishes the immutable archive before advancing the public update feed.
///
/// Generation preconditions prevent concurrent/older jobs from replacing a
/// newer feed. The authenticated client is used only with Google's storage API;
/// the separate public client confirms users can download the archive.
class MacosReleasePublisher {
  MacosReleasePublisher(this.client, this.publicClient);

  final http.Client client;
  final http.Client publicClient;

  Future<bool> publish({
    required File archive,
    required String appcast,
    required int buildNumber,
    required String version,
  }) async {
    if (buildNumber <= 0) throw ArgumentError('Invalid build number.');
    final fileName = archive.uri.pathSegments.last;
    if (!RegExp(r'^OpenCI-[0-9A-Za-z.+-]+\.zip$').hasMatch(fileName)) {
      throw ArgumentError('Invalid release archive filename.');
    }
    final object = archiveObject(buildNumber, fileName);
    final url = releaseUrl(object);
    final size = await archive.length();
    if (size == 0) throw StateError('Release archive is empty.');
    validateAppcast(
      appcast,
      buildNumber: buildNumber,
      archiveUrl: url,
      archiveLength: size,
    );
    final hash = (await sha256.bind(archive.openRead()).first).toString();

    var current = await _currentFeed();
    if (current.build >= buildNumber) return false;
    await _uploadArchive(archive, object, size, hash);
    final check = await _send(
      publicClient,
      http.Request('HEAD', url),
      'check public archive',
    );
    if (check.statusCode != 200 || check.headers['content-length'] != '$size') {
      throw StateError('Published archive is not publicly downloadable.');
    }

    for (var attempt = 0; attempt < 4; attempt++) {
      if (current.build >= buildNumber) return false;
      final boundary = 'openci-${DateTime.now().microsecondsSinceEpoch}';
      final metadata = jsonEncode({
        'name': releaseFeedObject,
        'contentType': 'application/xml; charset=utf-8',
        'cacheControl': 'no-cache, max-age=0, must-revalidate',
        'metadata': {'buildNumber': '$buildNumber', 'version': version},
      });
      final request =
          http.Request(
              'POST',
              _uploadUri(releaseFeedObject, {
                'uploadType': 'multipart',
                'ifGenerationMatch': current.generation,
              }),
            )
            ..headers['content-type'] = 'multipart/related; boundary=$boundary'
            ..body =
                '--$boundary\r\nContent-Type: application/json; charset=utf-8'
                '\r\n\r\n$metadata\r\n--$boundary\r\n'
                'Content-Type: application/xml; charset=utf-8\r\n\r\n'
                '$appcast\r\n--$boundary--\r\n';
      final response = await _send(client, request, 'publish appcast');
      if (response.statusCode == 412) {
        current = await _currentFeed();
        continue;
      }
      _requireSuccess(response, 'publish appcast');
      return true;
    }
    throw StateError('Appcast changed repeatedly; retry with a new run.');
  }

  Future<({String generation, int build})> _currentFeed() async {
    final response = await _send(
      client,
      http.Request('GET', _metadataUri(releaseFeedObject)),
      'read current appcast metadata',
    );
    if (response.statusCode == 404) return (generation: '0', build: 0);
    _requireSuccess(response, 'read current appcast metadata');
    final body = _json(response);
    final generation = body['generation'];
    final metadata = body['metadata'];
    final value = metadata is Map ? metadata['buildNumber'] : null;
    final build = value is String ? int.tryParse(value) : null;
    if (generation is String && RegExp(r'^[1-9][0-9]*$').hasMatch(generation)) {
      if (build != null && build >= 0) {
        return (generation: generation, build: build);
      }
      if (value == null && await _isEmptyBootstrapFeed(generation)) {
        return (generation: generation, build: 0);
      }
    }
    throw StateError('Existing appcast has no valid release metadata.');
  }

  Future<bool> _isEmptyBootstrapFeed(String generation) async {
    final url = _metadataUri(releaseFeedObject).replace(
      queryParameters: {'alt': 'media', 'generation': generation},
    );
    final response = await _send(
      client,
      http.Request('GET', url),
      'read initial appcast',
    );
    _requireSuccess(response, 'read initial appcast');
    final rss = XmlDocument.parse(utf8.decode(response.bodyBytes)).rootElement;
    final channel = rss.findElements('channel').singleOrNull;
    return rss.name.qualified == 'rss' &&
        rss.getAttribute('version') == '2.0' &&
        channel?.getElement('title')?.innerText == 'OpenCI for macOS' &&
        !rss.descendants.whereType<XmlElement>().any(
          (element) => element.name.local == 'item',
        );
  }

  Future<void> _uploadArchive(
    File archive,
    String object,
    int size,
    String hash,
  ) async {
    final reservation = await _send(
      client,
      http.Request(
          'POST',
          _uploadUri(object, {
            'uploadType': 'resumable',
            'ifGenerationMatch': '0',
          }),
        )
        ..headers.addAll({
          'content-type': 'application/json',
          'x-upload-content-type': 'application/zip',
          'x-upload-content-length': '$size',
        })
        ..body = jsonEncode({
          'name': object,
          'contentType': 'application/zip',
          'cacheControl': 'public, max-age=31536000, immutable',
          'metadata': {'sha256': hash},
        }),
      'start archive upload',
    );
    if (reservation.statusCode == 412) {
      await _verifyArchive(object, size, hash);
      return;
    }
    _requireSuccess(reservation, 'start archive upload');
    final location = Uri.tryParse(reservation.headers['location'] ?? '');
    if (location == null ||
        location.scheme != 'https' ||
        location.authority != 'storage.googleapis.com' ||
        !location.path.startsWith('/upload/') ||
        location.userInfo.isNotEmpty) {
      throw StateError('Storage returned an invalid upload location.');
    }
    final request = _ArchiveRequest(location, archive, size);
    final response = await _send(
      client,
      request,
      'upload archive',
      timeout: const Duration(minutes: 20),
    );
    _requireSuccess(response, 'upload archive');
    await _verifyArchive(object, size, hash);
  }

  Future<void> _verifyArchive(String object, int size, String hash) async {
    final response = await _send(
      client,
      http.Request('GET', _metadataUri(object)),
      'verify archive metadata',
    );
    _requireSuccess(response, 'verify archive metadata');
    final data = _json(response);
    final metadata = data['metadata'];
    if (data['size'] != '$size' ||
        metadata is! Map ||
        metadata['sha256'] != hash) {
      throw StateError('This build number already has a different archive.');
    }
  }

  Uri _metadataUri(String object) => Uri(
    scheme: 'https',
    host: 'storage.googleapis.com',
    pathSegments: ['storage', 'v1', 'b', releaseBucket, 'o', object],
  );

  Uri _uploadUri(String object, Map<String, String> query) => Uri.https(
    'storage.googleapis.com',
    '/upload/storage/v1/b/$releaseBucket/o',
    {'name': object, ...query},
  );
}

void validateAppcast(
  String source, {
  required int buildNumber,
  required Uri archiveUrl,
  required int archiveLength,
}) {
  final document = XmlDocument.parse(source);
  final items = document.findAllElements('item').toList();
  if (items.length != 1) {
    throw StateError('Expected exactly one release in the new appcast.');
  }
  final item = items.single;
  final enclosure = item.getElement('enclosure');
  const namespace = 'http://www.andymatuschak.org/xml-namespaces/sparkle';
  final signature = enclosure?.getAttribute(
    'edSignature',
    namespace: namespace,
  );
  final version = item.getElement('version', namespace: namespace)?.innerText;
  if (version != '$buildNumber' ||
      enclosure?.getAttribute('url') != archiveUrl.toString() ||
      enclosure?.getAttribute('length') != '$archiveLength' ||
      signature == null ||
      base64Decode(signature).length != 64) {
    throw StateError('Appcast does not match the signed release archive.');
  }
}

Future<http.Response> _send(
  http.Client client,
  http.BaseRequest request,
  String operation, {
  Duration timeout = const Duration(seconds: 60),
}) async {
  request.followRedirects = false;
  try {
    return await client
        .send(request)
        .then(http.Response.fromStream)
        .timeout(timeout);
  } catch (_) {
    // OAuth failures and resumable-upload URLs must not appear in build logs.
    throw StateError('Cloud Storage could not $operation.');
  }
}

void _requireSuccess(http.Response response, String operation) {
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw StateError(
      'Cloud Storage $operation failed (HTTP ${response.statusCode}).',
    );
  }
}

Map<String, dynamic> _json(http.Response response) {
  try {
    final data = jsonDecode(response.body);
    if (data is Map<String, dynamic>) return data;
  } catch (_) {
    // Keep arbitrary remote responses out of logs.
  }
  throw StateError('Cloud Storage returned invalid metadata.');
}

class _ArchiveRequest extends http.BaseRequest {
  _ArchiveRequest(Uri uri, this.archive, int size) : super('PUT', uri) {
    contentLength = size;
    headers['content-type'] = 'application/zip';
  }
  final File archive;

  @override
  http.ByteStream finalize() {
    super.finalize();
    return http.ByteStream(archive.openRead());
  }
}
