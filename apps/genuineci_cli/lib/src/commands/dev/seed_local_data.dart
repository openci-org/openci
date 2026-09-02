import 'dart:convert';
import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import '../../i18n/i18n.dart';

const _defaultServerUrl = 'http://localhost:8080';
const _defaultWebhookSecret = 'your-github-webhook-secret-here';

Future<bool> seedLocalData(
  Logger logger, {
  @visibleForTesting http.Client? client,
  @visibleForTesting Map<String, String>? environment,
}) async {
  logger.stdout('\n${t.dev.start.stepSeed}');

  final httpClient = client ?? http.Client();
  final env = environment ?? Platform.environment;
  final serverUrl = env['OPENCI_SERVER_URL'] ?? _defaultServerUrl;
  final webhookSecret = env['GITHUB_WEBHOOK_SECRET'] ?? _defaultWebhookSecret;
  final userId = env['USER_ID'] ?? env['USER_UID'] ?? '';

  try {
    final seedResponse = await httpClient.post(
      Uri.parse('$serverUrl/internal/seed'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({if (userId.isNotEmpty) 'userId': userId}),
    );
    if (!_isSuccessful(seedResponse)) {
      _logFailedResponse(logger, seedResponse);
      return false;
    }

    final webhookPayload = {
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
    final rawBody = jsonEncode(webhookPayload);
    final digest = Hmac(
      sha256,
      utf8.encode(webhookSecret),
    ).convert(utf8.encode(rawBody));

    final webhookResponse = await httpClient.post(
      Uri.parse('$serverUrl/webhook'),
      headers: {
        'Content-Type': 'application/json',
        'X-GitHub-Event': 'push',
        'X-GitHub-Delivery':
            'delivery-${DateTime.now().millisecondsSinceEpoch}',
        'X-Hub-Signature-256': 'sha256=$digest',
      },
      body: rawBody,
    );
    if (!_isSuccessful(webhookResponse)) {
      _logFailedResponse(logger, webhookResponse);
      return false;
    }
  } catch (error) {
    logger.stderr('${t.dev.start.stepSeedFailed}\n$error');
    return false;
  } finally {
    httpClient.close();
  }

  logger.stdout(t.dev.start.stepSeedCompleted);
  return true;
}

bool _isSuccessful(http.Response response) =>
    response.statusCode >= HttpStatus.ok &&
    response.statusCode < HttpStatus.multipleChoices;

void _logFailedResponse(Logger logger, http.Response response) {
  logger.stderr(
    '${t.dev.start.stepSeedFailed}\n'
    'Status: ${response.statusCode}\n'
    'Body: ${response.body}',
  );
}
