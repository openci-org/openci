import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:openci_shared/openci_shared.dart';

import 'firebase.dart';

class ApiClient {
  final AuthManager authManager;
  final String serverUrl;
  final String projectId;

  ApiClient({required this.authManager, required this.projectId})
    : serverUrl = Platform.environment['OPENCI_SERVER_URL'] ?? '' {
    if (serverUrl.isEmpty) {
      throw StateError('OPENCI_SERVER_URL environment variable is required.');
    }
  }

  /// Claims the next queued build job for this platform.
  Future<BuildJob?> claimNextJob(String? customPattern) async {
    final runsOnPattern =
        customPattern ?? (Platform.isLinux ? '%ubuntu%' : '%macos%');

    final url = Uri.parse('$serverUrl/builds/claim');
    final idToken = await authManager.getIdToken();
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({'runsOnPattern': runsOnPattern}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final jobJson = data['job'] as Map<String, dynamic>?;
      if (jobJson == null) return null;
      return BuildJob.fromJson(jobJson);
    }
    throw HttpException(
      'Failed to claim job from server: ${response.statusCode} ${response.body}',
    );
  }

  /// Creates a build run record in Firestore.
  Future<void> createRun(String buildJobId, String runId) async {
    final url = Uri.parse('$serverUrl/builds/$buildJobId/runs');
    final idToken = await authManager.getIdToken();
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({'id': runId}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw HttpException(
      'Failed to create run on server: ${response.statusCode} ${response.body}',
    );
  }

  /// Completes a build job.
  Future<void> completeJob(String id, String status) async {
    final url = Uri.parse('$serverUrl/builds/$id');
    final idToken = await authManager.getIdToken();
    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({
        'status': status,
        'completedAt': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw HttpException(
      'Failed to complete job on server: ${response.statusCode} ${response.body}',
    );
  }

  /// Updates a build run's status.
  Future<void> updateRunStatus({
    required String buildJobId,
    required String runId,
    required String status,
    String? conclusion,
  }) async {
    final url = Uri.parse('$serverUrl/builds/$buildJobId/runs/$runId');
    final idToken = await authManager.getIdToken();
    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({'status': status, 'conclusion': ?conclusion}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw HttpException(
      'Failed to update run status on server: ${response.statusCode} ${response.body}',
    );
  }

  /// Checks if a job has been cancelled in Firestore.
  Future<bool> isJobCancelled(String buildJobId) async {
    final url = Uri.parse('$serverUrl/builds/$buildJobId');
    final idToken = await authManager.getIdToken();
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final job = jsonDecode(response.body) as Map<String, dynamic>;
      return job['status'] == 'CANCELLED';
    }
    throw HttpException(
      'Failed to check job cancellation on server: ${response.statusCode} ${response.body}',
    );
  }

  /// Saves or updates a secret value associated with the team.
  Future<void> saveSecret({
    required String teamId,
    required String name,
    required String value,
  }) async {
    final url = Uri.parse('$serverUrl/teams/$teamId/secrets');
    final idToken = await authManager.getIdToken();
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'name': name, 'value': value}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Failed to save secret: ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Retrieves secrets associated with the team.
  Future<List<Map<String, dynamic>>> getSecrets(String teamId) async {
    final url = Uri.parse('$serverUrl/teams/$teamId/secrets');
    final idToken = await authManager.getIdToken();
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['secrets'] as List<dynamic>?;
      if (list == null) return [];
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    throw HttpException(
      'Failed to get secrets from server: ${response.statusCode} ${response.body}',
    );
  }

  /// Updates GitHub Check Run status.
  Future<void> updateCheckRun(
    BuildJob buildJob,
    String runStatus, {
    String? conclusion,
  }) async {
    final url = Uri.parse('$serverUrl/builds/${buildJob.id}/check-run');
    final idToken = await authManager.getIdToken();
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({'runStatus': runStatus, 'conclusion': ?conclusion}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw HttpException(
      'Failed to update check run on server: ${response.statusCode} ${response.body}',
    );
  }

  /// Handles Build Job status changes (notifications, etc).
  Future<void> handleBuildJobStatusChange(
    BuildJob buildJob,
    String status,
  ) async {
    final url = Uri.parse('$serverUrl/builds/${buildJob.id}/status-change');
    final idToken = await authManager.getIdToken();
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      },
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw HttpException(
      'Failed to process status change on server: ${response.statusCode} ${response.body}',
    );
  }

  /// Resolves the Installation Access Token via Firebase Functions.
  Future<Map<String, dynamic>> resolveInstallationToken(
    String buildJobId,
  ) async {
    final url = Uri.parse('$serverUrl/builds/$buildJobId/token');
    final idToken = await authManager.getIdToken();
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw HttpException(
      'Failed to resolve token on server: ${response.statusCode} ${response.body}',
    );
  }

  /// Fetches a Secret Value via Firebase Functions.
  Future<String> getSecretValue(String teamId, String name) async {
    final url = Uri.parse('$serverUrl/teams/$teamId/secrets/$name');
    final idToken = await authManager.getIdToken();
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['value'] as String? ?? '';
    }
    throw HttpException(
      'Failed to get secret value from server: ${response.statusCode} ${response.body}',
    );
  }
}
