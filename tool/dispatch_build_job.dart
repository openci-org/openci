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
  final parsedUserId =
      Platform.environment['USER_ID'] ??
      Platform.environment['USER_UID'] ??
      args
          .firstWhere((arg) => arg.startsWith('--user-id='), orElse: () => '')
          .replaceFirst('--user-id=', '')
          .trim();
  final userId = parsedUserId.isNotEmpty ? parsedUserId : 'test-uid';

  final parsedTeamId =
      Platform.environment['TEAM_ID'] ??
      args
          .firstWhere((arg) => arg.startsWith('--team-id='), orElse: () => '')
          .replaceFirst('--team-id=', '')
          .trim();
  final teamId = parsedTeamId.isNotEmpty ? parsedTeamId : 'test-team';
  final customScript =
      Platform.environment['CUSTOM_SCRIPT'] ??
      (args
              .where(
                (a) =>
                    !a.startsWith('--user-id=') && !a.startsWith('--team-id='),
              )
              .isNotEmpty
          ? args
                .where(
                  (a) =>
                      !a.startsWith('--user-id=') &&
                      !a.startsWith('--team-id='),
                )
                .join(' ')
          : null);

  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final commitSha = 'sha-${timestamp.toString().substring(5)}';
  final commitMessage =
      'feat: 🎉 Build job dispatched at ${DateTime.now().toIso8601String().substring(11, 19)}';

  print(
    '🚀 Step 1: Creating test build job via API ($serverUrl/internal/seed/jobs)...',
  );

  try {
    final payload = <String, dynamic>{
      if (customScript != null && customScript.isNotEmpty)
        'customScript': customScript,
      'userId': userId,
      if (teamId.isNotEmpty) 'teamId': teamId,
      'commitSha': commitSha,
      'commitMessage': commitMessage,
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

  final deliveryId = 'delivery-$timestamp';
  final payload = {
    'ref': 'refs/heads/main',
    'repository': {
      'name': 'openci',
      'owner': {'login': 'openci-org'},
    },
    'installation': {'id': 12345678},
    'head_commit': {
      'id': commitSha,
      'message': commitMessage,
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
