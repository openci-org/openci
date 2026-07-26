import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

void main() async {
  final serverUrl =
      Platform.environment['OPENCI_SERVER_URL'] ?? 'http://localhost:8080';
  final webhookSecret =
      Platform.environment['GITHUB_WEBHOOK_SECRET'] ??
      'your-github-webhook-secret-here';

  print('🌱 Step 1: Ensuring test team via API ($serverUrl/internal/seed)...');

  try {
    final seedResponse = await http.post(
      Uri.parse('$serverUrl/internal/seed'),
    );

    if (seedResponse.statusCode >= 200 && seedResponse.statusCode < 300) {
      print('✅ Test team configured successfully via API.');
    } else {
      print('❌ Failed to configure test team via API!');
      print('   Status: ${seedResponse.statusCode}');
      print('   Body: ${seedResponse.body}');
      exit(1);
    }
  } catch (e, st) {
    print('❌ Error connecting to openci-server API: $e');
    print(st);
    exit(1);
  }

  print(
    '\n🌱 Step 2: Dispatching GitHub Push Webhook to $serverUrl/webhook...',
  );

  final deliveryId = 'delivery-${DateTime.now().millisecondsSinceEpoch}';
  final payload = {
    'ref': 'refs/heads/main',
    'repository': {
      'name': 'openci',
      'owner': {'login': 'openci-org'},
    },
    'installation': {'id': 12345678},
    'head_commit': {
      'id': 'main',
      'message': 'feat: 🎉 Hello World from OpenCI Local Orchard via API!',
    },
  };

  final rawBody = jsonEncode(payload);

  // Calculate HMAC SHA-256 signature
  final hmac = Hmac(sha256, utf8.encode(webhookSecret));
  final digest = hmac.convert(utf8.encode(rawBody));
  final signature = 'sha256=$digest';

  try {
    final response = await http.post(
      Uri.parse('$serverUrl/webhook'),
      headers: {
        'Content-Type': 'application/json',
        'X-GitHub-Event': 'push',
        'X-GitHub-Delivery': deliveryId,
        'X-Hub-Signature-256': signature,
      },
      body: rawBody,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      print('✅ Webhook dispatched successfully!');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');
      print('   Delivery ID: $deliveryId');
    } else {
      print('❌ Failed to dispatch webhook!');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');
    }
  } catch (e, st) {
    print('❌ Error sending webhook HTTP request: $e');
    print(st);
  }
}
