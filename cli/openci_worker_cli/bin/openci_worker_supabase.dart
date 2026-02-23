/// OpenCI Worker CLI — Supabase migration version
///
/// Replaces the Firestore-based openci_worker_cli.dart with Supabase PostgREST.
/// Authentication: worker_role PostgreSQL role via direct DB connection.
/// Job claiming: uses the claim_next_build() RPC (FOR UPDATE SKIP LOCKED).
///
/// Usage:
///   openci_worker --service-account /path/to/supabase-credentials.json --worker-id mac-01
///
/// supabase-credentials.json format:
///   {
///     "supabase_url": "https://xxx.supabase.co",
///     "service_role_key": "eyJhbGci..."
///   }
///
/// Note: Secret environment variables are fetched from Supabase Vault via the
/// get_env_var_secret() SECURITY DEFINER RPC. No GCP credentials are required.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:http/http.dart' as http;
import 'package:process_run/process_run.dart';
import 'package:uuid/uuid.dart';

const String version = '0.5.0';
const int pollingIntervalSeconds = 10;

// ============================================================
// Supabase PostgREST client
// ============================================================

class SupabaseWorkerClient {
  final String supabaseUrl;
  final String serviceRoleKey;
  final http.Client _httpClient;

  SupabaseWorkerClient({
    required this.supabaseUrl,
    required this.serviceRoleKey,
  }) : _httpClient = http.Client();

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'apikey': serviceRoleKey,
        'Authorization': 'Bearer $serviceRoleKey',
        'Prefer': 'return=representation',
      };

  Uri _url(String path, [Map<String, String>? queryParams]) {
    final uri = Uri.parse('$supabaseUrl/rest/v1/$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  // Claim the next queued build atomically using FOR UPDATE SKIP LOCKED
  Future<Map<String, dynamic>?> claimNextBuild(String workerId) async {
    final response = await _httpClient.post(
      _url('rpc/claim_next_build'),
      headers: _headers,
      body: jsonEncode({'p_worker_id': workerId}),
    );
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body);
    if (data == null) return null; // No queued builds
    return data as Map<String, dynamic>;
  }

  // Check if a build has been cancelled
  Future<bool> isBuildCancelled(String buildId) async {
    final response = await _httpClient.get(
      _url('builds', {'id': 'eq.$buildId', 'select': 'status'}),
      headers: _headers,
    );
    if (response.statusCode != 200) return false;
    final data = jsonDecode(response.body) as List;
    if (data.isEmpty) return false;
    return data[0]['status'] == 'cancelled';
  }

  // Update a build's status
  Future<void> updateBuildStatus(String buildId, String status) async {
    await _httpClient.patch(
      _url('builds', {'id': 'eq.$buildId'}),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
  }

  // Create a build_run record for this attempt
  Future<String?> createBuildRun(String buildId) async {
    final response = await _httpClient.post(
      _url('build_runs'),
      headers: _headers,
      body: jsonEncode({
        'build_id': buildId,
        'status': 'in_progress',
      }),
    );
    if (response.statusCode != 201) return null;
    final data = jsonDecode(response.body);
    final rows = data is List ? data : [data];
    if (rows.isEmpty) return null;
    return rows[0]['id'] as String?;
  }

  // Complete a build_run with conclusion
  Future<void> completeBuildRun(
    String buildRunId,
    String conclusion, // 'success' | 'failure' | 'cancelled'
  ) async {
    await _httpClient.patch(
      _url('build_runs', {'id': 'eq.$buildRunId'}),
      headers: _headers,
      body: jsonEncode({
        'status': 'completed',
        'conclusion': conclusion,
      }),
    );
  }

  // Write a log entry for a build run (with exponential backoff retry)
  Future<void> writeLog({
    required String buildRunId,
    required String buildId,
    required String message,
    required String level, // 'info' | 'warning' | 'error'
    String? stackTrace,
    int? stepIndex,
    String? stepName,
  }) async {
    final body = <String, dynamic>{
      'build_run_id': buildRunId,
      'build_id': buildId,
      'message': message,
      'level': level,
    };
    if (stackTrace != null) body['stack_trace'] = stackTrace;
    if (stepIndex != null) body['step_index'] = stepIndex;
    if (stepName != null) body['step_name'] = stepName;

    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final response = await _httpClient.post(
          _url('build_logs'),
          headers: _headers,
          body: jsonEncode(body),
        );
        if (response.statusCode == 201) return;
        // Non-201 on last attempt: give up silently to avoid blocking the build
        if (attempt == 2) return;
      } catch (_) {
        if (attempt == 2) return;
      }
      await Future.delayed(Duration(seconds: 1 << attempt)); // 1s, 2s
    }
  }

  // Fetch all logs for a build run (used for archiving)
  Future<List<Map<String, dynamic>>> fetchAllLogs(String buildRunId) async {
    final response = await _httpClient.get(
      _url('build_logs', {
        'build_run_id': 'eq.$buildRunId',
        'select': 'id,created_at,level,message,stack_trace,step_index,step_name',
        'order': 'id.asc',
        'limit': '100000',
      }),
      headers: _headers,
    );
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body) as List;
    return data.cast<Map<String, dynamic>>();
  }

  // Upload a text file to Supabase Storage (build-logs bucket)
  Future<bool> uploadLogArchive({
    required String path,
    required String content,
  }) async {
    final uploadHeaders = {
      'Content-Type': 'text/plain; charset=utf-8',
      'apikey': serviceRoleKey,
      'Authorization': 'Bearer $serviceRoleKey',
    };
    final response = await _httpClient.post(
      Uri.parse('$supabaseUrl/storage/v1/object/build-logs/$path'),
      headers: uploadHeaders,
      body: utf8.encode(content),
    );
    return response.statusCode == 200 || response.statusCode == 201;
  }

  // Update builds.log_archive_path after successful upload
  Future<void> updateLogArchivePath(String buildId, String path) async {
    await _httpClient.patch(
      _url('builds', {'id': 'eq.$buildId'}),
      headers: _headers,
      body: jsonEncode({'log_archive_path': path}),
    );
  }

  // Fetch environment variables for a project
  Future<List<Map<String, dynamic>>> getEnvVars(String projectId) async {
    final response = await _httpClient.get(
      _url('environment_variables', {'project_id': 'eq.$projectId', 'select': '*'}),
      headers: _headers,
    );
    if (response.statusCode != 200) return [];
    final data = jsonDecode(response.body) as List;
    return data.cast<Map<String, dynamic>>();
  }

  // Atomically increment an auto-increment env var
  // Returns the value BEFORE incrementing (the current build uses this number)
  Future<String?> incrementEnvVar(String envVarId) async {
    final response = await _httpClient.post(
      _url('rpc/increment_env_var'),
      headers: _headers,
      body: jsonEncode({'p_env_var_id': envVarId}),
    );
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body);
    return data as String?;
  }

  // Get the latest worker version for self-update check
  Future<String?> fetchLatestVersion() async {
    final response = await _httpClient.get(
      _url('worker_config', {'key': 'eq.latest_version', 'select': 'value'}),
      headers: _headers,
    );
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as List;
    if (data.isEmpty) return null;
    return data[0]['value'] as String?;
  }

  // Fetch a secret env var value via get_env_var_secret() SECURITY DEFINER RPC
  Future<String?> getEnvVarSecret(String envVarId) async {
    final response = await _httpClient.post(
      _url('rpc/get_env_var_secret'),
      headers: _headers,
      body: jsonEncode({'p_env_var_id': envVarId}),
    );
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body);
    if (data == null) return null;
    return data as String?;
  }

  // Get workflow details (yaml_definition) for a build
  Future<Map<String, dynamic>?> getWorkflow(String workflowId) async {
    final response = await _httpClient.get(
      _url('workflows', {'id': 'eq.$workflowId', 'select': '*'}),
      headers: _headers,
    );
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body) as List;
    if (data.isEmpty) return null;
    return data[0] as Map<String, dynamic>;
  }

  void dispose() => _httpClient.close();
}

