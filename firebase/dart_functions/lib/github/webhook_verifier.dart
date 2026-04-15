import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';

Future<Response?> verifyWebhook({
  required String payload,
  required Map<String, String> headers,
  required String secret,
}) async {
  final signature = headers['x-hub-signature-256'];
  if (signature == null) {
    return Response(401, body: '{"error": "Missing signature"}');
  }

  final valid = verifySignature(
    payload: payload,
    signatureHeader: signature,
    secret: secret,
  );

  if (!valid) {
    return Response(401, body: '{"error": "Invalid signature"}');
  }

  return null;
}

bool verifySignature({
  required String payload,
  required String signatureHeader,
  required String secret,
}) {
  if (!signatureHeader.startsWith('sha256=')) {
    return false;
  }

  final expectedSignature = signatureHeader.substring('sha256='.length);
  final hmac = Hmac(sha256, utf8.encode(secret));
  final digest = hmac.convert(utf8.encode(payload));
  final computedSignature = digest.toString();

  if (expectedSignature.length != computedSignature.length) {
    return false;
  }

  var result = 0;
  for (var i = 0; i < expectedSignature.length; i++) {
    result |= expectedSignature.codeUnitAt(i) ^ computedSignature.codeUnitAt(i);
  }

  return result == 0;
}
