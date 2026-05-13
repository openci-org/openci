import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard/firebase/callable_function_names.dart';
import 'package:dashboard/firebase/firestore.dart';
import 'package:dashboard/firebase/functions.dart';
import 'package:dashboard/users/user_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum CiCdFixStatus {
  queued,
  collectingContext,
  generatingFix,
  ready,
  failed,
  committed,
  prCreated,
  unknown,
}

extension CiCdFixStatusX on CiCdFixStatus {
  bool get isWorking =>
      this == CiCdFixStatus.queued ||
      this == CiCdFixStatus.collectingContext ||
      this == CiCdFixStatus.generatingFix;

  bool get hasPreview =>
      this == CiCdFixStatus.ready ||
      this == CiCdFixStatus.committed ||
      this == CiCdFixStatus.prCreated;

  String get label => switch (this) {
    CiCdFixStatus.queued => 'queued',
    CiCdFixStatus.collectingContext => 'collecting',
    CiCdFixStatus.generatingFix => 'generating',
    CiCdFixStatus.ready => 'ready',
    CiCdFixStatus.failed => 'failed',
    CiCdFixStatus.committed => 'committed',
    CiCdFixStatus.prCreated => 'pr_created',
    CiCdFixStatus.unknown => 'unknown',
  };
}

class CiCdFixRequest {
  const CiCdFixRequest({
    required this.id,
    required this.status,
    required this.buildJobId,
    required this.teamId,
    required this.repository,
    required this.branch,
    required this.workflowPath,
    required this.failureReason,
    required this.fixSummary,
    required this.warnings,
    required this.files,
    required this.createdAt,
    required this.updatedAt,
    this.jobKey,
    this.commitMessage,
    this.error,
    this.model,
    this.commitSha,
    this.pullRequestUrl,
    this.pullRequestNumber,
  });

  final String id;
  final CiCdFixStatus status;
  final String buildJobId;
  final String teamId;
  final String repository;
  final String branch;
  final String workflowPath;
  final String? jobKey;
  final String failureReason;
  final List<String> fixSummary;
  final List<String> warnings;
  final List<CiCdFixFile> files;
  final String? commitMessage;
  final String? error;
  final String? model;
  final String? commitSha;
  final String? pullRequestUrl;
  final int? pullRequestNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CiCdFixRequest.fromSnapshot(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return CiCdFixRequest(
      id: doc.id,
      status: _ciCdFixStatusFromFirestore(data['status']),
      buildJobId: data['buildJobId'] as String? ?? '',
      teamId: data['teamId'] as String? ?? '',
      repository: data['repository'] as String? ?? '',
      branch: data['branch'] as String? ?? 'main',
      workflowPath: data['workflowPath'] as String? ?? '',
      jobKey: data['jobKey'] as String?,
      failureReason: data['failureReason'] as String? ?? '',
      fixSummary: _stringList(data['fixSummary']),
      warnings: _stringList(data['warnings']),
      files: _fileList(data['files']),
      commitMessage: data['commitMessage'] as String?,
      error: data['error'] as String?,
      model: data['model'] as String?,
      commitSha: data['commitSha'] as String?,
      pullRequestUrl: data['pullRequestUrl'] as String?,
      pullRequestNumber: data['pullRequestNumber'] as int?,
      createdAt: dateTimeFromFirestore(data['createdAt']),
      updatedAt: dateTimeFromFirestore(data['updatedAt']),
    );
  }
}

class CiCdFixFile {
  const CiCdFixFile({
    required this.path,
    required this.added,
    required this.removed,
    required this.lines,
  });

  final String path;
  final int added;
  final int removed;
  final List<CiCdFixDiffLine> lines;

  factory CiCdFixFile.fromMap(Map<String, Object?> data) {
    return CiCdFixFile(
      path: data['path'] as String? ?? '',
      added: data['added'] as int? ?? 0,
      removed: data['removed'] as int? ?? 0,
      lines: _diffLineList(data['lines']),
    );
  }
}

enum CiCdFixDiffLineKind { context, added, removed }

class CiCdFixDiffLine {
  const CiCdFixDiffLine({required this.kind, required this.text});

  final CiCdFixDiffLineKind kind;
  final String text;

  factory CiCdFixDiffLine.fromMap(Map<String, Object?> data) {
    final kind = switch (data['kind']) {
      'added' => CiCdFixDiffLineKind.added,
      'removed' => CiCdFixDiffLineKind.removed,
      _ => CiCdFixDiffLineKind.context,
    };
    return CiCdFixDiffLine(
      kind: kind,
      text: data['text'] as String? ?? '',
    );
  }
}

final ciCdFixRequestProvider = StreamProvider.family<CiCdFixRequest?, String>((
  ref,
  buildJobId,
) async* {
  final teamId = ref.watch(userProvider).value?.selectedTeamId;
  if (teamId == null) {
    yield null;
    return;
  }

  yield* firestore
      .collection(ciCdFixRequestsCollection)
      .where('buildJobId', isEqualTo: buildJobId)
      .where('teamId', isEqualTo: teamId)
      .snapshots()
      .map((snapshot) {
        final requests = snapshot.docs.map(CiCdFixRequest.fromSnapshot).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return requests.firstOrNull;
      });
});

final ciCdFixActionsProvider = Provider<CiCdFixActions>((ref) {
  return const CiCdFixActions();
});

class CiCdFixActions {
  const CiCdFixActions();

  Future<String> start(String buildJobId) async {
    final result = await firebaseFunctions
        .httpsCallable(startCiCdFixFunction)
        .call<Map<String, dynamic>>({'buildJobId': buildJobId});
    return result.data['requestId'] as String;
  }

  Future<void> commit(String requestId) async {
    await firebaseFunctions.httpsCallable(commitCiCdFixFunction).call({
      'requestId': requestId,
    });
  }

  Future<void> createPullRequest(String requestId) async {
    await firebaseFunctions
        .httpsCallable(createCiCdFixPullRequestFunction)
        .call(
          {'requestId': requestId},
        );
  }

  Future<String> revise({
    required String requestId,
    required String instruction,
  }) async {
    final result = await firebaseFunctions
        .httpsCallable(reviseCiCdFixFunction)
        .call<Map<String, dynamic>>({
          'requestId': requestId,
          'instruction': instruction,
        });
    return result.data['requestId'] as String;
  }
}

CiCdFixStatus _ciCdFixStatusFromFirestore(Object? value) {
  return switch (value) {
    'queued' => CiCdFixStatus.queued,
    'collecting_context' => CiCdFixStatus.collectingContext,
    'generating_fix' => CiCdFixStatus.generatingFix,
    'ready' => CiCdFixStatus.ready,
    'failed' => CiCdFixStatus.failed,
    'committed' => CiCdFixStatus.committed,
    'pr_created' => CiCdFixStatus.prCreated,
    _ => CiCdFixStatus.unknown,
  };
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList();
}

List<CiCdFixFile> _fileList(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((entry) => CiCdFixFile.fromMap(entry.cast<String, Object?>()))
      .toList();
}

List<CiCdFixDiffLine> _diffLineList(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((entry) => CiCdFixDiffLine.fromMap(entry.cast<String, Object?>()))
      .toList();
}