// ============================================================
// Build Logger (wraps SupabaseWorkerClient)
// ============================================================

class BuildLogger {
  final SupabaseWorkerClient _client;
  final String _buildId;
  final String _buildRunId;
  final Map<String, dynamic> _buildMeta; // build row for archive header

  // Current step context (set via beginStep)
  int? _currentStepIndex;
  String? _currentStepName;

  BuildLogger(this._client, this._buildId, this._buildRunId, this._buildMeta);

  String get buildRunId => _buildRunId;

  /// Call before executing each step to attach step context to subsequent logs.
  void beginStep(int index, String name) {
    _currentStepIndex = index;
    _currentStepName = name;
  }

  /// Call after a step finishes (or on error) to clear step context.
  void endStep() {
    _currentStepIndex = null;
    _currentStepName = null;
  }

  Future<void> info(String message) async {
    print('[INFO] $message');
    await _client.writeLog(
      buildRunId: _buildRunId,
      buildId: _buildId,
      message: message,
      level: 'info',
      stepIndex: _currentStepIndex,
      stepName: _currentStepName,
    );
  }

  Future<void> warning(String message) async {
    print('[WARNING] $message');
    await _client.writeLog(
      buildRunId: _buildRunId,
      buildId: _buildId,
      message: message,
      level: 'warning',
      stepIndex: _currentStepIndex,
      stepName: _currentStepName,
    );
  }

