import 'dart:convert';
import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:path/path.dart' as p;

import '../../i18n/i18n.dart';

const _defaultServerUrl = 'http://localhost:8080';
const _defaultTimeout = Duration(seconds: 10);
const _developmentEmail = 'test@openci.org';
const _developmentPassword = '123456';

Future<bool> seedLocalData(
  Logger logger, {
  required Directory projectRoot,
  @visibleForTesting Map<String, String>? environment,
  @visibleForTesting Duration timeout = _defaultTimeout,
}) async {
  logger.stdout('\n${t.dev.start.stepSeed}');

  final env = environment ?? Platform.environment;
  final serverUrl = env['OPENCI_SERVER_URL'] ?? _defaultServerUrl;

  try {
    final serverHost = Uri.tryParse(serverUrl)?.host;
    if (!const {'localhost', '127.0.0.1', '::1'}.contains(serverHost)) {
      throw StateError('Local seed requires a localhost OPENCI_SERVER_URL.');
    }
    final internalApiKey = await _readInternalApiKey(projectRoot);
    if (internalApiKey == null || internalApiKey.isEmpty) {
      throw StateError(
        'INTERNAL_API_KEY is not set in ${p.join(projectRoot.path, '.env')}.',
      );
    }
    final userId = await _seedLocalAuthUser(timeout);
    final client = createOpenCIChopperClient(
      baseUrl: serverUrl,
      tokenProvider: () => internalApiKey,
      services: [OpenCIApiService.create()],
    );
    try {
      final response = await client
          .getService<OpenCIApiService>()
          .seedLocalData({'userId': userId})
          .timeout(timeout);
      if (!response.isSuccessful) {
        logger.stderr(
          '${t.dev.start.stepSeedFailed}\n'
          'Status: ${response.statusCode}\n'
          'Body: ${response.bodyString}',
        );
        return false;
      }
    } finally {
      client.dispose();
    }
  } catch (error) {
    logger.stderr('${t.dev.start.stepSeedFailed}\n$error');
    return false;
  }

  logger.stdout(t.dev.start.stepSeedCompleted);
  return true;
}

Future<String> _seedLocalAuthUser(Duration timeout) async {
  final client = http.Client();

  Future<http.Response> post(String action) {
    final request =
        http.Request(
            'POST',
            Uri.parse(
              'http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/'
              'accounts:$action?key=demo-openci-api-key',
            ),
          )
          ..followRedirects = false
          ..headers['Content-Type'] = 'application/json'
          ..body = jsonEncode({
            'email': _developmentEmail,
            'password': _developmentPassword,
            'returnSecureToken': true,
          });
    return client.send(request).then(http.Response.fromStream).timeout(timeout);
  }

  try {
    var response = await post('signUp');
    var body = jsonDecode(response.body);
    final error = body is Map<String, dynamic> ? body['error'] : null;
    if (response.statusCode == 400 &&
        error is Map<String, dynamic> &&
        error['message'] == 'EMAIL_EXISTS') {
      // Reuse the user without resetting their password or other properties.
      response = await post('signInWithPassword');
      body = jsonDecode(response.body);
    }
    if (response.statusCode != 200 || body is! Map<String, dynamic>) {
      throw const FormatException();
    }
    final uid = body['localId'];
    if (uid is! String || uid.trim().isEmpty) {
      throw const FormatException();
    }
    return uid;
  } catch (_) {
    // Responses and HTTP exceptions can contain passwords or tokens.
    throw StateError(
      'Could not prepare the local Auth user. Check the Auth Emulator at '
      '127.0.0.1:9099 and the documented credentials for $_developmentEmail.',
    );
  } finally {
    client.close();
  }
}

Future<String?> _readInternalApiKey(Directory projectRoot) async {
  final envFile = File(p.join(projectRoot.path, '.env'));
  if (!await envFile.exists()) {
    return null;
  }

  for (final line in await envFile.readAsLines()) {
    final match = RegExp(r'^\s*INTERNAL_API_KEY\s*=\s*(.*)$').firstMatch(line);
    if (match == null) {
      continue;
    }

    final value = match.group(1)!.trim();
    if (value.length >= 2 &&
        ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'")))) {
      return value.substring(1, value.length - 1);
    }
    return value.split(RegExp(r'\s+#')).first.trimRight();
  }

  return null;
}
