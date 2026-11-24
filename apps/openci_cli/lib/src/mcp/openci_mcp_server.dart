import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:dart_mcp/server.dart';
import 'package:http/http.dart' as http;

import '../builds/builds_api.dart';
import '../commands/switch/fetch_teams.dart';
import '../credential_store/credential_config.dart';
import '../credential_store/credential_store.dart';
import '../credential_store/read_authenticated_profile.dart';
import '../dataconnect/data_connect_api.dart';
import '../teams/teams_api.dart';
import '../version.dart';

typedef AuthenticatedProfileReader =
    Future<AuthProfile?> Function(CredentialStore store);

final class OpenCIMcpServer extends MCPServer with ToolsSupport {
  static const int defaultListLimit = 20;
  static const int maxListLimit = 100;
  static const int defaultLogLimit = 200;
  static const int maxLogLimit = 1000;
  static const int defaultMaxPages = 10;
  static const int maxAllowedPages = 25;
  static const int maxLogOutputChars = 120000;

  static final _readOnlyAnnotations = ToolAnnotations(
    readOnlyHint: true,
    idempotentHint: true,
    openWorldHint: true,
  );

  static const _prettyJson = JsonEncoder.withIndent('  ');

  OpenCIMcpServer(
    super.channel, {
    CredentialStore? credentialStore,
    AuthenticatedProfileReader? readProfile,
    http.Client Function()? httpClientFactory,
    String? dataConnectEmulatorHost,
    DateTime Function()? now,
  }) : _credentialStore = credentialStore ?? CredentialStore(),
       _readProfile = readProfile ?? readAuthenticatedProfile,
       _httpClientFactory = httpClientFactory ?? http.Client.new,
       _dataConnectEmulatorHost = dataConnectEmulatorHost,
       _now = now ?? DateTime.now,
       super.fromStreamChannel(
         implementation: Implementation(name: 'openci', version: openCIVersion),
         instructions:
             'OpenCI MCP server for inspecting CI/CD builds and build logs. '
             'Recommended workflow: (1) call list_builds (or get_status) to '
             'find the relevant build job and its latestRunId; (2) call '
             'get_build to inspect failureSummary, step statuses, and '
             'lastLogSequence; (3) call get_build_logs with tail (default 200) '
             'or step_id/stream/query filters to read only the relevant log '
             'entries without overflowing context.',
       ) {
    registerTool(_getStatusTool, _handleGetStatus);
    registerTool(_listBuildsTool, _handleListBuilds);
    registerTool(_getBuildTool, _handleGetBuild);
    registerTool(_getBuildLogsTool, _handleGetBuildLogs);
  }

  final CredentialStore _credentialStore;
  final AuthenticatedProfileReader _readProfile;
  final http.Client Function() _httpClientFactory;
  final String? _dataConnectEmulatorHost;
  final DateTime Function() _now;

  static final _getStatusTool = Tool(
    name: 'get_status',
    title: 'Get OpenCI Status',
    description:
        'Show the active OpenCI CLI profile, selected team ID and name, '
        'Firebase project, and whether local emulator mode is active.',
    inputSchema: Schema.object(),
    annotations: _readOnlyAnnotations,
  );

  static final _listBuildsTool = Tool(
    name: 'list_builds',
    title: 'List OpenCI Builds',
    description:
        'List recent build jobs for the active OpenCI team (or a specified '
        'team_id), with optional filtering by status, branch, repo, PR number, '
        'or workflow name.',
    inputSchema: Schema.object(
      properties: {
        'team_id': Schema.string(
          description:
              'Optional team ID override. Defaults to the active CLI team.',
        ),
        'status': Schema.string(
          description:
              'Optional case-insensitive status filter (e.g. FAILURE, SUCCESS, '
              'IN_PROGRESS, QUEUED, CANCELLED, TIMED_OUT).',
        ),
        'branch': Schema.string(
          description: 'Optional exact branch name filter.',
        ),
        'repo': Schema.string(
          description:
              'Optional case-insensitive repository filter (matches repo or '
              'owner/repo).',
        ),
        'pr_number': Schema.int(
          description: 'Optional pull request number filter.',
          minimum: 1,
        ),
        'workflow': Schema.string(
          description:
              'Optional case-insensitive substring filter on workflowName or '
              'workflowFileName.',
        ),
        'limit': Schema.int(
          description:
              'Maximum number of matching builds to return (1-100, default 20).',
          minimum: 1,
          maximum: maxListLimit,
        ),
        'offset': Schema.int(
          description:
              'Offset into the team build history (default 0). Useful for '
              'paginating older builds.',
          minimum: 0,
        ),
      },
    ),
    annotations: _readOnlyAnnotations,
  );