  Future<void> error(String message, {String? stackTrace}) async {
    print('[ERROR] $message');
    if (stackTrace != null) print('[ERROR] $stackTrace');
    await _client.writeLog(
      buildRunId: _buildRunId,
      buildId: _buildId,
      message: message,
      level: 'error',
      stackTrace: stackTrace,
      stepIndex: _currentStepIndex,
      stepName: _currentStepName,
    );
  }

  Future<void> complete(String conclusion) async {
    await _client.completeBuildRun(_buildRunId, conclusion);
    final status = conclusion == 'success'
        ? 'success'
        : conclusion == 'cancelled'
            ? 'cancelled'
            : 'failure';
    await _client.updateBuildStatus(_buildId, status);
    await _archiveLogs(conclusion);
  }

  /// Fetch all logs from DB, format as UTF-8 text, and upload to Supabase Storage.
  Future<void> _archiveLogs(String conclusion) async {
    try {
      final logs = await _client.fetchAllLogs(_buildRunId);
      final text = _formatArchive(logs, conclusion);
      final orgId = _buildMeta['org_id'] as String? ?? 'unknown';
      final projectId = _buildMeta['project_id'] as String;
      final path = '$orgId/$projectId/$_buildId.txt';
      final ok = await _client.uploadLogArchive(path: path, content: text);
      if (ok) {
        await _client.updateLogArchivePath(_buildId, path);
      } else {
        print('[Archive] Failed to upload log archive for build $_buildId');
      }
    } catch (e) {
      print('[Archive] Error archiving logs for build $_buildId: $e');
    }
  }

  String _formatArchive(List<Map<String, dynamic>> logs, String conclusion) {
    final sb = StringBuffer();
    sb.writeln('Build: $_buildId');
    sb.writeln('Repository: ${_buildMeta['github_owner']}/${_buildMeta['github_repo']}');
    if (_buildMeta['commit_sha'] != null) sb.writeln('Commit: ${(_buildMeta['commit_sha'] as String).substring(0, 7)}');
    if (_buildMeta['branch'] != null) sb.writeln('Branch: ${_buildMeta['branch']}');
    if (_buildMeta['tag_name'] != null) sb.writeln('Tag: ${_buildMeta['tag_name']}');
    sb.writeln('Status: $conclusion');
    sb.writeln('Date: ${DateTime.now().toUtc().toIso8601String()}');
    sb.writeln('=' * 80);
    sb.writeln();

    int? lastStepIndex;
    for (final log in logs) {
      final stepIndex = log['step_index'] as int?;
      final stepName = log['step_name'] as String?;

      // Print step header when step changes
      if (stepIndex != null && stepIndex != lastStepIndex) {
        sb.writeln();
        sb.writeln('[Step ${stepIndex + 1}] ${stepName ?? "Step ${stepIndex + 1}"}');
        sb.writeln('-' * 80);
        lastStepIndex = stepIndex;
      }

      final ts = log['created_at'] as String;
      final level = (log['level'] as String).toUpperCase();
      final message = log['message'] as String;
      final levelTag = level == 'INFO' ? '' : '[$level] ';
      sb.writeln('$ts ${levelTag}$message');

      final stackTrace = log['stack_trace'] as String?;
      if (stackTrace != null && stackTrace.isNotEmpty) {
        for (final line in stackTrace.split('\n')) {
          sb.writeln('    $line');
        }
      }
    }
    return sb.toString();
  }
}

