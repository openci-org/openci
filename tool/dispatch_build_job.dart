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
  final customScriptArg = args
      .firstWhere((arg) => arg.startsWith('--script='), orElse: () => '')
      .replaceFirst('--script=', '')
      .trim();

  final yamlArg = args
      .firstWhere((arg) => arg.startsWith('--yaml='), orElse: () => '')
      .replaceFirst('--yaml=', '')
      .trim();

  final workflowYaml =
      Platform.environment['WORKFLOW_YAML'] ??
      (yamlArg.isNotEmpty
          ? yamlArg
          : '''
name: Test Workflow
on:
  push:
    branches: [ main ]

jobs:
  build:
    name: Build & Test
    runs-on: macos-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Run Long OpenCI Streaming Test Script
        run: |
          echo "🚀 Step 1: Initializing environment & dependencies..."
          for i in 1 2 3 4 5; do
            echo "   [Dep Check \$i/5] Installing package dependencies..."
            sleep 2
          done

          echo "📦 Step 2: Compiling Application..."
          for i in 1 2 3 4; do
            echo "   [Build Task \$i/4] Building target release bundle..."
            sleep 2
          done

          echo "🧪 Step 3: Executing Test Suites..."
          echo "   Running unit tests (128 tests total)..."
          sleep 3
          echo "   ✅ Unit tests passed (128/128)"

          echo "💥 Step 4: Simulating Final Build Failure..."
          sleep 2
          echo "❌ Build failed due to simulated error"
          exit 1
''');

  final customScript = Platform.environment['CUSTOM_SCRIPT'] ?? customScriptArg;

  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final commitSha = 'sha-${timestamp.toString().substring(5)}';
  final commitMessage =
      'feat: 🎉 Build job dispatched at ${DateTime.now().toIso8601String().substring(11, 19)}';

  print(
    '🚀 Step 1: Creating test build job via API ($serverUrl/internal/seed/jobs)...',
  );

  try {
    final payload = <String, dynamic>{
      if (customScript.isNotEmpty) 'customScript': customScript,
      'workflowYaml': workflowYaml,
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
      print('   Body:\n${_formatJson(response.body)}');
    } else {
      print('❌ Failed to create test build job via API!');
      print('   Status: ${response.statusCode}');
      print('   Body:\n${_formatJson(response.body)}');
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
      print('   Body:\n${_formatJson(response.body)}');
      print('   Delivery ID: $deliveryId');
    } else {
      print('❌ Failed to dispatch webhook!');
      print('   Status: ${response.statusCode}');
      print('   Body:\n${_formatJson(response.body)}');
    }
  } catch (e, st) {
    print('❌ Error sending webhook HTTP request: $e');
    print(st);
  }
}

String _formatJson(String rawJson) {
  try {
    final parsed = jsonDecode(rawJson);
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(parsed);
  } catch (_) {
    return rawJson;
  }
}
