import 'package:dio/dio.dart';
import 'package:firebase_functions/firebase_functions.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart';
import 'package:openci_shared/firestore_paths.dart';

import '../firebase.dart';
import '../secret_manager.dart';
import '../util/logger.dart';

// ---------------------------------------------------------------------------
// Request model
// ---------------------------------------------------------------------------

class GenerateFailureSummaryRequest {
  const GenerateFailureSummaryRequest({
    required this.buildJobId,
  });

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
    return <String, dynamic>{
      'success': false,
      'reason': 'No run ID found',
    };
  }

  await _generateSummary(buildJobId, latestRunId);
  return <String, dynamic>{'success': true};
}

// ---------------------------------------------------------------------------
// Summary generation
// ---------------------------------------------------------------------------

Future<void> _generateSummary(
  String buildJobId,
  String latestRunId,
) async {
  try {
    final geminiApiKey = await _accessSecretCached('GEMINI_API_KEY');

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

    const modelName = 'gemini-2.5-flash-lite';
    final dio = Dio();
    try {
      final resp = await dio.post<Map<String, dynamic>>(
        'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$geminiApiKey',
        data: {
          'contents': [
            {
              'parts': [
                {
                  'text':
                      'You are a CI/CD expert. Analyze the following build log and provide a concise summary of why the build failed. Focus on the root cause and suggest a fix. Keep it under 3 sentences.\n\n$logLines',
                },
              ],
            },
          ],
        },
      );

      final candidates = resp.data?['candidates'] as List<dynamic>?;
      final text =
          (candidates?.firstOrNull
                  as Map<String, dynamic>?)?['content']?['parts']?[0]?['text']
              as String? ??
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