  static final _getBuildTool = Tool(
    name: 'get_build',
    title: 'Get OpenCI Build Details',
    description:
        'Fetch details of a specific build job (including failureSummary, '
        'commit info, and latestRunId) together with its run state, steps '
        '(e.g. prepare_vm, checkout, run_workflow), lastLogSequence, and log '
        'expiration status.',
    inputSchema: Schema.object(
      properties: {
        'job_id': Schema.string(description: 'The build job ID.', minLength: 1),
        'run_id': Schema.string(
          description:
              'Optional specific run ID. Defaults to the job latestRunId.',
          minLength: 1,
        ),
      },
      required: ['job_id'],
    ),
    annotations: _readOnlyAnnotations,
  );

  static final _getBuildLogsTool = Tool(
    name: 'get_build_logs',
    title: 'Get OpenCI Build Logs',
    description:
        'Fetch build logs for an OpenCI build job or run. By default returns '
        'the last 200 log entries (tail mode) in O(1) using lastLogSequence. '
        'Supports forward pagination via after_sequence and filtering by '
        'step_id, stream (stdout/stderr), or case-insensitive substring query.',
    inputSchema: Schema.object(
      properties: {
        'job_id': Schema.string(
          description:
              'Build job ID. Automatically resolves latestRunId and teamId. '
              'Either job_id or run_id must be provided.',
          minLength: 1,
        ),
        'run_id': Schema.string(
          description:
              'Build run ID. Either job_id or run_id must be provided.',
          minLength: 1,
        ),
        'team_id': Schema.string(
          description:
              'Optional team ID override. Defaults to the job team or active '
              'CLI team.',
          minLength: 1,
        ),
        'tail': Schema.int(
          description:
              'Fetch the last N log entries (1-1000, default 200 when '
              'after_sequence is omitted). Cannot be combined with '
              'after_sequence.',
          minimum: 1,
          maximum: maxLogLimit,
        ),
        'after_sequence': Schema.int(
          description:
              'Fetch log entries strictly after this sequence number (0-based '
              'forward pagination). Cannot be combined with tail.',
          minimum: 0,
        ),
        'limit': Schema.int(
          description:
              'Maximum number of log entries to return (1-1000, default 200).',
          minimum: 1,
          maximum: maxLogLimit,
        ),
        'step_id': Schema.string(
          description:
              'Optional step ID filter (e.g. prepare_vm, checkout, '
              'run_workflow).',
          minLength: 1,
        ),
        'stream': UntitledSingleSelectEnumSchema(
          description: 'Optional stream filter: stdout or stderr.',
          values: ['stdout', 'stderr'],
        ),
        'query': Schema.string(
          description:
              'Optional case-insensitive substring filter applied to log '
              'messages.',
          minLength: 1,
        ),
        'max_pages': Schema.int(
          description:
              'Maximum number of 200-entry pages to scan when filtering '
              '(1-25, default 10).',
          minimum: 1,
          maximum: maxAllowedPages,
        ),
      },
    ),
    annotations: _readOnlyAnnotations,
  );

