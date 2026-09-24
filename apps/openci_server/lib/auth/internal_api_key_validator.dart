import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:meta/meta.dart';
import 'package:openci_shared/openci_shared.dart';

class InternalApiKeyValidator {
  const InternalApiKeyValidator() : _environmentForTesting = null;

  @visibleForTesting
  const InternalApiKeyValidator.forTesting({
    required Map<String, String> environment,
  }) : _environmentForTesting = environment;

  final Map<String, String>? _environmentForTesting;

  bool isValid(RequestContext context) {
    final internalApiKey = readInternalApiKey();
    if (internalApiKey == null) return false;

    final token = extractToken(context.request);
    return matchesInternalApiKey(token, internalApiKey);
  }

  @visibleForTesting
  String? readInternalApiKey() {
    final environment = _environmentForTesting ?? Platform.environment;
    final internalApiKey = environment['INTERNAL_API_KEY'];
    if (internalApiKey == null || internalApiKey.isEmpty) return null;
    return internalApiKey;
  }

  @visibleForTesting
  String? extractToken(Request request) {
    final authorization = request.headers['authorization'];
    if (authorization != null && authorization.startsWith('Bearer ')) {
      return authorization.substring(7);
    }
    return request.uri.queryParameters['token'] ??
        request.uri.queryParameters['auth'];
  }

  @visibleForTesting
  bool matchesInternalApiKey(String? token, String internalApiKey) {
    return token != null &&
        token.isNotEmpty &&
        constantTimeCompareString(token, internalApiKey);
  }
}
