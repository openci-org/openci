import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

void main(List<String> args) async {
  final serverUrl =
      Platform.environment['OPENCI_SERVER_URL'] ?? 'http://localhost:8080';
  final webhookSecret =
      Platform.environment['GITHUB_WEBHOOK_SECRET'] ??
      'your-github-webhook-secret-here';
  final customScript =
      Platform.environment['CUSTOM_SCRIPT'] ??
      (args.isNotEmpty ? args.join(' ') : null);

  print(
    '🚀 Step 1: Creating test build job via API ($serverUrl/internal/seed/jobs)...',
  );

  try {
    final payload = <String, dynamic>{
      if (customScript != null && customScript.isNotEmpty)
        'customScript': customScript,
    };

    final response = await http.post(
      Uri.parse('$serverUrl/internal/seed/jobs'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      print('✅ Test build job created successfully via API.');
      print('   Body: ${response.body}');
    } else {
      print('❌ Failed to create test build job via API!');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');
    }
  } catch (e, st) {
    print('❌ Error connecting to openci-server API: $e');
    print(st);
  }

  print(
    '\n🚀 Step 2: Dispatching GitHub Push Webhook to $serverUrl/webhook...',
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