  Future<CallToolResult> _handleGetStatus(CallToolRequest request) async {
    final context = await _loadAuthContext();
    if (context.error != null) return context.error!;
    final profile = context.profile!;

    String? projectId;
    try {
      projectId = firebaseProjectIdFromProfile(profile);
    } on FormatException {
      projectId = null;
    }

    String? teamName;
    String? teamNameError;
    if (profile.teamId.trim().isNotEmpty) {
      final client = _httpClientFactory();
      final teamsApi = TeamsApi(profile, client: client);
      try {
        final teams = await fetchTeams(teamsApi);
        final match = teams
            .where((team) => team.id == profile.teamId)
            .firstOrNull;
        teamName = match?.name;
        if (teamName == null) {
          teamNameError = teams.isEmpty
              ? 'No teams found for this account.'
              : 'Selected team ID was not found in your memberships.';
        }
      } on TeamsHttpException catch (error) {
        teamNameError = 'Could not fetch team name (HTTP ${error.statusCode}).';
      } catch (_) {
        teamNameError = 'Could not fetch team name.';
      } finally {
        teamsApi.dispose();
      }
    }

    return _jsonResult({
      'profile': context.profileName,
      'teamId': profile.teamId.trim().isEmpty ? null : profile.teamId,
      'teamName': ?teamName,
      'teamNameError': ?teamNameError,
      'firebaseProjectId': ?projectId,
      'region': profile.functionsRegion,
      'localEmulator':
          profile.firebaseAuthEmulatorHost != null ||
          _dataConnectEmulatorHost != null,
    });
  }

  Future<CallToolResult> _handleListBuilds(CallToolRequest request) async {
    final context = await _loadAuthContext();
    if (context.error != null) return context.error!;
    final profile = context.profile!;

    final args = request.arguments ?? const <String, Object?>{};
    final teamId = _trimOrNull(args['team_id'] as String?) ?? profile.teamId;
    if (teamId.trim().isEmpty) {
      return _errorResult(
        'No team is selected. Run `openci switch team` in your terminal or '
        'pass `team_id`.',
      );
    }

    final statusFilter = _trimOrNull(args['status'] as String?)?.toLowerCase();
    final branchFilter = _trimOrNull(args['branch'] as String?);
    final repoFilter = _trimOrNull(args['repo'] as String?)?.toLowerCase();
    final prNumberFilter = args['pr_number'] as int?;
    final workflowFilter = _trimOrNull(
      args['workflow'] as String?,
    )?.toLowerCase();
    final limit = (args['limit'] as int? ?? defaultListLimit).clamp(
      1,
      maxListLimit,
    );
    final offset = math.max(0, args['offset'] as int? ?? 0);

    final hasFilter =
        statusFilter != null ||
        branchFilter != null ||
        repoFilter != null ||
        prNumberFilter != null ||
        workflowFilter != null;
    final fetchLimit = hasFilter ? BuildsApi.maxPageSize : limit;

    return _withBuildsApi(profile, (buildsApi) async {
      final fetched = await buildsApi.listBuildJobs(
        teamId: teamId,
        offset: offset,
        limit: fetchLimit,
      );

      final matches = <BuildJobSummary>[];
      for (final job in fetched) {
        if (statusFilter != null && job.status.toLowerCase() != statusFilter) {
          continue;
        }
        if (branchFilter != null && job.branch != branchFilter) {
          continue;
        }
        if (repoFilter != null) {
          final fullRepo = '${job.owner}/${job.repo}'.toLowerCase();
          if (job.repo.toLowerCase() != repoFilter && fullRepo != repoFilter) {
            continue;
          }
        }
        if (prNumberFilter != null && job.pullRequestNumber != prNumberFilter) {
          continue;
        }
        if (workflowFilter != null &&
            !job.workflowName.toLowerCase().contains(workflowFilter) &&
            !job.workflowFileName.toLowerCase().contains(workflowFilter)) {
          continue;
        }
        matches.add(job);
        if (matches.length >= limit) break;
      }

      return _jsonResult({
        'teamId': teamId,
        'offset': offset,
        'scannedCount': fetched.length,
        'count': matches.length,
        'hasMore': fetched.length == fetchLimit,
        'builds': matches.map(_compactBuildSummary).toList(),
      });
    });
  }

