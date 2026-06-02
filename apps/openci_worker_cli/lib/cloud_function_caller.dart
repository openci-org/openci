import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:openci_shared/openci_shared.dart';

import 'firebase.dart';

const Map<String, String> defaultProjectNumbers = {
  'openci-b1b91': '372767414789',
};

class ApiClient {
  final AuthManager authManager;
  final String projectId;
  final String? projectNumber;

  ApiClient({
    required this.authManager,
    required this.projectId,
    this.projectNumber,
  });

  String _resolveUrl(String functionName) {
    final isEmulator = Platform.environment['FUNCTIONS_EMULATOR'] == 'true' ||
        Platform.environment['FIRESTORE_EMULATOR_HOST'] != null;

    if (isEmulator) {
      final emulatorHost = Platform.environment['FIREBASE_FUNCTIONS_EMULATOR_HOST'] ?? '127.0.0.1:5001';
      return 'http://$emulatorHost/$projectId/asia-northeast1/$functionName';
    } else {
      final resolvedNumber = projectNumber ?? defaultProjectNumbers[projectId];
      if (resolvedNumber == null) {
        throw StateError(
          'Project number required for production mode but was not provided or resolved.',
        );
      }
      return 'https://$functionName-$resolvedNumber.asia-northeast1.run.app';
    }
  }

  Future<Map<String, dynamic>> callApi(
    String functionName,
    Map<String, dynamic> payload,
  ) async {
    final url = _resolveUrl(functionName);
    final idToken = await authManager.getIdToken();

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'API $functionName failed: ${response.statusCode} ${response.body}',
      );
    }

    if (response.body.isEmpty) {
      return {};
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Claims the next queued build job for this platform.
  Future<BuildJob?> claimNextJob(String? customPattern) async {
    final runsOnPattern = customPattern ??
        (Platform.isLinux ? '%ubuntu%' : '%macos%');
    
    final response = await callApi('claim-next-job', {
      'runsOnPattern': runsOnPattern,
    });

    final jobJson = response['job'] as Map<String, dynamic>?;
    if (jobJson == null) return null;

    return BuildJob.fromJson(jobJson);
  }

  /// Creates a build run record in Firestore.
  Future<void> createRun(String buildJobId, String runId) async {
    await callApi('create-build-run', {
      'buildJobId': buildJobId,
      'id': runId,
    });
  }

  /// Appends multiple build logs.
  Future<void> appendBuildLogs({
    required String buildJobId,
    required String runId,
    required List<Map<String, dynamic>> logs,
  }) async {
    await callApi('append-build-logs', {
      'buildJobId': buildJobId,
      'runId': runId,
      'logs': logs,
    });
  }

  /// Completes a build job.
  Future<void> completeJob(String id, String status) async {
    await callApi('complete-build-job', {
      'id': id,
      'status': status,
    });
  }

  /// Updates a build run's status.
  Future<void> updateRunStatus({
    required String buildJobId,
    required String runId,
    required String status,
    String? conclusion,
  }) async {
    await callApi('update-build-run-status', {
      'buildJobId': buildJobId,
      'runId': runId,
      'status': status,
      if (conclusion != null) 'conclusion': conclusion,
    });
  }

  /// Sends worker heartbeat signal to monitor worker status.
  Future<void> updateWorkerHeartbeat(Map<String, dynamic> heartbeat) async {
    await callApi('update-worker-heartbeat', heartbeat);
  }

  /// Checks if a job has been cancelled in Firestore.
  Future<bool> isJobCancelled(String buildJobId) async {
    final response = await callApi('is-job-cancelled', {
      'buildJobId': buildJobId,
    });
    return response['cancelled'] as bool? ?? false;
  }

  /// Retrieves environment variables associated with the team.
  Future<List<Map<String, dynamic>>> getEnvironmentVariables(String teamId) async {
    final response = await callApi('get-environment-variables', {
      'teamId': teamId,
    });
    final list = response['environmentVariables'] as List<dynamic>?;
    if (list == null) return [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Increments or updates environment variable value.
  Future<void> updateEnvironmentVariable(String id, String value) async {
    await callApi('update-environment-variable', {
      'id': id,
      'value': value,
    });
  }

  /// Retrieves secrets associated with the team.
  Future<List<Map<String, dynamic>>> getSecrets(String teamId) async {
    final response = await callApi('get-secrets', {
      'teamId': teamId,
    });
    final list = response['secrets'] as List<dynamic>?;
    if (list == null) return [];
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  /// Updates GitHub Check Run status.
  Future<void> updateCheckRun(
    BuildJob buildJob,
    String runStatus, {
    String? conclusion,
  }) async {
    await callApi('update-check-run', {
      'buildJob': buildJob.toJson(),
      'runStatus': runStatus,
      if (conclusion != null) 'conclusion': conclusion,
    });
  }

  /// Handles Build Job status changes (notifications, etc).
  Future<void> handleBuildJobStatusChange(BuildJob buildJob, String status) async {
    await callApi('handle-build-job-status-change', {
      'buildJob': buildJob.toJson(),
      'status': status,
    });
  }

  /// Resolves the Installation Access Token via Firebase Functions.
  Future<Map<String, dynamic>> resolveInstallationToken(String buildJobId) async {
    return await callApi('resolve-installation-token', {
      'buildJobId': buildJobId,
    });
  }

  /// Fetches a Secret Value via Firebase Functions.
  Future<String> getSecretValue(String teamId, String name) async {
    final response = await callApi('get-secret-value', {
      'teamId': teamId,
      'name': name,
    });
    return response['value'] as String? ?? '';
  }
}
