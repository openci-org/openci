import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:openci_server/build_job/build_job_mapper.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_service.dart';
import 'package:openci_server/github/github_webhook_payload.dart';
import 'package:openci_server/parser/genuine_ci_parser.dart';
import 'package:openci_server/request/error_handler.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:uuid/uuid.dart';

FutureOr<Response> onRequest(RequestContext context, String id) {
  return switch (context.request.method) {
    HttpMethod.post => _post(context, id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _post(RequestContext context, String taskId) async {
  try {
    final db = context.read<AppDatabase>();
    final uid = context.read<String?>();

    if (uid == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'success': false, 'error': 'Authentication required'},
      );
    }

    final task = await (db.select(
      db.webhookTasks,
    )..where((tbl) => tbl.id.equals(taskId))).getSingleOrNull();

    if (task == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'success': false, 'error': 'WebhookTask not found'},
      );
    }

    final Map<String, dynamic> rawJson;
    try {
      rawJson = jsonDecode(task.payload) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Invalid WebhookTask JSON payload: $e');
    }

    final event = GitHubWebhookPayload.fromRawJson(
      eventType: task.eventType,
      rawJson: rawJson,
    );

    if (event.isDeleted) {
      await _completeTask(db, taskId);
      return Response.json(
        body: {
          'success': true,
          'jobs_created': 0,
          'job_ids': <String>[],
          'message': 'Branch deletion event skipped',
        },
      );
    }

    // 2. Resolve team by installation ID
    final allTeams = await db.select(db.teams).get();
    DriftTeam? targetTeam;
    for (final team in allTeams) {
      if (team.installationIds.contains(event.installationId)) {
        targetTeam = team;
        break;
      }
    }

    if (targetTeam == null) {
      await _completeTask(db, taskId);
      return Response.json(
        body: {
          'success': true,
          'jobs_created': 0,
          'job_ids': <String>[],
          'message': 'No team associated with installation ID',
        },
      );
    }

    Map<String, String>? env;
    try {
      env = context.read<Map<String, String>>();
    } catch (_) {
      env = Platform.environment;
    }

    http.Client? client;
    try {
      client = context.read<http.Client>();
    } catch (_) {
      client = null;
    }

    // 3. Fetch genuine_ci/*.dart files from GitHub
    final files = await GitHubService.fetchGenuineCiFiles(
      owner: event.owner,
      repo: event.repo,
      commitSha: event.commitSha,
      installationIdStr: event.installationId.toString(),
      environment: env,
      client: client,
    );

    if (files.isEmpty) {
      await _completeTask(db, taskId);
      return Response.json(
        body: {
          'success': true,
          'jobs_created': 0,
          'job_ids': <String>[],
          'message': 'No genuine_ci/*.dart files found',
        },
      );
    }

    // 4. Parse workflows and match triggers
    final matchingWorkflows = <ParsedWorkflow>[];
    for (final file in files) {
      final parsed = parseGenuineCiWorkflow(file.content, file.name);
      if (parsed == null) continue;

      if (parsed.matches(
        eventType: event.triggerType,
        branch: event.triggerBranch,
      )) {
        matchingWorkflows.add(parsed);
      }
    }

    if (matchingWorkflows.isEmpty) {
      await _completeTask(db, taskId);
      return Response.json(
        body: {
          'success': true,
          'jobs_created': 0,
          'job_ids': <String>[],
          'message': 'No matching workflows for event',
        },
      );
    }

    // 5. Create BuildJob records in DB
    final createdJobIds = <String>[];
    final createdJobs = <DriftBuildJob>[];
    for (final workflow in matchingWorkflows) {
      final jobId = const Uuid().v4();
      final now = DateTime.now().toUtc();

      final buildJob = BuildJob(
        id: jobId,
        status: BuildJobStatus.QUEUED,
        owner: event.owner,
        repo: event.repo,
        workflowName: workflow.workflowName,
        teamId: targetTeam.id,
        workflowFileName: workflow.workflowFileName,
        commitSha: event.commitSha,
        commitMessage: event.commitMessage,
        pullRequestNumber: event.pullRequestNumber,
        runCount: 0,
        branch: event.branch,
        runsOn: 'macos-latest',
        githubBaseUrl: targetTeam.githubBaseUrl ?? 'https://github.com',
        createdAt: now,
        updatedAt: now,
      );

      final driftJob = buildJob.toDrift().copyWith(
        installationId: Value(event.installationId.toString()),
      );

      createdJobs.add(driftJob);
      createdJobIds.add(jobId);
    }

    // 6. Persist jobs and task completion atomically.
    await db.transaction(() async {
      for (final job in createdJobs) {
        await db.buildJobDao.insertBuildJob(job);
      }
      await _completeTask(db, taskId);
    });

    return Response.json(
      body: {
        'success': true,
        'jobs_created': createdJobIds.length,
        'job_ids': createdJobIds,
      },
    );
  } catch (e, s) {
    try {
      final db = context.read<AppDatabase>();
      await db.webhookTaskDao.recordWebhookTaskFailure(
        taskId: taskId,
        errorMessage: '$e\n$s',
      );
    } catch (_) {}

    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to process webhook task $taskId',
    );
  }
}

Future<void> _completeTask(AppDatabase db, String taskId) {
  return (db.update(
    db.webhookTasks,
  )..where((tbl) => tbl.id.equals(taskId))).write(
    WebhookTasksCompanion(
      status: const Value('completed'),
      leaseUntil: const Value(null),
      nextRetryAt: const Value(null),
      errorMessage: const Value(null),
      updatedAt: Value(DateTime.now().toUtc()),
    ),
  );
}