  Future<CallToolResult> _handleGetBuild(CallToolRequest request) async {
    final context = await _loadAuthContext();
    if (context.error != null) return context.error!;
    final profile = context.profile!;

    final args = request.arguments ?? const <String, Object?>{};
    final jobId = _trimOrNull(args['job_id'] as String?);
    if (jobId == null) {
      return _errorResult('job_id must not be empty.');
    }
    final requestedRunId = _trimOrNull(args['run_id'] as String?);

    return _withBuildsApi(profile, (buildsApi) async {
      final job = await buildsApi.getBuildJob(jobId);
      if (job == null) {
        return _errorResult('Build job "$jobId" was not found.');
      }

      final effectiveRunId = requestedRunId ?? job.latestRunId;
      final effectiveTeamId = job.teamId ?? profile.teamId;
      BuildLogStateSummary? runState;
      String? logStateError;

      if (effectiveRunId != null &&
          effectiveRunId.isNotEmpty &&
          effectiveTeamId.trim().isNotEmpty) {
        try {
          runState = await buildsApi.getBuildLogState(
            teamId: effectiveTeamId,
            jobId: job.id,
            runId: effectiveRunId,
          );
        } on DataConnectGraphQLException catch (error) {
          logStateError = error.messages.join('; ');
        } on DataConnectHttpException catch (error) {
          logStateError =
              'Could not fetch build log state (HTTP ${error.statusCode}).';
        } catch (_) {
          logStateError = 'Could not fetch build log state.';
        }
      }

      return _jsonResult({
        'job': job.toJson(),
        'run': runState?.toJson(),
        'logStateError': ?logStateError,
      });
    });
  }

  Future<CallToolResult> _handleGetBuildLogs(CallToolRequest request) async {
    final context = await _loadAuthContext();
    if (context.error != null) return context.error!;
    final profile = context.profile!;

    final args = request.arguments ?? const <String, Object?>{};
    final jobId = _trimOrNull(args['job_id'] as String?);
    final requestedRunId = _trimOrNull(args['run_id'] as String?);
    if (jobId == null && requestedRunId == null) {
      return _errorResult('Provide either `job_id` or `run_id`.');
    }

    final tailArg = args['tail'] as int?;
    final afterSequenceArg = args['after_sequence'] as int?;
    if (tailArg != null && afterSequenceArg != null) {
      return _errorResult(
        'Cannot combine `tail` and `after_sequence`. Use `tail` for the latest '
        'entries or `after_sequence` for forward pagination.',
      );
    }

    final limitArg = args['limit'] as int?;
    final stepIdFilter = _trimOrNull(args['step_id'] as String?);
    final streamFilter = _trimOrNull(args['stream'] as String?)?.toLowerCase();
    final queryFilter = _trimOrNull(args['query'] as String?)?.toLowerCase();
    final maxPages = (args['max_pages'] as int? ?? defaultMaxPages).clamp(
      1,
      maxAllowedPages,
    );

    final hasFilter =
        stepIdFilter != null || streamFilter != null || queryFilter != null;

    bool matchesFilter(BuildLogEntry entry) {
      if (stepIdFilter != null && entry.stepId != stepIdFilter) return false;
      if (streamFilter != null && entry.stream.toLowerCase() != streamFilter) {
        return false;
      }
      if (queryFilter != null &&
          !entry.message.toLowerCase().contains(queryFilter)) {
        return false;
      }
      return true;
    }

    return _withBuildsApi(profile, (buildsApi) async {
      var teamId = _trimOrNull(args['team_id'] as String?);
      var runId = requestedRunId;
      BuildJobSummary? job;

      if (jobId != null && (runId == null || teamId == null)) {
        job = await buildsApi.getBuildJob(jobId);
        if (job == null) {
          return _errorResult('Build job "$jobId" was not found.');
        }
        runId ??= job.latestRunId;
        teamId ??= job.teamId;
      }

      teamId ??= profile.teamId;
      if (teamId.trim().isEmpty) {
        return _errorResult(
          'No team is selected. Run `openci switch team` in your terminal or '
          'pass `team_id`.',
        );
      }

      if (runId == null || runId.isEmpty) {
        return _jsonResult({
          'jobId': ?jobId,
          if (job != null) 'jobStatus': job.status,
          'runId': null,
          'returnedCount': 0,
          'note': 'This build job does not have a run yet.',
        });
      }

      if (afterSequenceArg != null) {
        final limit = (limitArg ?? defaultLogLimit).clamp(1, maxLogLimit);
        return _fetchForwardLogs(
          buildsApi: buildsApi,
          teamId: teamId,
          jobId: jobId,
          runId: runId,
          afterSequence: afterSequenceArg,
          limit: limit,
          maxPages: maxPages,
          hasFilter: hasFilter,
          matchesFilter: matchesFilter,
        );
      }

      final targetCount = (tailArg ?? limitArg ?? defaultLogLimit).clamp(
        1,
        maxLogLimit,
      );
      if (!hasFilter) {
        return _fetchTailLogs(
          buildsApi: buildsApi,
          teamId: teamId,
          jobId: jobId,
          runId: runId,
          tail: targetCount,
        );
      }

      return _fetchFilteredTailLogs(
        buildsApi: buildsApi,
        teamId: teamId,
        jobId: jobId,
        runId: runId,
        limit: targetCount,
        maxPages: maxPages,
        matchesFilter: matchesFilter,
      );
    });
  }

