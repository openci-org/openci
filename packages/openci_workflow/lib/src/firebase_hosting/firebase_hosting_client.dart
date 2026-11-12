import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'hosting_files.dart';

const _managedLabel = 'openci-workflow';
final _id = RegExp(r'^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?$');

void validateHostingArguments(
  String siteId,
  String? channelId,
  Duration expiresIn,
  int maxPreviewChannels,
) {
  if (!_id.hasMatch(siteId)) {
    throw ArgumentError('siteId must be a valid Hosting site ID.');
  }
  if (channelId == null) return;
  if (channelId == 'live' || !_id.hasMatch('openci-$channelId')) {
    throw ArgumentError('channelId must be a non-live lowercase channel ID.');
  }
  if (expiresIn < const Duration(minutes: 1) ||
      expiresIn > const Duration(days: 30)) {
    throw ArgumentError('expiresIn must be between one minute and 30 days.');
  }
  if (maxPreviewChannels < 1 || maxPreviewChannels > 100) {
    throw ArgumentError('maxPreviewChannels must be between 1 and 100.');
  }
}

/// Internal Hosting protocol implementation with an authenticated client.
class FirebaseHostingClient {
  FirebaseHostingClient(
    this._client, {
    this.requestTimeout = const Duration(seconds: 60),
    this.uploadTimeout = const Duration(minutes: 10),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final http.Client _client;
  final Duration requestTimeout;
  final Duration uploadTimeout;
  final DateTime Function() _now;

  Future<Uri> deploy({
    required String siteId,
    required List<HostingFile> files,
    Map<String, Object?> config = const {},
    String? channelId,
    Duration expiresIn = const Duration(hours: 1),
    int maxPreviewChannels = 20,
  }) async {
    var channel = channelId == null
        ? null
        : await _preview(siteId, channelId, expiresIn, maxPreviewChannels);
    final created = await _json(
      'POST',
      'sites/$siteId/versions',
      body: {
        'config': config,
      },
    );
    final version = _resource(created['name'], siteId, 'versions');
    var releaseAttempted = false;
    try {
      final byHash = {for (final file in files) file.hash: file};
      final uploaded = <String>{};
      for (var offset = 0; offset < files.length; offset += 1000) {
        final batch = files.sublist(offset, min(offset + 1000, files.length));
        final response = await _json(
          'POST',
          '$version:populateFiles',
          body: {
            'files': {for (final file in batch) file.path: file.hash},
          },
        );
        final requiredHashes = response['uploadRequiredHashes'] ?? <Object>[];
        final batchHashes = batch.map((file) => file.hash).toSet();
        if (requiredHashes is! List ||
            requiredHashes.any(
              (h) => h is! String || !batchHashes.contains(h),
            )) {
          throw StateError('Firebase returned invalid Hosting file hashes.');
        }
        if (requiredHashes.isEmpty) continue;
        final expectedUrl = Uri.https(
          'upload-firebasehosting.googleapis.com',
          '/upload/$version/files',
        );
        final uploadUrl = response['uploadUrl'];
        if (uploadUrl is! String || Uri.tryParse(uploadUrl) != expectedUrl) {
          throw StateError('Firebase returned an invalid Hosting upload URL.');
        }
        final pending = requiredHashes
            .cast<String>()
            .toSet()
            .difference(uploaded)
            .toList();
        // Wait for all in-flight requests before removing the snapshots.
        for (var i = 0; i < pending.length; i += 4) {
          await Future.wait([
            for (final hash in pending.sublist(i, min(i + 4, pending.length)))
              _upload(Uri.parse('$expectedUrl/$hash'), byHash[hash]!),
          ]);
        }
        uploaded.addAll(pending);
      }
      final finalized = await _json(
        'PATCH',
        version,
        query: {'updateMask': 'status'},
        body: {'status': 'FINALIZED'},
      );
      if (_resource(finalized['name'], siteId, 'versions') != version ||
          finalized['status'] != 'FINALIZED') {
        throw StateError('Firebase did not finalize the Hosting version.');
      }
      if (channel != null) {
        final name = channel['name'];
        channel = await _updatePreview(channel, expiresIn, siteId);
        if (channel['name'] != name) {
          throw StateError('Firebase returned an invalid preview channel.');
        }
      }
      final url = channel == null
          ? Uri.https('$siteId.web.app', '')
          : _previewUrl(channel['url'], siteId);
      releaseAttempted = true;
      final released = await _json(
        'POST',
        channel == null
            ? 'sites/$siteId/releases'
            : '${channel['name']}/releases',
        query: {'versionName': version},
        body: {},
      );
      if (released['version'] is! Map ||
          _resource((released['version'] as Map)['name'], siteId, 'versions') !=
              version ||
          ![null, 'DEPLOY', 'TYPE_UNSPECIFIED'].contains(released['type'])) {
        throw StateError('Firebase returned an invalid Hosting release.');
      }
      return url;
    } catch (_) {
      // A lost release response may already have published this version.
      if (!releaseAttempted) {
        try {
          await _send('DELETE', _uri(version));
        } catch (_) {
          // Preserve the original failure; cleanup is best effort.
        }
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _preview(
    String siteId,
    String channelId,
    Duration ttl,
    int budget,
  ) async {
    final name = 'sites/$siteId/channels/$channelId';
    final channels = await _channels(siteId);
    final current = channels[name];
    if (current != null && !_managed(current, siteId)) {
      throw StateError('The requested preview channel is not owned by OpenCI.');
    }
    final others = channels.values
        .where(
          (c) =>
              c['name'] != name && c['name'] != 'sites/$siteId/channels/live',
        )
        .toList();
    final owned = others.where((c) => _managed(c, siteId)).toList()
      ..sort((a, b) => _updated(a).compareTo(_updated(b)));
    final expired = owned.where((c) {
      final expires = _time(c['expireTime']);
      return expires != null && !expires.isAfter(_now());
    }).toList();
    // Check that the budget is achievable before deleting anything.
    if (others.length - owned.length + 1 > budget) {
      throw StateError(
        'Unmanaged Hosting previews fill maxPreviewChannels. '
        'Use another site, remove those previews, or increase the budget.',
      );
    }
    for (final candidate in expired) {
      await _deletePreview(candidate['name'] as String);
      others.remove(candidate);
      owned.remove(candidate);
    }
    while (others.length + 1 > budget) {
      final candidate = owned.removeAt(0);
      await _deletePreview(candidate['name'] as String);
      others.remove(candidate);
    }
    Map<String, dynamic> result;
    if (current != null) {
      result = await _updatePreview(current, ttl, siteId);
    } else {
      try {
        result = await _json(
          'POST',
          'sites/$siteId/channels',
          query: {'channelId': channelId},
          body: {
            'ttl': '${ttl.inSeconds}s',
            'retainedReleaseCount': 1,
            'labels': {_managedLabel: 'preview'},
          },
        );
      } on _HostingHttpException catch (error) {
        if (error.status != 409) rethrow;
        // Reuse a channel created concurrently only if it belongs to OpenCI.
        final existing = _normalizeChannel(await _json('GET', name), siteId);
        if (existing['name'] != name || !_managed(existing, siteId)) {
          throw StateError(
            'The requested preview channel is not owned by OpenCI.',
          );
        }
        result = await _updatePreview(existing, ttl, siteId);
      }
    }
    result = _normalizeChannel(result, siteId);
    if (result['name'] != name) {
      throw StateError('Firebase returned an invalid preview channel.');
    }
    _previewUrl(result['url'], siteId);
    return result;
  }

  Future<Map<String, Map<String, dynamic>>> _channels(String siteId) async {
    final channels = <String, Map<String, dynamic>>{};
    final tokens = <String>{};
    String? token;
    do {
      final page = await _json(
        'GET',
        'sites/$siteId/channels',
        query: {
          'pageSize': '100',
          'pageToken': ?token,
        },
      );
      final items = page['channels'] ?? <Object>[];
      if (items is! List) {
        throw StateError('Firebase returned an invalid preview channel list.');
      }
      for (final item in items) {
        if (item is! Map<String, dynamic>) {
          throw StateError('Firebase returned an invalid preview channel.');
        }
        final channel = _normalizeChannel(item, siteId);
        channels[channel['name'] as String] = channel;
      }
      final next = page['nextPageToken'];
      if (next != null && next is! String) {
        throw StateError('Firebase returned invalid channel pagination.');
      }
      token = next as String?;
      if (token != null &&
          token.isNotEmpty &&
          (!tokens.add(token) || tokens.length > 100)) {
        throw StateError('Firebase repeated or exceeded channel pagination.');
      }
    } while (token != null && token.isNotEmpty);
    return channels;
  }

  bool _managed(Map<String, dynamic> channel, String siteId) =>
      channel['name'] is String &&
      (channel['name'] as String).startsWith(
        'sites/$siteId/channels/openci-',
      ) &&
      channel['labels'] is Map &&
      (channel['labels'] as Map)[_managedLabel] == 'preview';

  DateTime? _time(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  DateTime _updated(Map<String, dynamic> channel) =>
      _time(channel['updateTime']) ??
      _time(channel['createTime']) ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  Future<Map<String, dynamic>> _updatePreview(
    Map<String, dynamic> channel,
    Duration ttl,
    String siteId,
  ) async => _normalizeChannel(
    await _json(
      'PATCH',
      channel['name'] as String,
      query: {'updateMask': 'ttl,retainedReleaseCount,labels'},
      body: {
        'ttl': '${ttl.inSeconds}s',
        'retainedReleaseCount': 1,
        // Patch can implicitly recreate an expired channel. Preserve ownership
        // in that case, and retain any additional labels on an existing channel.
        'labels': {
          ...(channel['labels'] as Map? ?? {}),
          _managedLabel: 'preview',
        },
      },
    ),
    siteId,
  );

  // Hosting supports both site aliases and fully qualified project resources.
  // Normalize only after verifying that the returned resource is in this site.
  String _resource(Object? value, String siteId, String kind) {
    final match = value is String
        ? RegExp(
            '^(?:projects/[a-zA-Z0-9_-]+/)?(sites/$siteId/$kind/[a-zA-Z0-9_-]+)\$',
          ).firstMatch(value)
        : null;
    if (match == null) {
      throw StateError('Firebase returned an invalid Hosting resource.');
    }
    return match.group(1)!;
  }

  Map<String, dynamic> _normalizeChannel(
    Map<String, dynamic> channel,
    String siteId,
  ) => {
    ...channel,
    'name': _resource(channel['name'], siteId, 'channels'),
  };

  Future<void> _deletePreview(String name) async {
    try {
      await _send('DELETE', _uri(name));
    } on _HostingHttpException catch (error) {
      if (error.status != 404) rethrow;
    }
  }

  Uri _previewUrl(Object? value, String siteId) {
    final url = value is String ? Uri.tryParse(value) : null;
    if (url == null ||
        url.scheme != 'https' ||
        !url.host.startsWith('$siteId--') ||
        !url.host.endsWith('.web.app') ||
        url.userInfo.isNotEmpty ||
        url.hasPort ||
        url.hasQuery ||
        url.hasFragment ||
        (url.path.isNotEmpty && url.path != '/')) {
      throw StateError('Firebase returned an invalid Hosting preview URL.');
    }
    return url;
  }

  Future<void> _upload(Uri url, HostingFile file) async {
    final request = http.StreamedRequest('POST', url)
      ..followRedirects = false
      ..headers['content-type'] = 'application/octet-stream'
      ..contentLength = await file.compressed.length();
    Future<void> send() async {
      final response = _client.send(request);
      final write = file.compressed.openRead().pipe(request.sink);
      await Future.wait<void>([
        write,
        () async {
          final result = await response;
          await result.stream.drain<void>();
          _checkStatus(result.statusCode);
        }(),
      ]);
    }

    try {
      await send().timeout(uploadTimeout);
    } on TimeoutException {
      throw TimeoutException('Firebase Hosting file upload timed out.');
    } on http.ClientException {
      throw StateError('Firebase Hosting file upload failed.');
    }
  }

  Future<Map<String, dynamic>> _json(
    String method,
    String resource, {
    Map<String, String>? query,
    Map<String, Object?>? body,
  }) async {
    final response = await _send(method, _uri(resource, query), body: body);
    try {
      final value = jsonDecode(response.body);
      if (value is Map<String, dynamic>) return value;
    } catch (_) {
      // Raw responses may contain secrets or signed URLs.
    }
    throw StateError('Firebase returned invalid Hosting JSON.');
  }

  Uri _uri(String resource, [Map<String, String>? query]) =>
      Uri.https('firebasehosting.googleapis.com', '/v1beta1/$resource', query);

  Future<http.Response> _send(
    String method,
    Uri url, {
    Map<String, Object?>? body,
  }) async {
    final request = http.Request(method, url)..followRedirects = false;
    if (body != null) {
      request.headers['content-type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final http.Response response;
    try {
      response = await (() async => http.Response.fromStream(
        await _client.send(request),
      ))().timeout(requestTimeout);
    } on TimeoutException {
      throw TimeoutException('Firebase Hosting request timed out.');
    } on http.ClientException {
      throw StateError('Firebase Hosting request failed.');
    }
    _checkStatus(response.statusCode);
    return response;
  }

  void _checkStatus(int status) {
    if (status < 200 || status >= 300) {
      throw _HostingHttpException(status);
    }
  }
}

class _HostingHttpException extends HttpException {
  _HostingHttpException(this.status)
    : super('Firebase Hosting request failed (HTTP $status).');

  final int status;
}
