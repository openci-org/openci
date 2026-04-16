import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dart_functions/github/webhook_verifier.dart';
import 'package:test/test.dart';

String _generateSignature(String payload, String secret) {
  final hmac = Hmac(sha256, utf8.encode(secret));
  final digest = hmac.convert(utf8.encode(payload));
  return 'sha256=$digest';
}

void main() {
  const secret = 'test-webhook-secret';
  const payload = '{"action":"opened","repository":{"full_name":"org/repo"}}';

  group('verifySignature', () {
    test('returns true for valid signature', () {
      final signature = _generateSignature(payload, secret);

      expect(
        verifySignature(
          payload: payload,
          signatureHeader: signature,
          secret: secret,
        ),
        isTrue,
      );
    });

    test('returns false for invalid signature', () {
      expect(
        verifySignature(
          payload: payload,
          signatureHeader: 'sha256=invalid',
          secret: secret,
        ),
        isFalse,
      );
    });

    test('returns false when sha256= prefix is missing', () {
      final hmac = Hmac(sha256, utf8.encode(secret));
      final digest = hmac.convert(utf8.encode(payload));

      expect(
        verifySignature(
          payload: payload,
          signatureHeader: digest.toString(),
          secret: secret,
        ),
        isFalse,
      );
    });

    test('returns false when secret is wrong', () {
      final signature = _generateSignature(payload, 'wrong-secret');

      expect(
        verifySignature(
          payload: payload,
          signatureHeader: signature,
          secret: secret,
        ),
        isFalse,
      );
    });

    test('returns false when payload is tampered', () {
      final signature = _generateSignature(payload, secret);

      expect(
        verifySignature(
          payload: '{"action":"tampered"}',
          signatureHeader: signature,
          secret: secret,
        ),
        isFalse,
      );
    });

    test('works with empty payload', () {
      final signature = _generateSignature('', secret);

      expect(
        verifySignature(
          payload: '',
          signatureHeader: signature,
          secret: secret,
        ),
        isTrue,
      );
    });
  });

  group('verifyWebhook', () {
    test('returns null for valid signature', () async {
      final signature = _generateSignature(payload, secret);

      final result = await verifyWebhook(
        payload: payload,
        headers: {'x-hub-signature-256': signature},
        secret: secret,
      );

      expect(result, isNull);
    });

    test('returns 401 when signature header is missing', () async {
      final result = await verifyWebhook(
        payload: payload,
        headers: {},
        secret: secret,
      );

      expect(result?.statusCode, 401);
    });

    test('returns 401 for invalid signature', () async {
      final result = await verifyWebhook(
        payload: payload,
        headers: {'x-hub-signature-256': 'sha256=invalid'},
        secret: secret,
      );

      expect(result?.statusCode, 401);
    });
  });
}