  Future<CallToolResult> _fetchForwardLogs({
    required BuildsApi buildsApi,
    required String teamId,
    required String? jobId,
    required String runId,
    required int afterSequence,
    required int limit,
    required int maxPages,
    required bool hasFilter,
    required bool Function(BuildLogEntry) matchesFilter,
  }) async {
    final entries = <BuildLogEntry>[];
    var cursor = afterSequence;
    var lastLogSequence = 0;
    String? logsExpireAt;
    var expired = false;
    var pagesFetched = 0;
    final pageBudget = hasFilter
        ? maxPages
        : math.max(maxPages, (limit / BuildsApi.maxPageSize).ceil());

    while (entries.length < limit && pagesFetched < pageBudget) {
      final fetchSize = hasFilter
          ? BuildsApi.maxPageSize
          : math.min(BuildsApi.maxPageSize, limit - entries.length);
      final page = await buildsApi.getBuildLogs(
        teamId: teamId,
        runId: runId,
        afterSequence: cursor,
        limit: fetchSize,
      );
      pagesFetched++;
      lastLogSequence = page.lastLogSequence;
      logsExpireAt = page.logsExpireAt;
      expired = page.expired;

      if (page.entries.isEmpty) break;

      var lastConsumedSequence = cursor;
      for (final entry in page.entries) {
        lastConsumedSequence = entry.sequence;
        if (matchesFilter(entry)) {
          entries.add(entry);
          if (entries.length >= limit) break;
        }
      }
      cursor = lastConsumedSequence;

      if (cursor >= lastLogSequence || page.entries.length < fetchSize) {
        if (entries.length < limit) break;
      }
    }

    return _formatLogsResult(
      jobId: jobId,
      runId: runId,
      mode: 'forward',
      entries: entries,
      lastLogSequence: lastLogSequence,
      logsExpireAt: logsExpireAt,
      expired: expired,
      pagesFetched: pagesFetched,
      nextAfterSequence: cursor,
      hasMore: cursor < lastLogSequence,
      keepTailOnTruncate: false,
    );
  }

  Future<CallToolResult> _fetchTailLogs({
    required BuildsApi buildsApi,
    required String teamId,
    required String? jobId,
    required String runId,
    required int tail,
  }) async {
    final head = await _readLogMetadata(
      buildsApi: buildsApi,
      teamId: teamId,
      jobId: jobId,
      runId: runId,
    );
    final lastLogSequence = head.lastLogSequence;
    if (lastLogSequence <= 0) {
      return _formatLogsResult(
        jobId: jobId,
        runId: runId,
        mode: 'tail',
        entries: const [],
        lastLogSequence: lastLogSequence,
        logsExpireAt: head.logsExpireAt,
        expired: head.expired,
        pagesFetched: 0,
        hasMore: false,
        keepTailOnTruncate: true,
        steps: head.steps,
      );
    }

    final startAfter = math.max(0, lastLogSequence - tail);
    final entries = <BuildLogEntry>[];
    var cursor = startAfter;
    var pagesFetched = 0;

    while (entries.length < tail && cursor < lastLogSequence) {
      final fetchSize = math.min(BuildsApi.maxPageSize, tail - entries.length);
      final page = await buildsApi.getBuildLogs(
        teamId: teamId,
        runId: runId,
        afterSequence: cursor,
        limit: fetchSize,
      );
      pagesFetched++;
      if (page.entries.isEmpty) break;
      entries.addAll(page.entries);
      cursor = page.entries.last.sequence;
      if (page.entries.length < fetchSize) break;
    }

    return _formatLogsResult(
      jobId: jobId,
      runId: runId,
      mode: 'tail',
      entries: entries,
      lastLogSequence: lastLogSequence,
      logsExpireAt: head.logsExpireAt,
      expired: head.expired,
      pagesFetched: pagesFetched,
      scannedFromSequence: startAfter + 1,
      scannedToSequence: lastLogSequence,
      hasOlderUnscanned: startAfter > 0,
      hasMore: false,
      keepTailOnTruncate: true,
      steps: head.steps,
    );
  }

