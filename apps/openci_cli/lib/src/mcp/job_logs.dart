import 'dart:math' as math;

import 'build_api.dart';

const _pageSize = 32;
const _excerptSize = 4096;
final _diagnostic = RegExp(
  r'\bfatal\b|\berror\s*[:•\]]|\bexception\b|\bfailed\b',
  caseSensitive: false,
);

Future<Map<String, Object?>> getJobLogs(
  BuildApi api,
  Map<String, Object?> args,
) async {
  final jobId = args['job_id'] as String;
  final requestedRun = args['run_id'] as String?;
  final cursor = args['cursor'] as String?;
  if (cursor != null && requestedRun == null) {
    throw const BuildReadException('Pass the run_id with a log cursor.');
  }
  final data = await api.query('builds', 'GetBuildJob', {'id': jobId});
  final job = data['job'] as Map?;
  if (job == null || job['teamId'] != api.profile.teamId) {
    throw const BuildReadException('Job not found in the active OpenCI team.');
  }
  final pending = job['status'] == 'QUEUED' || job['status'] == 'WAITING';
  // While a retry is queued, latestRunId still points to the previous attempt.
  final runId =
      requestedRun ?? (pending ? null : job['latestRunId'] as String?);
  final result = <String, Object?>{
    'job_id': jobId,
    'workflow': job['workflowName'],
    'commit': job['commitSha'],
    'job_status': job['status'],
    'dashboard_url': ?api.dashboardUrl(jobId),
    if (requestedRun == null || requestedRun == job['latestRunId'])
      if (job['failureSummary'] case final String summary)
        'failure_summary': summary.substring(0, math.min(summary.length, 768)),
  };
  if (runId == null) return {...result, 'log_status': 'no_run'};
  final ids = {'teamId': api.profile.teamId, 'jobId': jobId, 'runId': runId};
  final state = await api.query('logs', 'GetBuildLogState', ids);
  final run = state['run'] as Map?;
  if (run == null) {
    throw const BuildReadException('Run not found for this job and team.');
  }
  final steps = (run['allSteps'] as List).cast<Map>();
  final failed = steps
      .where((step) => const {'FAILURE', 'TIMED_OUT'}.contains(step['status']))
      .lastOrNull;
  result.addAll({
    'run_id': runId,
    'run_status': run['status'],
    if (failed != null)
      'failed_step': {'id': failed['stepId'], 'name': failed['name']},
  });
  final expiry = run['logsExpireAt'] as String?;
  if (expiry != null && !DateTime.parse(expiry).isAfter(DateTime.now())) {
    return {...result, 'log_status': 'expired'};
  }
  final last = int.parse(run['lastLogSequence'].toString());
  if (last == 0) return {...result, 'log_status': 'empty'};
  final position = cursor?.split(':');
  final start = position == null
      ? math.max(1, last - _pageSize + 1)
      : int.parse(position.first);
  if (start > last) {
    throw const BuildReadException('Cursor is outside this run.');
  }
  final logs = await api.query('logs', 'GetBuildLogs', {
    'teamId': api.profile.teamId,
    'runId': runId,
    'afterSequence': (start - 1).toString(),
    'limit': math.min(_pageSize, last - start + 1),
  });
  final entries = ((logs['run'] as Map)['logEntries'] as List).cast<Map>();
  if (entries.isEmpty) return {...result, 'log_status': 'empty'};
  final (index, requestedOffset) = position == null
      ? _excerptStart(entries, failed?['stepId'] as String?)
      : (0, int.parse(position.last));
  final first = entries[index];
  final message = first['message'] as String;
  if (requestedOffset > message.length ||
      (cursor != null && first['sequence'].toString() != start.toString())) {
    throw const BuildReadException('Cursor is outside this log entry.');
  }
  final offset = _characterBoundary(message, requestedOffset);
  return {
    ...result,
    'log_status': 'available',
    if (first['sequence'].toString() != '1' || offset > 0)
      'first_cursor': '1:0',
    ..._logPage(entries, index, offset, last),
  };
}

/// Start near a diagnostic in the failed step, otherwise return the most
/// recent output. Explicit cursors always read forwards in persisted order.
(int, int) _excerptStart(List<Map> entries, String? failedStep) {
  if (failedStep != null) {
    for (final (index, entry) in entries.indexed) {
      if (entry['stepId'] != failedStep) continue;
      final match = _diagnostic.firstMatch(entry['message'] as String);
      if (match == null) continue;
      if (match.start < 384 &&
          index > 0 &&
          entries[index - 1]['stepId'] == failedStep) {
        final previous = entries[index - 1]['message'] as String;
        return (index - 1, math.max(0, previous.length - 384));
      }
      return (index, math.max(0, match.start - 384));
    }
  }
  var remaining = _excerptSize;
  for (var index = entries.length - 1; index >= 0; index--) {
    final size = (entries[index]['message'] as String).length;
    if (size >= remaining) return (index, size - remaining);
    remaining -= size;
  }
  return (0, 0);
}

Map<String, Object?> _logPage(
  List<Map> entries,
  int index,
  int offset,
  int last,
) {
  final excerpt = <Map<String, Object?>>[];
  var remaining = _excerptSize;
  String? next;
  for (final entry in entries.skip(index)) {
    final message = entry['message'] as String;
    final sequence = int.parse(entry['sequence'].toString());
    final end = _characterBoundary(
      message,
      math.min(message.length, offset + remaining),
    );
    excerpt.add({
      'sequence': sequence,
      'step': entry['stepId'],
      'stream': entry['stream'],
      'text': message.substring(offset, end),
    });
    remaining -= end - offset;
    next = sequence < last ? '${sequence + 1}:0' : null;
    if (end < message.length) {
      next = '$sequence:$end';
      break;
    }
    if (remaining == 0) break;
    offset = 0;
  }
  return {'entries': excerpt, 'next_cursor': ?next};
}

// Dart string offsets are UTF-16. Keep a supplementary character in one page.
int _characterBoundary(String text, int index) {
  if (index > 0 && index < text.length) {
    final unit = text.codeUnitAt(index);
    if (unit >= 0xdc00 && unit <= 0xdfff) return index - 1;
  }
  return index;
}
