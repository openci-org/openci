import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

import 'firebase_hosting_client.dart';
import 'firebase_hosting_config.dart';
import 'firebase_hosting_preview.dart';
import 'hosting_files.dart';

/// Firebase Hosting deployments using in-memory service account credentials.
class FirebaseHostingCI {
  FirebaseHostingCI(this._resolveDirectory);

  final String Function(String? dir) _resolveDirectory;

  /// Deploys [publicDirectory] to the existing Hosting site's live channel.
  ///
  /// [serviceAccountJsonBase64] is a Base64-encoded service account JSON key.
  /// The account needs `roles/firebasehosting.admin` on the destination project.
  /// Set [firebaseConfigPath] to read static Hosting settings from firebase.json.
  /// Its path is relative to the workflow directory, or [dir] when supplied.
  /// Hosting arrays are selected by [siteId], or [target] for deploy targets;
  /// a single configuration without a `site` is also accepted. The destination
  /// is always [siteId]; `.firebaserc` and CLI hooks are not used.
  ///
  /// Omit [publicDirectory] to use `hosting.public` relative to the JSON file.
  /// An explicit [publicDirectory] overrides it and is relative to the workflow
  /// directory or [dir]. Absolute file and content paths are accepted.
  ///
  /// Without [firebaseConfigPath], [publicDirectory] is required and [config]
  /// uses the REST API's `ServingConfig` format (rewrites use `glob` and `path`).
  /// A non-empty [config] cannot be combined with [firebaseConfigPath].
  /// Returns the site's `https://SITE_ID.web.app` URL after release succeeds.
  Future<Uri> deploy({
    required String siteId,
    required String serviceAccountJsonBase64,
    String? publicDirectory,
    String? firebaseConfigPath,
    String? target,
    Map<String, Object?> config = const {},
    String? dir,
  }) async => (await _deploy(
    siteId: siteId,
    publicDirectory: publicDirectory,
    firebaseConfigPath: firebaseConfigPath,
    target: target,
    serviceAccountJsonBase64: serviceAccountJsonBase64,
    config: config,
    dir: dir,
  )).url;

  /// Deploys a reusable preview and returns its URL and actual expiry in UTC.
  ///
  /// Pass the result's `url` and `expiresAt` explicitly to `postQrCode` to
  /// display the expiration time in the PR comment. The expiry comes from
  /// Firebase's final channel refresh, rather than the local clock.
  ///
  /// Use a stable [channelId], such as `pr-123`, for each PR. The actual channel
  /// ID is prefixed with `openci-`. Re-deployment refreshes [expiresIn], which
  /// defaults to one hour and must be between one minute and 30 days.
  /// Only one previous release is retained on preview channels.
  ///
  /// [maxPreviewChannels] is the site's preview budget, including other tools'
  /// previews. Expired previews owned by this helper are removed first, then
  /// its least recently updated previews until the new deployment fits. Live
  /// and unowned channels are never removed. Eviction deactivates old URLs.
  /// Serialize preview deployments for each site to enforce the budget across
  /// concurrent runs. Use a different site or increase the budget when unowned
  /// channels occupy all slots. This does not bound bandwidth or total storage.
  ///
  /// Authentication, [firebaseConfigPath], [target], content paths and [config]
  /// work as in [deploy]. The helper does not change Firebase Authentication's
  /// authorized domains.
  Future<FirebaseHostingPreview> deployPreview({
    required String siteId,
    required String channelId,
    required String serviceAccountJsonBase64,
    String? publicDirectory,
    String? firebaseConfigPath,
    String? target,
    Duration expiresIn = const Duration(hours: 1),
    int maxPreviewChannels = 20,
    Map<String, Object?> config = const {},
    String? dir,
  }) async {
    final result = await _deploy(
      siteId: siteId,
      publicDirectory: publicDirectory,
      firebaseConfigPath: firebaseConfigPath,
      target: target,
      serviceAccountJsonBase64: serviceAccountJsonBase64,
      channelId: channelId,
      expiresIn: expiresIn,
      maxPreviewChannels: maxPreviewChannels,
      config: config,
      dir: dir,
    );
    return FirebaseHostingPreview(
      url: result.url,
      expiresAt: result.expiresAt!,
    );
  }