  Future<CallToolResult> _fetchFilteredTailLogs({
    required BuildsApi buildsApi,
    required String teamId,
    required String? jobId,
    required String runId,
    required int limit,
    required int maxPages,
    required bool Function(BuildLogEntry) matchesFilter,
  }) async {
    final head = await _readLogMetadata(
      buildsApi: buildsApi,
      teamId: teamId,
      jobId: jobId,
      runId: runId,
    );
    final lastLogSequence = head.lastLogSequence;
    if (lastLogSequence <= 0) {
      return _formatLogsResult(
        jobId: jobId,
        runId: runId,
        mode: 'tail_filtered',
        entries: const [],
        lastLogSequence: lastLogSequence,
        logsExpireAt: head.logsExpireAt,
        expired: head.expired,
        pagesFetched: 0,
        hasMore: false,
        keepTailOnTruncate: true,
        steps: head.steps,
      );
    }

    // Collect matching entries from newest window backward so recent errors
    // are found first without scanning an entire multi-megabyte log.
    final reversedMatches = <BuildLogEntry>[];
    var windowEnd = lastLogSequence;
    var scannedFrom = lastLogSequence + 1;
    var pagesFetched = 0;

    while (windowEnd > 0 &&
        pagesFetched < maxPages &&
        reversedMatches.length < limit) {
      final windowAfter = math.max(0, windowEnd - BuildsApi.maxPageSize);
      final windowLimit = math.min(
        BuildsApi.maxPageSize,
        windowEnd - windowAfter,
      );
      final page = await buildsApi.getBuildLogs(
        teamId: teamId,
        runId: runId,
        afterSequence: windowAfter,
        limit: windowLimit,
      );
      pagesFetched++;
      scannedFrom = windowAfter + 1;

      for (var i = page.entries.length - 1; i >= 0; i--) {
        final entry = page.entries[i];
        if (entry.sequence > windowEnd) continue;
        if (matchesFilter(entry)) {
          reversedMatches.add(entry);
          if (reversedMatches.length >= limit) break;
        }
      }

      if (page.entries.isEmpty && head.expired) {
        break;
      }
      windowEnd = windowAfter;
    }

    final chronological = reversedMatches.reversed.toList();
    return _formatLogsResult(
      jobId: jobId,
      runId: runId,
      mode: 'tail_filtered',
      entries: chronological,
      lastLogSequence: lastLogSequence,
      logsExpireAt: head.logsExpireAt,
      expired: head.expired,
      pagesFetched: pagesFetched,
      scannedFromSequence: scannedFrom <= lastLogSequence ? scannedFrom : null,
      scannedToSequence: lastLogSequence,
      hasOlderUnscanned: windowEnd > 0,
      hasMore: false,
      keepTailOnTruncate: true,
      steps: head.steps,
    );
  }

  Future<_LogMetadata> _readLogMetadata({
    required BuildsApi buildsApi,
    required String teamId,
    required String? jobId,
    required String runId,
  }) async {
    if (jobId != null) {
      final state = await buildsApi.getBuildLogState(
        teamId: teamId,
        jobId: jobId,
        runId: runId,
      );
      return _LogMetadata(
        lastLogSequence: state.lastLogSequence,
        logsExpireAt: state.logsExpireAt,
        expired: state.expired,
        steps: state.steps,
      );
    }
    final probe = await buildsApi.getBuildLogs(
      teamId: teamId,
      runId: runId,
      afterSequence: 0,
      limit: 1,
    );
    return _LogMetadata(
      lastLogSequence: probe.lastLogSequence,
      logsExpireAt: probe.logsExpireAt,
      expired: probe.expired,
    );
  }

