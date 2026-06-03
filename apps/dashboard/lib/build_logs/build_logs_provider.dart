import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard/firebase/firestore.dart';
import 'package:dashboard/users/user_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'build_logs_provider.freezed.dart';
part 'build_logs_provider.g.dart';

@riverpod
class BuildLogs extends _$BuildLogs {
  static const int _pageSize = 200;
  static const int _maxLiveLogLimit = 500;

  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _logsSubscription;

  @override
  FutureOr<List<BuildLog>> build(String buildJobId, String runId) async {
    ref.onDispose(() {
      _logsSubscription?.cancel();
    });

    final teamId = ref.watch(userProvider).value?.selectedTeamId;
    if (teamId == null) {
      return const [];
    }

    final buildJobDoc = await firestore
        .collection(buildJobsCollection)
        .doc(buildJobId)
        .get();
    if (buildJobDoc.data()?['teamId'] != teamId) {
      return const [];
    }

    final buildStatus = buildJobStatusFromFirestore(buildJobDoc.data()?['status']);
    final isRunning = buildStatus == BuildJobStatus.IN_PROGRESS ||
        buildStatus == BuildJobStatus.QUEUED ||
        buildStatus == BuildJobStatus.WAITING;

    final query = firestore
        .collection(buildJobsCollection)
        .doc(buildJobId)
        .collection('runs')
        .doc(runId)
        .collection('logs')
        .orderBy('timestamp')
        .limit(_pageSize);

    final snapshot = await query.get();
    if (snapshot.docs.isNotEmpty) {
      _lastDoc = snapshot.docs.last;
    }
    _hasMore = snapshot.docs.length >= _pageSize;

    final initialLogs = _buildLogsFromDocs(snapshot.docs);

    if (isRunning) {
      _startRealtimeListener(buildJobId, runId, initialLogs);
    }

    return initialLogs;
  }

  void _startRealtimeListener(
    String buildJobId,
    String runId,
    List<BuildLog> initialLogs,
  ) {
    _logsSubscription?.cancel();

    Query<Map<String, dynamic>> query = firestore
        .collection(buildJobsCollection)
        .doc(buildJobId)
        .collection('runs')
        .doc(runId)
        .collection('logs')
        .orderBy('timestamp');

    if (_lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    }

    _logsSubscription = query.snapshots().listen(
      (snapshot) {
        if (snapshot.docs.isEmpty) return;

        final newLogs = _buildLogsFromDocs(snapshot.docs);
        final currentList = [...?state.value, ...newLogs];

        if (currentList.length > _maxLiveLogLimit) {
          state = AsyncData(
            currentList.sublist(currentList.length - _maxLiveLogLimit),
          );
        } else {
          state = AsyncData(currentList);
        }

        _lastDoc = snapshot.docs.last;
      },
      onError: (err, stack) {
        debugPrint('Realtime log listener error: $err\n$stack');
      },
    );
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _lastDoc == null) return;

    _isLoadingMore = true;
    try {
      final query = firestore
          .collection(buildJobsCollection)
          .doc(buildJobId)
          .collection('runs')
          .doc(runId)
          .collection('logs')
          .orderBy('timestamp')
          .startAfterDocument(_lastDoc!)
          .limit(_pageSize);

      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        _lastDoc = snapshot.docs.last;
      }
      _hasMore = snapshot.docs.length >= _pageSize;

      final moreLogs = _buildLogsFromDocs(snapshot.docs);
      final currentList = [...?state.value, ...moreLogs];

      state = AsyncData(currentList);
    } catch (e, st) {
      debugPrint('Error loading more logs: $e\n$st');
    } finally {
      _isLoadingMore = false;
    }
  }

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
}

@freezed
abstract class BuildLog with _$BuildLog {
  const factory BuildLog({
    required String message,
    required String level,
    @DateTimeConverter() DateTime? timestamp,
  }) = _BuildLog;

  factory BuildLog.fromJson(Map<String, Object?> json) =>
      _$BuildLogFromJson(json);
}

List<BuildLog> _buildLogsFromDocs(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> logs,
) {
  return logs
      .map(
        (doc) => BuildLog(
          message: doc.data()['message'] as String? ?? '',
          level: doc.data()['level'] as String? ?? 'info',
          timestamp: dateTimeFromFirestore(doc.data()['timestamp']),
        ),
      )
      .toList();
}
