import 'package:dio/dio.dart';
import 'package:firebase_functions/firebase_functions.dart';
import 'package:openci_shared/firestore_paths.dart';

import '../firebase.dart';
import '../secret_manager.dart';
import '../util/logger.dart';

// ---------------------------------------------------------------------------
// Request model
// ---------------------------------------------------------------------------

class GenerateFailureSummaryRequest {
  const GenerateFailureSummaryRequest({required this.buildJobId});

  factory GenerateFailureSummaryRequest.fromJson(Map<String, dynamic> json) {
    final buildJobId = json['buildJobId'] as String?;
    if (buildJobId == null || buildJobId.isEmpty) {
      throw InvalidArgumentError('Missing buildJobId');
    }
    return GenerateFailureSummaryRequest(buildJobId: buildJobId);
  }

  final String buildJobId;
}

// ---------------------------------------------------------------------------
// Handler
// ---------------------------------------------------------------------------

/// Generates an AI-powered failure summary for a failed build job.
///
/// Called by the Worker CLI after a build job fails.
/// Reads the last N log lines and sends them to Gemini for analysis.
Future<Map<String, dynamic>> handleGenerateFailureSummary(
  CallableRequest<GenerateFailureSummaryRequest> request,
  CallableResponse<Map<String, dynamic>> response,
) async {
  final buildJobId = request.data.buildJobId;

  final buildJobDoc = await firestore
      .collection(buildJobsCollection)
      .doc(buildJobId)
      .get();

  if (!buildJobDoc.exists) {
    throw NotFoundError('Build job not found');
  }

  final jobData = buildJobDoc.data()!;
  final status = jobData['status'] as String?;
  if (status != 'failure') {
    return <String, dynamic>{
      'success': false,
      'reason': 'Build job is not in failure status',
    };
  }

  // Check if AI is enabled for the team
  final teamId = jobData['teamId'] as String?;
  if (teamId != null) {
    final teamDoc = await firestore
        .collection(teamsCollection)
        .doc(teamId)
        .get();
    if (teamDoc.exists && teamDoc.data()?['aiEnabled'] == false) {
      logInfo('AI features disabled for team $teamId, skipping summary');
      return <String, dynamic>{
        'success': false,
        'reason': 'AI features disabled',
      };
    }
  }

  final latestRunId = jobData['latestRunId'] as String?;
  if (latestRunId == null) {
    return <String, dynamic>{'success': false, 'reason': 'No run ID found'};
  }

  await _generateSummary(buildJobId, latestRunId);
  return <String, dynamic>{'success': true};
}

// ---------------------------------------------------------------------------
// Summary generation
// ---------------------------------------------------------------------------

Future<void> _generateSummary(String buildJobId, String latestRunId) async {
  try {
    final anthropicApiKey = await _accessSecretCached('ANTHROPIC_API_KEY');

    // Mark as generating
    final stopwatch = Stopwatch()..start();
    await firestore.collection(buildJobsCollection).doc(buildJobId).update({
      'failureSummaryStatus': 'generating',
    });

    // Get last N log lines
    final logsSnapshot = await firestore
        .collection(buildJobsCollection)
        .doc(buildJobId)
        .collection('runs')
        .doc(latestRunId)
        .collection('logs')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();

    if (logsSnapshot.docs.isEmpty) {
      await firestore.collection(buildJobsCollection).doc(buildJobId).update({
        'failureSummaryStatus': 'error',
        'failureSummary': 'No logs found',
      });
      return;
    }

    final logLines = logsSnapshot.docs.reversed
        .map((doc) => doc.data()['message'] as String? ?? '')
        .join('\n');

    const modelName = 'claude-opus-4-7';
    final dio = Dio();
    try {
      final resp = await dio.post<Map<String, dynamic>>(
        'https://api.anthropic.com/v1/messages',
        options: Options(
          headers: {
            'x-api-key': anthropicApiKey,
            'anthropic-version': '2023-06-01',
            'content-type': 'application/json',
          },
        ),
        data: {
          'model': modelName,
          'max_tokens': 1024,
          'messages': [
            {
              'role': 'user',
              'content':
                  'あなたはCI/CDの専門家です。以下のビルドログを分析し、ビルドが失敗した原因を簡潔に要約してください。根本原因に焦点を当て、修正方法を提案してください。3文以内で日本語で回答してください。\n\n$logLines',
            },
          ],
        },
      );

      final content = resp.data?['content'] as List<dynamic>?;
      final text =
          (content?.firstOrNull as Map<String, dynamic>?)?['text'] as String? ??
          'No summary generated';

      stopwatch.stop();
      await firestore.collection(buildJobsCollection).doc(buildJobId).update({
        'failureSummaryStatus': 'done',
        'failureSummary': text,
        'failureSummaryModel': modelName,
        'failureSummaryDurationMs': stopwatch.elapsedMilliseconds,
      });

      logInfo(
        'Generated failure summary for $buildJobId using $modelName in ${stopwatch.elapsedMilliseconds}ms',
      );
    } finally {
      dio.close();
    }
  } catch (e) {
    logError('Failed to generate failure summary', null, e);
    await firestore.collection(buildJobsCollection).doc(buildJobId).update({
      'failureSummaryStatus': 'error',
      'failureSummary': e.toString(),
    });
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

final _secretCache = <String, String>{};

Future<String> _accessSecretCached(String name) async {
  if (_secretCache.containsKey(name)) return _secretCache[name]!;
  final value = await accessSecret(name);
  _secretCache[name] = value;
  return value;
}
