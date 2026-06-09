import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:openci_server/database.dart';
import 'package:openci_server/log_stream_manager.dart';
import 'package:openci_server/storage.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

Router getRouter(
  StorageManager storage, {
  required AppDatabase db,
  Map<String, String>? environment,
}) {
  final router = Router();
  final env = environment ?? Platform.environment;
  final appEnv = env['APP_ENV'] ?? 'development';

  router.get('/', (Request request) {
    return Response.ok(
      'OpenCI Server (Shelf) is running!\n',
      headers: {'content-type': 'text/plain'},
    );
  });

  router.post('/test-upload', (Request request) async {
    if (appEnv == 'production') {
      return Response.forbidden(
        jsonEncode({
          'success': false,
          'error': 'Test upload is disabled in production environment.',
        }),
        headers: {'content-type': 'application/json'},
      );
    }

    try {
      final testFileName = 'test_${DateTime.now().millisecondsSinceEpoch}.txt';
      final testContent =
          'Hello, this is a test artifact uploaded from OpenCI Server!';
      final stream = Stream.value(Uint8List.fromList(utf8.encode(testContent)));

      await storage.uploadObject(
        testFileName,
        stream,
        size: testContent.length,
      );

      final downloadUrl = await storage.getPresignedUrl(testFileName);

      return Response.ok(
        jsonEncode({
          'success': true,
          'file': testFileName,
          'downloadUrl': downloadUrl,
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e, s) {
      stderr.writeln('Test upload failed: $e\n$s');
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'Internal server error',
        }),
        headers: {'content-type': 'application/json'},
      );
    }
  });

  // POST /builds - ジョブの新規登録
  router.post('/builds', (Request request) async {
    try {
      final payload =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final job = BuildJob.fromJson(payload);
      final driftJob = DriftBuildJob(
        id: job.id,
        status: job.status,
        owner: job.owner,
        repo: job.repo,
        workflowName: job.workflowName,
        teamId: job.teamId,
        workflowId: job.workflowId,
        workflowFileName: job.workflowFileName,
        commitSha: job.commitSha,
        pullRequestNumber: job.pullRequestNumber,
        runCount: job.runCount,
        latestRunId: job.latestRunId,
        tagName: job.tagName,
        branch: job.branch,
        jobKey: job.jobKey,
        workflowJobKey: job.workflowJobKey,
        matrix: job.matrix,
        matrixLabel: job.matrixLabel,
        workflowRunId: job.workflowRunId,
        needs: job.needs,
        failureSummary: job.failureSummary,
        failureSummaryModel: job.failureSummaryModel,
        failureSummaryStatus: job.failureSummaryStatus,
        failureSummaryDurationMs: job.failureSummaryDurationMs,
        provisionedUdids: job.provisionedUdids,
        ipaUrl: job.ipaUrl,
        hasIpa: job.hasIpa,
        bundleId: job.bundleId,
        ipaVersion: job.ipaVersion,
        appName: job.appName,
        githubBaseUrl: job.githubBaseUrl,
        githubApiBaseUrl: job.githubApiBaseUrl,
        createdAt: job.createdAt,
        updatedAt: job.updatedAt,
        completedAt: job.completedAt,
      );

      await db.insertBuildJob(driftJob);

      return Response.ok(
        jsonEncode({'success': true, 'id': job.id}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e, s) {
      stderr.writeln('Failed to insert build job: $e\n$s');
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'Internal server error',
        }),
        headers: {'content-type': 'application/json'},
      );
    }
  });

  // GET /builds/<buildJobId> - ジョブ情報の取得
  router.get('/builds/<buildJobId>', (
    Request request,
    String buildJobId,
  ) async {
    try {
      final driftJob = await db.getBuildJob(buildJobId);
      if (driftJob == null) {
        return Response.notFound(
          jsonEncode({'success': false, 'error': 'Build job not found'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final job = BuildJob(
        id: driftJob.id,
        status: driftJob.status,
        owner: driftJob.owner,
        repo: driftJob.repo,
        workflowName: driftJob.workflowName,
        teamId: driftJob.teamId,
        workflowId: driftJob.workflowId,
        workflowFileName: driftJob.workflowFileName,
        commitSha: driftJob.commitSha,
        pullRequestNumber: driftJob.pullRequestNumber,
        runCount: driftJob.runCount,
        latestRunId: driftJob.latestRunId,
        tagName: driftJob.tagName,
        branch: driftJob.branch,
        jobKey: driftJob.jobKey,
        workflowJobKey: driftJob.workflowJobKey,
        matrix: driftJob.matrix,
        matrixLabel: driftJob.matrixLabel,
        workflowRunId: driftJob.workflowRunId,
        needs: driftJob.needs,
        failureSummary: driftJob.failureSummary,
        failureSummaryModel: driftJob.failureSummaryModel,
        failureSummaryStatus: driftJob.failureSummaryStatus,
        failureSummaryDurationMs: driftJob.failureSummaryDurationMs,
        provisionedUdids: driftJob.provisionedUdids,
        ipaUrl: driftJob.ipaUrl,
        hasIpa: driftJob.hasIpa,
        bundleId: driftJob.bundleId,
        ipaVersion: driftJob.ipaVersion,
        appName: driftJob.appName,
        githubBaseUrl: driftJob.githubBaseUrl,
        githubApiBaseUrl: driftJob.githubApiBaseUrl,
        createdAt: driftJob.createdAt,
        updatedAt: driftJob.updatedAt,
        completedAt: driftJob.completedAt,
      );

      return Response.ok(
        jsonEncode(job.toJson()),
        headers: {'content-type': 'application/json'},
      );
    } catch (e, s) {
      stderr.writeln('Failed to get build job $buildJobId: $e\n$s');
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'Internal server error',
        }),
        headers: {'content-type': 'application/json'},
      );
    }
  });

  // PATCH /builds/<buildJobId> - ジョブの部分更新
  router.patch('/builds/<buildJobId>', (
    Request request,
    String buildJobId,
  ) async {
    try {
      final payload =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final driftJob = await db.getBuildJob(buildJobId);
      if (driftJob == null) {
        return Response.notFound(
          jsonEncode({'success': false, 'error': 'Build job not found'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final job = BuildJob(
        id: driftJob.id,
        status: driftJob.status,
        owner: driftJob.owner,
        repo: driftJob.repo,
        workflowName: driftJob.workflowName,
        teamId: driftJob.teamId,
        workflowId: driftJob.workflowId,
        workflowFileName: driftJob.workflowFileName,
        commitSha: driftJob.commitSha,
        pullRequestNumber: driftJob.pullRequestNumber,
        runCount: driftJob.runCount,
        latestRunId: driftJob.latestRunId,
        tagName: driftJob.tagName,
        branch: driftJob.branch,
        jobKey: driftJob.jobKey,
        workflowJobKey: driftJob.workflowJobKey,
        matrix: driftJob.matrix,
        matrixLabel: driftJob.matrixLabel,
        workflowRunId: driftJob.workflowRunId,
        needs: driftJob.needs,
        failureSummary: driftJob.failureSummary,
        failureSummaryModel: driftJob.failureSummaryModel,
        failureSummaryStatus: driftJob.failureSummaryStatus,
        failureSummaryDurationMs: driftJob.failureSummaryDurationMs,
        provisionedUdids: driftJob.provisionedUdids,
        ipaUrl: driftJob.ipaUrl,
        hasIpa: driftJob.hasIpa,
        bundleId: driftJob.bundleId,
        ipaVersion: driftJob.ipaVersion,
        appName: driftJob.appName,
        githubBaseUrl: driftJob.githubBaseUrl,
        githubApiBaseUrl: driftJob.githubApiBaseUrl,
        createdAt: driftJob.createdAt,
        updatedAt: driftJob.updatedAt,
        completedAt: driftJob.completedAt,
      );

      final updatedJob = job.copyWith(
        status: payload.containsKey('status')
            ? BuildJobStatus.values.byName(payload['status'] as String)
            : job.status,
        latestRunId: payload.containsKey('latestRunId')
            ? payload['latestRunId'] as String?
            : job.latestRunId,
        runCount: payload.containsKey('runCount')
            ? payload['runCount'] as int?
            : job.runCount,
        failureSummary: payload.containsKey('failureSummary')
            ? payload['failureSummary'] as String?
            : job.failureSummary,
        failureSummaryModel: payload.containsKey('failureSummaryModel')
            ? payload['failureSummaryModel'] as String?
            : job.failureSummaryModel,
        failureSummaryStatus: payload.containsKey('failureSummaryStatus')
            ? payload['failureSummaryStatus'] as String?
            : job.failureSummaryStatus,
        failureSummaryDurationMs:
            payload.containsKey('failureSummaryDurationMs')
            ? payload['failureSummaryDurationMs'] as int?
            : job.failureSummaryDurationMs,
        ipaUrl: payload.containsKey('ipaUrl')
            ? payload['ipaUrl'] as String?
            : job.ipaUrl,
        hasIpa: payload.containsKey('hasIpa')
            ? payload['hasIpa'] as bool?
            : job.hasIpa,
        bundleId: payload.containsKey('bundleId')
            ? payload['bundleId'] as String?
            : job.bundleId,
        ipaVersion: payload.containsKey('ipaVersion')
            ? payload['ipaVersion'] as String?
            : job.ipaVersion,
        appName: payload.containsKey('appName')
            ? payload['appName'] as String?
            : job.appName,
        updatedAt: DateTime.now().toUtc(),
        completedAt: payload.containsKey('completedAt')
            ? (payload['completedAt'] != null
                  ? DateTime.parse(payload['completedAt'] as String)
                  : null)
            : job.completedAt,
      );

      final updatedDriftJob = DriftBuildJob(
        id: updatedJob.id,
        status: updatedJob.status,
        owner: updatedJob.owner,
        repo: updatedJob.repo,
        workflowName: updatedJob.workflowName,
        teamId: updatedJob.teamId,
        workflowId: updatedJob.workflowId,
        workflowFileName: updatedJob.workflowFileName,
        commitSha: updatedJob.commitSha,
        pullRequestNumber: updatedJob.pullRequestNumber,
        runCount: updatedJob.runCount,
        latestRunId: updatedJob.latestRunId,
        tagName: updatedJob.tagName,
        branch: updatedJob.branch,
        jobKey: updatedJob.jobKey,
        workflowJobKey: updatedJob.workflowJobKey,
        matrix: updatedJob.matrix,
        matrixLabel: updatedJob.matrixLabel,
        workflowRunId: updatedJob.workflowRunId,
        needs: updatedJob.needs,
        failureSummary: updatedJob.failureSummary,
        failureSummaryModel: updatedJob.failureSummaryModel,
        failureSummaryStatus: updatedJob.failureSummaryStatus,
        failureSummaryDurationMs: updatedJob.failureSummaryDurationMs,
        provisionedUdids: updatedJob.provisionedUdids,
        ipaUrl: updatedJob.ipaUrl,
        hasIpa: updatedJob.hasIpa,
        bundleId: updatedJob.bundleId,
        ipaVersion: updatedJob.ipaVersion,
        appName: updatedJob.appName,
        githubBaseUrl: updatedJob.githubBaseUrl,
        githubApiBaseUrl: updatedJob.githubApiBaseUrl,
        createdAt: updatedJob.createdAt,
        updatedAt: updatedJob.updatedAt,
        completedAt: updatedJob.completedAt,
      );

      await db.updateBuildJob(updatedDriftJob);

      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e, s) {
      stderr.writeln('Failed to patch build job $buildJobId: $e\n$s');
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'Internal server error',
        }),
        headers: {'content-type': 'application/json'},
      );
    }
  });

  // GET /builds/<buildJobId>/runs/<runId>/logs - データベースから結合したログテキストの取得
  router.get('/builds/<buildJobId>/runs/<runId>/logs', (
    Request request,
    String buildJobId,
    String runId,
  ) async {
    try {
      final logs = await db.getBuildJobLogs(runId);
      final logText = logs.map((l) => l.logContent).join('');
      return Response.ok(
        logText,
        headers: {'content-type': 'text/plain; charset=utf-8'},
      );
    } catch (e, s) {
      stderr.writeln('Failed to read logs for run $runId: $e\n$s');
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'Internal server error',
        }),
        headers: {'content-type': 'application/json'},
      );
    }
  });

  // POST /builds/<buildJobId>/runs/<runId>/logs - ログの都度受信・DB保存
  router.post('/builds/<buildJobId>/runs/<runId>/logs', (
    Request request,
    String buildJobId,
    String runId,
  ) async {
    try {
      final payload =
          jsonDecode(await request.readAsString()) as Map<String, dynamic>;
      final logs = payload['logs'] as List<dynamic>? ?? [];

      final StringBuffer logBuffer = StringBuffer();
      for (final log in logs) {
        if (log is Map) {
          final message = log['message'] as String?;
          if (message != null) {
            logBuffer.write('$message\n');
            // WebSocketでのリアルタイム中継配信用にアペンド
            LogStreamManager().appendLog(runId, message);
          }
        }
      }

      if (logBuffer.isNotEmpty) {
        await db.insertBuildJobLog(runId, logBuffer.toString());
      }

      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e, s) {
      stderr.writeln('Failed to append logs for run $runId: $e\n$s');
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'Internal server error',
        }),
        headers: {'content-type': 'application/json'},
      );
    }
  });

  // GET /builds/<buildJobId>/runs/<runId>/logs/stream - WebSocketによるストリーミング配信
  router.get('/builds/<buildJobId>/runs/<runId>/logs/stream', (
    Request request,
    String buildJobId,
    String runId,
  ) async {
    return webSocketHandler((
      WebSocketChannel webSocket,
      String? protocol,
    ) async {
      final manager = LogStreamManager();
      manager.initSession(runId);

      // 初期バッファとして、これまでにDBに保存されているログをクライアントに送信
      try {
        final existingLogs = await db.getBuildJobLogs(runId);
        for (final logRecord in existingLogs) {
          final lines = logRecord.logContent.split('\n');
          for (final line in lines) {
            if (line.isNotEmpty) {
              webSocket.sink.add(line);
            }
          }
        }
      } catch (e) {
        stderr.writeln('Error loading initial logs from DB for streaming: $e');
      }

      final stream = manager.getStream(runId);
      StreamSubscription<String>? subscription;
      if (stream != null) {
        subscription = stream.listen(
          (message) {
            webSocket.sink.add(message);
          },
          onError: (err) {
            webSocket.sink.close();
          },
          onDone: () {
            webSocket.sink.close();
          },
        );
      }

      webSocket.stream.listen(
        null,
        onDone: () {
          subscription?.cancel();
        },
      );
    })(request);
  });

  // POST /builds/<buildJobId>/runs/<runId>/complete - ビルド完了処理（ストリームのクローズ）
  router.post('/builds/<buildJobId>/runs/<runId>/complete', (
    Request request,
    String buildJobId,
    String runId,
  ) async {
    try {
      await LogStreamManager().finalizeSession(runId);

      return Response.ok(
        jsonEncode({'success': true}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e, s) {
      stderr.writeln('Failed to finalize log session for run $runId: $e\n$s');
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'error': 'Internal server error',
        }),
        headers: {'content-type': 'application/json'},
      );
    }
  });

  return router;
}
