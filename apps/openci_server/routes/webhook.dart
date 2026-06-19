import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  Map<String, String> env;
  try {
    env = context.read<Map<String, String>>();
  } catch (_) {
    env = Platform.environment;
  }
  final secret = env['GITHUB_WEBHOOK_SECRET'];
  if (secret == null || secret.isEmpty) {
    stderr.writeln('Warning: GITHUB_WEBHOOK_SECRET is not configured.');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'success': false, 'error': 'Server configuration error'},
    );
  }

  final signatureHeader = context.request.headers['x-hub-signature-256'];
  if (signatureHeader == null || !signatureHeader.startsWith('sha256=')) {
    return Response.json(
      statusCode: HttpStatus.unauthorized,
      body: {'success': false, 'error': 'Missing or invalid signature header'},
    );
  }

  final rawBody = await context.request.body();
  final rawBodyBytes = utf8.encode(rawBody);
  final expectedSignature = signatureHeader.substring(7);

  final key = utf8.encode(secret);
  final hmacSha256 = Hmac(sha256, key);
  final digest = hmacSha256.convert(rawBodyBytes);
  final computedSignature = digest.toString();

  final computedSignatureBytes = utf8.encode(computedSignature);
  final expectedSignatureBytes = utf8.encode(expectedSignature);

  if (!constantTimeCompare(computedSignatureBytes, expectedSignatureBytes)) {
    return Response.json(
      statusCode: HttpStatus.unauthorized,
      body: {'success': false, 'error': 'Signature mismatch'},
    );
  }

  return Response.json(
    body: {'success': true, 'message': 'Signature verified'},
  );
}

bool constantTimeCompare(List<int> a, List<int> b) {
  if (a.length != b.length) {
    return false;
  }

  var result = 0;
  for (var i = 0; i < a.length; i++) {
    result |= a[i] ^ b[i];
  }
  return result == 0;
}
