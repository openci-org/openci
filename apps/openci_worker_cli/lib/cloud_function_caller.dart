import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

final _log = Logger('CloudFunctionCaller');

/// Cloud Run base URL pattern for Dart Firebase Functions.
/// Matches dart_function_urls.dart in the Dashboard.
const _projectHash = 'zmg24bcsaq';
const _regionCode = 'an'; // asia-northeast1

String _dartFunctionUrl(String serviceName) {
  return 'https://$serviceName-$_projectHash-$_regionCode.a.run.app';
}

/// Calls a Dart Firebase Function (callable) as an authenticated request.
///
/// Uses the service account's OIDC token for authentication.
/// Fire-and-forget: errors are logged but not thrown.
Future<void> callDartFunction(
  String functionName,
  Map<String, dynamic> data,
) async {
  final url = _dartFunctionUrl(functionName);

  try {
    // Get OIDC token from metadata server (GCE) or skip if not available
    String? idToken;
    try {
      final metadataClient = HttpClient();
      try {
        final metadataUrl = Uri.parse(
          'http://metadata.google.internal/computeMetadata/v1/instance/'
          'service-accounts/default/identity?audience=$url',
        );
        final metadataRequest = await metadataClient.getUrl(metadataUrl);
        metadataRequest.headers.set('Metadata-Flavor', 'Google');
        final metadataResponse = await metadataRequest.close();
        idToken = await metadataResponse.transform(utf8.decoder).join();
      } finally {
        metadataClient.close();
      }
    } catch (_) {
      // Not running on GCE — skip OIDC
    }

    final dio = Dio();
    try {
      final response = await dio.post<Map<String, dynamic>>(
        url,
        data: {'data': data},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (idToken != null && idToken.isNotEmpty)
              'Authorization': 'Bearer $idToken',
          },
        ),
      );
      _log.info('$functionName called successfully (${response.statusCode})');
    } on DioException catch (e) {
      _log.warning(
        '$functionName returned ${e.response?.statusCode}: ${e.response?.data}',
      );
    } finally {
      dio.close();
    }
  } catch (e) {
    _log.warning('Failed to call $functionName: $e');
  }
}

/// Notify that a build job's status has changed.
Future<void> notifyBuildJobStatusChange(
  String buildJobId,
  String status,
) async {
  await callDartFunction('build-job-status-change', {
    'buildJobId': buildJobId,
    'status': status,
  });
}

/// Notify that a run's check run should be updated.
Future<void> notifyCheckRunUpdate(
  String buildJobId,
  String runStatus, {
  String? conclusion,
}) async {
  await callDartFunction('check-run-update', {
    'buildJobId': buildJobId,
    'runStatus': runStatus,
    'conclusion': ?conclusion,
  });
}