// ============================================================
// CLI entry point
// ============================================================

ArgParser buildParser() {
  return ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Print usage information.')
    ..addFlag('version', negatable: false, help: 'Print the tool version.')
    ..addFlag('update', abbr: 'u', negatable: false, help: 'Update to the latest version.')
    ..addOption('service-account', help: 'Path to supabase-credentials.json')
    ..addOption('worker-id', help: 'Unique ID for this worker (e.g., mac-01)');
}

Future<void> main(List<String> arguments) async {
  final argParser = buildParser();

  try {
    final results = argParser.parse(arguments);

    if (results.flag('help')) {
      print('Usage: openci_worker_supabase <flags>');
      print(argParser.usage);
      return;
    }
    if (results.flag('version')) {
      print('openci_worker_supabase version: $version');
      return;
    }
    if (results.flag('update')) {
      final shell = Shell(verbose: true);
      await shell.run('dart pub global activate openci_worker_cli');
      return;
    }

    final String? serviceAccountPath = results['service-account'];
    final String? workerId = results['worker-id'];

    if (serviceAccountPath == null || workerId == null) {
      print('Error: --service-account and --worker-id are required.');
      print(argParser.usage);
      return;
    }

    final credFile = File(serviceAccountPath);
    if (!credFile.existsSync()) {
      print('Error: Credentials file not found: $serviceAccountPath');
      return;
    }

    final creds = jsonDecode(credFile.readAsStringSync()) as Map<String, dynamic>;
    final supabaseUrl = creds['supabase_url'] as String?;
    final serviceRoleKey = creds['service_role_key'] as String?;

    if (supabaseUrl == null || serviceRoleKey == null) {
      print('Error: supabase_url and service_role_key required in credentials JSON.');
      return;
    }

    final supabase = SupabaseWorkerClient(
      supabaseUrl: supabaseUrl,
      serviceRoleKey: serviceRoleKey,
    );

    print('OpenCI Worker $version starting. Worker ID: $workerId');

    // Check for self-update
    final latestVersion = await supabase.fetchLatestVersion();
    if (latestVersion != null && latestVersion != version) {
      print('New version available: $latestVersion. Run with --update to upgrade.');
    }

    // Main polling loop
    while (true) {
      try {
        final build = await supabase.claimNextBuild(workerId);
        if (build == null) {
          await Future.delayed(Duration(seconds: pollingIntervalSeconds));
          continue;
        }

        print('Claimed build: ${build['id']} (project: ${build['project_id']})');
        await _processBuild(supabase, build, workerId);
      } catch (e, st) {
        print('Worker loop error: $e\n$st');
        await Future.delayed(Duration(seconds: pollingIntervalSeconds));
      }
    }
  } on FormatException catch (e) {
    print('Error: ${e.message}');
    print(argParser.usage);
    exit(1);
  }
}

// ============================================================
// Build processing
// ============================================================

