import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;

import '../../app_store_connect_keys.dart';

class AppStoreConnectClient {
  AppStoreConnectClient(this._keys)
    : _privateKey = _decodeKey(_keys),
      _client = http.Client();

  final AppStoreConnectKeys _keys;
  final ECPrivateKey _privateKey;
  final http.Client _client;

  Future<Map<String, dynamic>> request(
    String method,
    String path,
    String action, {
    Map<String, String>? query,
    Map<String, Object?>? body,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final String token;
    try {
      token =
          JWT(
            {'iss': _keys.issuerId, 'aud': 'appstoreconnect-v1'},
            header: {'kid': _keys.keyId},
          ).sign(
            _privateKey,
            algorithm: JWTAlgorithm.ES256,
            expiresIn: const Duration(minutes: 15),
          );
    } catch (_) {
      throw StateError('Could not sign the App Store Connect API token.');
    }
    final request = http.Request(
      method,
      Uri.https('api.appstoreconnect.apple.com', path, query),
    )..headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final response = await _send(request, action, timeout);
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) return body;
    } on FormatException {
      // Raw responses may contain private request data.
    }
    throw StateError('App Store Connect returned an invalid $action response.');
  }

  Future<void> uploadPart({
    required File ipa,
    required Uri uri,
    required int offset,
    required int length,
    required Map<String, String> headers,
    required Duration timeout,
  }) async {
    // Storage URLs use Apple's upload headers, never the App Store API JWT.
    await _send(
      _IpaPartRequest(uri, ipa, offset, length)..headers.addAll(headers),
      'upload IPA bytes',
      timeout,
    );
  }

  Future<http.Response> _send(
    http.BaseRequest request,
    String action,
    Duration timeout,
  ) async {
    request.followRedirects = false;
    final http.Response response;
    try {
      response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
    } on TimeoutException {
      throw TimeoutException('App Store Connect $action timed out.');
    } catch (_) {
      // Avoid logging JWTs, signed upload URLs, or response bodies.
      throw StateError('App Store Connect $action request failed.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'App Store Connect $action failed (HTTP ${response.statusCode}).',
      );
    }
    return response;
  }

  void close() => _client.close();
}

ECPrivateKey _decodeKey(AppStoreConnectKeys keys) {
  if (keys.issuerId.trim().isEmpty || keys.keyId.trim().isEmpty) {
    throw ArgumentError('App Store Connect issuerId and keyId are required.');
  }
  try {
    final key = ECPrivateKey(utf8.decode(base64Decode(keys.privateKeyBase64)));
    if (key.toJWK()['crv'] == 'P-256') return key;
  } catch (_) {
    // Key parsing errors can contain the supplied secret.
  }
  throw const FormatException(
    'App Store Connect privateKeyBase64 must contain a Base64-encoded '
    'P-256 private key.',
  );
}

class _IpaPartRequest extends http.BaseRequest {
  _IpaPartRequest(Uri uri, this.ipa, this.offset, int length)
    : super('PUT', uri) {
    contentLength = length;
  }

  final File ipa;
  final int offset;

  @override
  http.ByteStream finalize() {
    super.finalize();
    return http.ByteStream(ipa.openRead(offset, offset + contentLength!));
  }
}