  CallToolResult _formatLogsResult({
    required String? jobId,
    required String runId,
    required String mode,
    required List<BuildLogEntry> entries,
    required int lastLogSequence,
    required String? logsExpireAt,
    required bool expired,
    required int pagesFetched,
    required bool hasMore,
    required bool keepTailOnTruncate,
    int? nextAfterSequence,
    int? scannedFromSequence,
    int? scannedToSequence,
    bool? hasOlderUnscanned,
    List<BuildStepSummary>? steps,
  }) {
    final formattedLines = entries.map(_formatLogEntry).toList();
    var included = formattedLines;
    var includedEntries = entries;
    var truncated = false;

    final totalChars = formattedLines.fold<int>(
      0,
      (sum, line) => sum + line.length + 1,
    );
    if (totalChars > maxLogOutputChars) {
      truncated = true;
      var budget = maxLogOutputChars;
      if (keepTailOnTruncate) {
        final keptLines = <String>[];
        final keptEntries = <BuildLogEntry>[];
        for (var i = formattedLines.length - 1; i >= 0; i--) {
          final line = formattedLines[i];
          if (keptLines.isNotEmpty && line.length + 1 > budget) break;
          keptLines.add(
            line.length > budget
                ? '${line.substring(0, math.max(0, budget - 16))}... [truncated]'
                : line,
          );
          keptEntries.add(entries[i]);
          budget -= line.length + 1;
          if (budget <= 0) break;
        }
        included = keptLines.reversed.toList();
        includedEntries = keptEntries.reversed.toList();
      } else {
        final keptLines = <String>[];
        final keptEntries = <BuildLogEntry>[];
        for (var i = 0; i < formattedLines.length; i++) {
          final line = formattedLines[i];
          if (keptLines.isNotEmpty && line.length + 1 > budget) break;
          keptLines.add(
            line.length > budget
                ? '${line.substring(0, math.max(0, budget - 16))}... [truncated]'
                : line,
          );
          keptEntries.add(entries[i]);
          budget -= line.length + 1;
          if (budget <= 0) break;
        }
        included = keptLines;
        includedEntries = keptEntries;
      }
    }

    final effectiveNextAfter = !keepTailOnTruncate && truncated
        ? (includedEntries.isNotEmpty
              ? includedEntries.last.sequence
              : nextAfterSequence)
        : nextAfterSequence;
    final effectiveHasMore =
        hasMore ||
        (!keepTailOnTruncate &&
            truncated &&
            effectiveNextAfter != null &&
            effectiveNextAfter < lastLogSequence);

    final metadata = <String, Object?>{
      'jobId': ?jobId,
      'runId': runId,
      'mode': mode,
      'lastLogSequence': lastLogSequence,
      'logsExpireAt': ?logsExpireAt,
      'expired': expired,
      'returnedCount': includedEntries.length,
      if (includedEntries.isNotEmpty) ...{
        'firstSequence': includedEntries.first.sequence,
        'lastSequence': includedEntries.last.sequence,
      },
      'scannedFromSequence': ?scannedFromSequence,
      'scannedToSequence': ?scannedToSequence,
      'hasOlderUnscanned': ?hasOlderUnscanned,
      'nextAfterSequence': ?effectiveNextAfter,
      'hasMore': effectiveHasMore,
      'pagesFetched': pagesFetched,
      if (truncated) 'outputTruncated': true,
      if (expired && includedEntries.isEmpty)
        'note':
            'Build logs for this run have expired (14-day retention) and '
            'their bodies have been removed.',
      if (steps != null)
        'steps': steps
            .map(
              (s) => {
                'stepId': s.stepId,
                'name': s.name,
                'status': s.status,
                'durationMs': s.durationMs,
              },
            )
            .toList(),
    };

    final buffer = StringBuffer(_prettyJson.convert(metadata));
    if (included.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('---')
        ..write(included.join('\n'));
    }
    return CallToolResult(content: [TextContent(text: buffer.toString())]);
  }

