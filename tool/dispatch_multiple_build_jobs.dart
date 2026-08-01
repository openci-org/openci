import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'dart:math';

Future<void> dispatchSingleJob({
  required int index,
  required String serverUrl,
  required String webhookSecret,
  required String userId,
  required String teamId,
}) async {
  final now = DateTime.now();
  final uniqueId = '${now.microsecondsSinceEpoch}_$index';
  final commitSha = 'sha-${uniqueId.substring(uniqueId.length - 8)}-$index';
  final commitMessage =
      'feat: 🚀 Concurrent job #$index dispatched at ${now.toIso8601String().substring(11, 19)}';

  final workflowYaml =
      '''
name: Concurrent Test Workflow #$index
on:
  push:
    branches: [ main ]

jobs:
  build:
    name: Concurrent Build Job #$index
    runs-on: macos-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Execute Step 1 for Job #$index
        run: |
          echo "🚀 [Job #$index] Step 1 initializing..."
          sleep 2

      - name: Execute Step 2 for Job #$index
        run: |
          echo "📦 [Job #$index] Step 2 compiling..."
          sleep 3

      - name: Finish Job #$index
        run: |
          echo "✅ [Job #$index] Build finished successfully!"
''';

  // Step 1: Seed build job in openci-server
  final seedPayload = <String, dynamic>{
    'workflowYaml': workflowYaml,
    'userId': userId,
    if (teamId.isNotEmpty) 'teamId': teamId,
    'commitSha': commitSha,
    'commitMessage': commitMessage,
  };

  final seedResponse = await http.post(
    Uri.parse('$serverUrl/internal/seed/jobs'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(seedPayload),
  );

  if (seedResponse.statusCode < 200 || seedResponse.statusCode >= 300) {
    print('❌ [Job #$index] Failed to seed job: ${seedResponse.body}');
    return;
  }

  // Step 2: Dispatch GitHub Push Webhook
  final deliveryId = 'delivery-$uniqueId';

  final webhookPayload = {
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

  final rawBody = jsonEncode(webhookPayload);
  final hmac = Hmac(sha256, utf8.encode(webhookSecret));
  final digest = hmac.convert(utf8.encode(rawBody));
  final signature = 'sha256=$digest';

  final webhookResponse = await http.post(
    Uri.parse('$serverUrl/webhook'),
    headers: {
      'Content-Type': 'application/json',
      'X-GitHub-Event': 'push',
      'X-GitHub-Delivery': deliveryId,
      'X-Hub-Signature-256': signature,
    },
    body: rawBody,
  );

  if (webhookResponse.statusCode >= 200 && webhookResponse.statusCode < 300) {
    print(
      '✅ [Job #$index] Dispatched successfully! (Sha: $commitSha, Delivery: $deliveryId)',
    );
  } else {
    print(
      '❌ [Job #$index] Webhook dispatch failed (Status: ${webhookResponse.statusCode})',
    );
  }
}

void main(List<String> args) async {
  final countArg = args
      .firstWhere((a) => a.startsWith('--count='), orElse: () => '')
      .replaceFirst('--count=', '')
      .trim();
  final count = int.tryParse(countArg) ?? 5;

  final serverUrl =
      Platform.environment['OPENCI_SERVER_URL'] ?? 'http://localhost:8080';
  final webhookSecret =
      Platform.environment['GITHUB_WEBHOOK_SECRET'] ??
      'your-github-webhook-secret-here';

  final parsedUserId =
      Platform.environment['USER_ID'] ??
      Platform.environment['USER_UID'] ??
      args
          .firstWhere((a) => a.startsWith('--user-id='), orElse: () => '')
          .replaceFirst('--user-id=', '')
          .trim();
  final userId = parsedUserId.isNotEmpty ? parsedUserId : 'test-uid';

  final parsedTeamId =
      Platform.environment['TEAM_ID'] ??
      args
          .firstWhere((a) => a.startsWith('--team-id='), orElse: () => '')
          .replaceFirst('--team-id=', '')
          .trim();
  final teamId = parsedTeamId.isNotEmpty ? parsedTeamId : 'test-team';

  print('🚀 Concurrently dispatching $count build jobs to $serverUrl...\n');

  final futures = List.generate(
    count,
    (i) => dispatchSingleJob(
      index: i + 1,
      serverUrl: serverUrl,
      webhookSecret: webhookSecret,
      userId: userId,
      teamId: teamId,
    ),
  );

  await Future.wait(futures);

  print('\n🎉 All $count build jobs dispatched concurrently!');
}
