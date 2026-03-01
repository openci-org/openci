import 'dart:convert';

import 'package:http/http.dart' as http;

class Build {
  final String id;
  final String orgId;
  final String status;
  final String? yamlDefinition;
  final String runnerOs;
  final String githubOwner;
  final String githubRepo;
  final String? commitSha;
  final String? branch;
  final String? tagName;
  final int? pullRequestNumber;
  final String? githubEvent;
  final String? githubSender;
  final int? installationId;
  final String? installationToken;
  final int? checkRunId;
  final String createdAt;

  Build({
    required this.id,
    required this.orgId,
    required this.status,
    this.yamlDefinition,
    required this.runnerOs,
    required this.githubOwner,
    required this.githubRepo,
    this.commitSha,
    this.branch,
    this.tagName,
    this.pullRequestNumber,
    this.githubEvent,
    this.githubSender,
    this.installationId,
    this.installationToken,
    this.checkRunId,
    required this.createdAt,
  });

  factory Build.fromJson(Map<String, dynamic> json) => Build(
    id: json['id'] as String,
    orgId: json['org_id'] as String,
    status: json['status'] as String,
    yamlDefinition: json['yaml_definition'] as String?,
    runnerOs: json['runner_os'] as String,
    githubOwner: json['github_owner'] as String,
    githubRepo: json['github_repo'] as String,
    commitSha: json['commit_sha'] as String?,
    branch: json['branch'] as String?,
    tagName: json['tag_name'] as String?,
    pullRequestNumber: json['pull_request_number'] as int?,
    githubEvent: json['github_event'] as String?,
    githubSender: json['github_sender'] as String?,
    installationId: json['installation_id'] as int?,
    installationToken: json['installation_token'] as String?,
    checkRunId: json['check_run_id'] as int?,
    createdAt: json['created_at'] as String,
  );
}

class SupabaseWorkerClient {
  final String _url;
  final String _key;
  final http.Client _client;

  SupabaseWorkerClient({
    required String url,
    required String key,
  }) : _url = url.endsWith('/') ? url.substring(0, url.length - 1) : url,
       _key = key,
       _client = http.Client();

  Map<String, String> get _headers => {
    'apikey': _key,
    'Authorization': 'Bearer $_key',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  Future<List<Build>> fetchQueuedBuilds() async {
    final uri = Uri.parse(
      '$_url/rest/v1/builds?status=eq.queued&runner_os=eq.macos&order=created_at.asc&limit=10',
    );
    final response = await _client.get(uri, headers: _headers);
    if (response.statusCode != 200) return [];

    final list = jsonDecode(response.body) as List;
    return list.map((e) => Build.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Build?> claimNextBuild(String workerId) async {
    final uri = Uri.parse('$_url/rest/v1/rpc/claim_next_build');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'p_worker_id': workerId,
        'p_runner_os': 'macos',
      }),
    );
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);
    if (data == null) return null;
    return Build.fromJson(data as Map<String, dynamic>);
  }

  Future<void> updateBuildStatus(String buildId, String status) async {
    final uri = Uri.parse('$_url/rest/v1/builds?id=eq.$buildId');
    await _client.patch(
      uri,
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
  }

  Future<String?> createBuildRun(String buildId) async {
    final uri = Uri.parse('$_url/rest/v1/build_runs');
    final response = await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'build_id': buildId,
        'status': 'in_progress',
      }),
    );
    if (response.statusCode != 201) return null;
    final list = jsonDecode(response.body) as List;
    if (list.isEmpty) return null;
    return (list.first as Map<String, dynamic>)['id'] as String?;
  }

  Future<void> completeBuildRun(String runId, String conclusion) async {
    final uri = Uri.parse('$_url/rest/v1/build_runs?id=eq.$runId');
    await _client.patch(
      uri,
      headers: _headers,
      body: jsonEncode({
        'status': 'completed',
        'conclusion': conclusion,
      }),
    );
  }

  Future<void> insertLog(
    String buildRunId,
    String buildId,
    String message,
    String level,
  ) async {
    final uri = Uri.parse('$_url/rest/v1/build_logs');
    await _client.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'build_run_id': buildRunId,
        'build_id': buildId,
        'message': message,
        'level': level,
      }),
    );
  }

  void dispose() => _client.close();
}