  Future<({Uri url, DateTime? expiresAt})> _deploy({
    required String siteId,
    required String serviceAccountJsonBase64,
    required Map<String, Object?> config,
    String? publicDirectory,
    String? firebaseConfigPath,
    String? target,
    String? channelId,
    Duration expiresIn = const Duration(hours: 1),
    int maxPreviewChannels = 20,
    String? dir,
  }) async {
    validateHostingArguments(siteId, channelId, expiresIn, maxPreviewChannels);
    if (target != null &&
        (target.trim().isEmpty || firebaseConfigPath == null)) {
      throw ArgumentError(
        'target must be non-empty and requires firebaseConfigPath.',
      );
    }
    final workingDirectory = _resolveDirectory(dir);
    File? configFile;
    FirebaseHostingConfig? firebaseConfig;
    if (firebaseConfigPath != null) {
      if (firebaseConfigPath.trim().isEmpty) {
        throw ArgumentError('firebaseConfigPath must not be empty.');
      }
      if (config.isNotEmpty) {
        throw ArgumentError(
          'Use either firebaseConfigPath or config, not both.',
        );
      }
      final file = File(firebaseConfigPath);
      configFile = file.isAbsolute
          ? file
          : File('$workingDirectory/$firebaseConfigPath');
      firebaseConfig = await FirebaseHostingConfig.load(
        configFile,
        siteId: siteId,
        target: target,
      );
    }
    final contentPath = publicDirectory ?? firebaseConfig?.publicDirectory;
    if (contentPath == null || contentPath.trim().isEmpty) {
      throw ArgumentError(
        'Provide publicDirectory or hosting.public in firebase.json.',
      );
    }
    // Reject non-JSON configuration before creating channels or versions, and
    // keep potentially private configuration out of diagnostics.
    final Map<String, dynamic> servingConfig;
    try {
      servingConfig =
          jsonDecode(
                jsonEncode(firebaseConfig?.servingConfig ?? config),
              )
              as Map<String, dynamic>;
    } catch (_) {
      throw ArgumentError('config must contain JSON-compatible ServingConfig.');
    }
    final directory = Directory(contentPath);
    final contentBase = publicDirectory == null
        ? configFile!.parent.path
        : workingDirectory;
    final content = directory.isAbsolute
        ? directory
        : Directory('$contentBase/$contentPath');
    final credentials = _credentials(serviceAccountJsonBase64);
    final files = await HostingFiles.prepare(
      content,
      ignore: firebaseConfig?.ignore ?? const [],
    );
    final baseClient = _NoRedirectClient(http.Client());
    AutoRefreshingAuthClient? client;
    try {
      try {
        client = await clientViaServiceAccount(
          credentials,
          ['https://www.googleapis.com/auth/firebase.hosting'],
          baseClient: baseClient,
        ).timeout(const Duration(seconds: 60));
      } catch (_) {
        throw StateError(
          'Could not authenticate the Firebase service account.',
        );
      }
      final result = await FirebaseHostingClient(client).deploy(
        siteId: siteId,
        files: files.files,
        config: servingConfig,
        channelId: channelId == null ? null : 'openci-$channelId',
        expiresIn: expiresIn,
        maxPreviewChannels: maxPreviewChannels,
      );
      stdout.writeln('Firebase Hosting deployment complete: ${result.url}');
      return result;
    } finally {
      client?.close();
      baseClient.close();
      await files.close();
    }
  }
}

ServiceAccountCredentials _credentials(String value) {
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
    // Key parsing errors may contain the supplied secret.
  }
  throw const FormatException(
    'serviceAccountJsonBase64 must contain a valid service account JSON key.',
  );
}

class _NoRedirectClient extends http.BaseClient {
  _NoRedirectClient(this._inner);
  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.followRedirects = false;
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}
