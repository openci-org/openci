import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:openci_shared/openci_shared.dart';

import 'api/openci_api_client.dart';
import 'firebase.dart';

class ApiClient {
  final AuthManager authManager;
  final String serverUrl;
  final String projectId;
  late final ChopperClient _chopperClient;
  late final OpenCiApiService _apiService;

  ApiClient({required this.authManager, required this.projectId})
    : serverUrl = Platform.environment['OPENCI_SERVER_URL'] ?? '' {
    if (serverUrl.isEmpty) {
      throw StateError('OPENCI_SERVER_URL environment variable is required.');
    }
    _chopperClient = createChopperClient(
      baseUrl: serverUrl,
      authManager: authManager,
    );
    _apiService = _chopperClient.getService<OpenCiApiService>();
  }

  /// Claims the next queued build job for this platform.
  Future<BuildJob?> claimNextJob(String? customPattern) async {
    final runsOnPattern =
        customPattern ?? (Platform.isLinux ? '%ubuntu%' : '%macos%');

    final response = await _apiService.claimNextJob({
      'runsOnPattern': runsOnPattern,
    });

    if (response.isSuccessful) {
      final data = response.body;
      if (data == null) return null;
      final jobJson = data['job'] as Map<String, dynamic>?;
      if (jobJson == null) return null;
      return BuildJob.fromJson(jobJson);
    }
    throw HttpException(
      'Failed to claim job from server: ${response.statusCode} ${response.error}',
    );
  }

  /// Creates a build run record in Firestore.
  Future<void> createRun(String buildJobId, String runId) async {
    final response = await _apiService.createRun(buildJobId, {'id': runId});
    if (response.isSuccessful) {
      return;
    }
    throw HttpException(
      'Failed to create run on server: ${response.statusCode} ${response.error}',
    );
  }

  /// Completes a build job.
  Future<void> completeJob(String id, String status) async {
    final response = await _apiService.completeJob(id, {
      'status': status,
      'completedAt': DateTime.now().toUtc().toIso8601String(),
    });
    if (response.isSuccessful) {
      return;
    }
    throw HttpException(
      'Failed to complete job on server: ${response.statusCode} ${response.error}',
    );
  }

  /// Updates a build run's status.
  Future<void> updateRunStatus({
    required String buildJobId,
    required String runId,
    required String status,
    String? conclusion,
  }) async {
    final response = await _apiService.updateRunStatus(buildJobId, runId, {
      'status': status,
      'conclusion': conclusion,
    });
    if (response.isSuccessful) {
      return;
    }
    throw HttpException(
      'Failed to update run status on server: ${response.statusCode} ${response.error}',
    );
  }

  /// Checks if a job has been cancelled in Firestore.
  Future<bool> isJobCancelled(String buildJobId) async {
    final response = await _apiService.getBuildJob(buildJobId);
    if (response.isSuccessful) {
      final job = response.body;
      if (job == null) return false;
      return job['status'] == 'CANCELLED';
    }
    throw HttpException(
      'Failed to check job cancellation on server: ${response.statusCode} ${response.error}',
    );
  }

  /// Saves or updates a secret value associated with the team.
  Future<void> saveSecret({
    required String teamId,
    required String name,
    required String value,
  }) async {
    final response = await _apiService.saveSecret(teamId, {
      'name': name,
      'value': value,
    });
    if (!response.isSuccessful) {
      throw HttpException(
        'Failed to save secret: ${response.statusCode} ${response.error}',
      );
    }
  }

  /// Retrieves secrets associated with the team.
  Future<List<Map<String, dynamic>>> getSecrets(String teamId) async {
    final response = await _apiService.getSecrets(teamId);
    if (response.isSuccessful) {
      final data = response.body;
      if (data == null) return [];
      final list = data['secrets'] as List<dynamic>?;
      if (list == null) return [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    throw HttpException(
      'Failed to get secrets from server: ${response.statusCode} ${response.error}',
    );
  }

  /// Updates GitHub Check Run status.
  Future<void> updateCheckRun(
    BuildJob buildJob,
    String runStatus, {
    String? conclusion,
  }) async {
    final response = await _apiService.updateCheckRun(buildJob.id, {
      'runStatus': runStatus,
      'conclusion': conclusion,
    });
    if (response.isSuccessful) {
      return;
    }
    throw HttpException(
      'Failed to update check run on server: ${response.statusCode} ${response.error}',
    );
  }

  /// Handles Build Job status changes (notifications, etc).
  Future<void> handleBuildJobStatusChange(
    BuildJob buildJob,
    String status,
  ) async {
    final response = await _apiService.handleBuildJobStatusChange(buildJob.id, {
      'status': status,
    });
    if (response.isSuccessful) {
      return;
    }
    throw HttpException(
      'Failed to process status change on server: ${response.statusCode} ${response.error}',
    );
  }

  /// Resolves the Installation Access Token via Firebase Functions.
  Future<Map<String, dynamic>> resolveInstallationToken(
    String buildJobId,
  ) async {
    final response = await _apiService.resolveInstallationToken(buildJobId);
    if (response.isSuccessful) {
      return response.body ?? const {};
    }
    throw HttpException(
      'Failed to resolve token on server: ${response.statusCode} ${response.error}',
    );
  }

  /// Fetches a Secret Value via Firebase Functions.
  Future<String> getSecretValue(String teamId, String name) async {
    final response = await _apiService.getSecretValue(teamId, name);
    if (response.isSuccessful) {
      final data = response.body;
      if (data == null) return '';
      return data['value'] as String? ?? '';
    }
    throw HttpException(
      'Failed to get secret value from server: ${response.statusCode} ${response.error}',
    );
  }

  /// Sends the worker heartbeat status.
  Future<void> sendHeartbeat({
    required String workerId,
    required String version,
    required String status,
  }) async {
    final response = await _apiService.sendHeartbeat({
      'workerId': workerId,
      'version': version,
      'platform': Platform.operatingSystem,
      'status': status,
    });
    if (!response.isSuccessful) {
      throw HttpException(
        'Failed to update worker heartbeat on server: ${response.statusCode} ${response.error}',
      );
    }
  }
}