Future<void> _processBuild(
  SupabaseWorkerClient supabase,
  Map<String, dynamic> build,
  String workerId,
) async {
  final buildId = build['id'] as String;
  final projectId = build['project_id'] as String;
  final workflowId = build['workflow_id'] as String?;

  // Create a build_run record for this attempt
  final buildRunId = await supabase.createBuildRun(buildId);
  if (buildRunId == null) {
    print('Failed to create build_run for build $buildId');
    await supabase.updateBuildStatus(buildId, 'failure');
    return;
  }

  final logger = BuildLogger(supabase, buildId, buildRunId, build);

  try {
    await logger.info('Build started. Worker: $workerId');

    // Fetch workflow YAML
    if (workflowId == null) {
      await logger.error('No workflow associated with this build.');
      await logger.complete('failure');
      return;
    }

    final workflow = await supabase.getWorkflow(workflowId);
    if (workflow == null) {
      await logger.error('Workflow $workflowId not found.');
      await logger.complete('failure');
      return;
    }

    final yamlDefinition = workflow['yaml_definition'] as String? ?? '';
    await logger.info('Loaded workflow: ${workflow['name']}');

    // Parse steps from YAML (simplified — production should use a proper YAML parser)
    // The YAML format is GitHub Actions-style; steps are under jobs.<job>.steps
    final steps = _parseWorkflowSteps(yamlDefinition);
    await logger.info('Found ${steps.length} step(s).');

    // Load environment variables
    final envVars = await supabase.getEnvVars(projectId);
    final env = <String, String>{};

    for (final ev in envVars) {
      final key = ev['key'] as String;
      if (ev['auto_increment'] == true) {
        final value = await supabase.incrementEnvVar(ev['id'] as String);
        if (value != null) env[key] = value;
      } else if (ev['is_secret'] == true) {
        // Fetch from Supabase Vault via SECURITY DEFINER RPC
        final secretValue = await supabase.getEnvVarSecret(ev['id'] as String);
        if (secretValue != null) env[key] = secretValue;
      } else if (ev['value'] != null) {
        env[key] = ev['value'] as String;
      }
    }

    // Add built-in env vars
    env['OPENCI_BUILD_ID'] = buildId;
    env['OPENCI_PROJECT_ID'] = projectId;
    if (build['tag_name'] != null) env['OPENCI_TAG'] = build['tag_name'] as String;
    if (build['branch'] != null) env['OPENCI_BRANCH'] = build['branch'] as String;
    if (build['commit_sha'] != null) env['OPENCI_COMMIT_SHA'] = build['commit_sha'] as String;

    // Execute steps
    final shell = Shell(environment: env, verbose: false);

    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      final stepName = step['name'] as String? ?? 'Step ${i + 1}';
      final command = step['run'] as String?;

      if (command == null) continue;

      logger.beginStep(i, stepName);
      await logger.info('▶ Running step: $stepName');

      // Check for cancellation before each step
      if (await supabase.isBuildCancelled(buildId)) {
        await logger.info('Build cancelled by user.');
        logger.endStep();
        await logger.complete('cancelled');
        return;
      }

      try {
        final results = await shell.run(command);
        for (final result in results) {
          if (result.stdout.isNotEmpty) {
            await logger.info(result.stdout.trim());
          }
          if (result.stderr.isNotEmpty) {
            await logger.warning(result.stderr.trim());
          }
        }
        await logger.info('✓ Step completed: $stepName');
        logger.endStep();
      } catch (e, st) {
        await logger.error('✗ Step failed: $stepName\n$e', stackTrace: st.toString());
        logger.endStep();
        await logger.complete('failure');
        return;
      }
    }

    await logger.info('Build completed successfully.');
    await logger.complete('success');
  } catch (e, st) {
    await logger.error('Unexpected error: $e', stackTrace: st.toString());
    await logger.complete('failure');
  }
}

// Minimal YAML step parser — extracts steps[].{name, run} from GitHub Actions YAML.
// Production: replace with a proper YAML package (e.g., yaml: ^3.0.0)
List<Map<String, String>> _parseWorkflowSteps(String yaml) {
  final steps = <Map<String, String>>[];
  final lines = yaml.split('\n');
  bool inSteps = false;
  Map<String, String>? currentStep;

  for (final line in lines) {
    final trimmed = line.trimLeft();

    if (trimmed.startsWith('steps:')) {
      inSteps = true;
      continue;
    }

    if (!inSteps) continue;

    if (trimmed.startsWith('- name:')) {
      if (currentStep != null) steps.add(currentStep);
      currentStep = {'name': trimmed.substring(7).trim()};
    } else if (trimmed.startsWith('run:') && currentStep != null) {
      currentStep['run'] = trimmed.substring(4).trim().replaceAll('|', '').trim();
    }
  }

  if (currentStep != null) steps.add(currentStep);
  return steps;
}

