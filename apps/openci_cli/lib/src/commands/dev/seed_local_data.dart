import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:meta/meta.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:path/path.dart' as p;

import '../../i18n/i18n.dart';

const _defaultServerUrl = 'http://localhost:8080';
const _defaultTimeout = Duration(seconds: 10);

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
    final client = createOpenCIChopperClient(
      baseUrl: serverUrl,
      tokenProvider: () => internalApiKey,
      services: [OpenCIApiService.create()],
    );
    try {
      final response = await client
          .getService<OpenCIApiService>()
          .seedLocalData({})
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