  Future<CallToolResult> _withBuildsApi(
    AuthProfile profile,
    Future<CallToolResult> Function(BuildsApi buildsApi) action,
  ) async {
    final httpClient = _httpClientFactory();
    final dataConnect = DataConnectApi(
      profile,
      client: httpClient,
      emulatorHost: _dataConnectEmulatorHost,
    );
    final buildsApi = BuildsApi(dataConnect, now: _now);
    try {
      return await action(buildsApi);
    } on DataConnectHttpException catch (error) {
      if (error.statusCode == HttpStatus.unauthorized ||
          error.statusCode == HttpStatus.forbidden) {
        return _errorResult(
          'Authentication failed (HTTP ${error.statusCode}). Run `openci login` '
          '(or `openci login --local`) in your terminal and retry.',
        );
      }
      return _errorResult(
        'OpenCI Data Connect request failed (HTTP ${error.statusCode}).',
      );
    } on DataConnectGraphQLException catch (error) {
      return _errorResult('OpenCI query failed: ${error.messages.join('; ')}');
    } on FormatException catch (error) {
      return _errorResult(
        'Invalid OpenCI configuration or response: ${error.message}',
      );
    } on TimeoutException {
      return _errorResult('OpenCI request timed out.');
    } catch (_) {
      return _errorResult(
        'Could not connect to OpenCI. Check your network connection or local '
        'emulator status.',
      );
    } finally {
      buildsApi.dispose();
      httpClient.close();
    }
  }

  Future<_AuthContext> _loadAuthContext() async {
    try {
      final config = await _credentialStore.get();
      if (config.profiles.isEmpty) {
        return _AuthContext.error(
          _errorResult(
            'No OpenCI CLI profile is configured. Run `openci login` '
            '(or `openci login --local`) in your terminal first.',
          ),
        );
      }
      final profile = await _readProfile(_credentialStore);
      if (profile == null ||
          profile.authType != 'firebase' ||
          profile.token.trim().isEmpty) {
        return _AuthContext.error(
          _errorResult(
            'OpenCI Firebase login is required. Run `openci login` '
            '(or `openci login --local`) in your terminal first.',
          ),
        );
      }
      return _AuthContext.ok(config.activeProfile, profile);
    } catch (_) {
      // Never expose credentials, tokens, or file contents in tool errors.
      return _AuthContext.error(
        _errorResult(
          'Could not read or refresh OpenCI credentials. Run `openci login` '
          '(or `openci login --local`) in your terminal first.',
        ),
      );
    }
  }
}

class _AuthContext {
  const _AuthContext.ok(this.profileName, this.profile) : error = null;
  const _AuthContext.error(this.error) : profileName = null, profile = null;

  final String? profileName;
  final AuthProfile? profile;
  final CallToolResult? error;
}

class _LogMetadata {
  const _LogMetadata({
    required this.lastLogSequence,
    required this.expired,
    this.logsExpireAt,
    this.steps,
  });

  final int lastLogSequence;
  final String? logsExpireAt;
  final bool expired;
  final List<BuildStepSummary>? steps;
}

Map<String, Object?> _compactBuildSummary(BuildJobSummary job) => {
  'id': job.id,
  if (job.latestRunId != null) 'latestRunId': job.latestRunId,
  'status': job.status,
  'repo': '${job.owner}/${job.repo}',
  'workflowName': job.workflowName,
  'workflowFileName': job.workflowFileName,
  if (job.branch != null) 'branch': job.branch,
  if (job.tagName != null) 'tagName': job.tagName,
  if (job.pullRequestNumber != null) 'pullRequestNumber': job.pullRequestNumber,
  if (job.commitSha != null) 'commitSha': job.commitSha,
  if (job.commitMessage != null) 'commitMessage': job.commitMessage,
  if (job.matrixLabel != null) 'matrixLabel': job.matrixLabel,
  if (job.failureSummary != null) 'failureSummary': job.failureSummary,
  'retryCount': job.retryCount,
  'createdAt': job.createdAt,
  'updatedAt': job.updatedAt,
  if (job.completedAt != null) 'completedAt': job.completedAt,
};

String _formatLogEntry(BuildLogEntry entry) {
  final stepPart = entry.stepId == null ? '' : ' step=${entry.stepId}';
  final message = entry.message.replaceFirst(RegExp(r'\r?\n$'), '');
  return '[seq=${entry.sequence}$stepPart ${entry.stream}] $message';
}

String? _trimOrNull(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

CallToolResult _jsonResult(Map<String, Object?> data) => CallToolResult(
  content: [TextContent(text: OpenCIMcpServer._prettyJson.convert(data))],
);

CallToolResult _errorResult(String message) =>
    CallToolResult(isError: true, content: [TextContent(text: message)]);
