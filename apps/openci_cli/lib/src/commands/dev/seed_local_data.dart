import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:meta/meta.dart';
import 'package:openci_shared/openci_shared.dart';

import '../../i18n/i18n.dart';

const _defaultServerUrl = 'http://localhost:8080';
const _defaultTimeout = Duration(seconds: 10);

Future<bool> seedLocalData(
  Logger logger, {
  @visibleForTesting Map<String, String>? environment,
  @visibleForTesting Duration timeout = _defaultTimeout,
}) async {
  logger.stdout('\n${t.dev.start.stepSeed}');

  final env = environment ?? Platform.environment;
  final serverUrl = env['OPENCI_SERVER_URL'] ?? _defaultServerUrl;

  try {
    final internalApiKey = getRequiredEnv('INTERNAL_API_KEY', environment: env);
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
