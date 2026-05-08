import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard/firebase/firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final workerInstancesProvider =
    StreamProvider.autoDispose<List<WorkerInstance>>(
      (ref) {
        return firestore
            .collection(workerInstancesCollection)
            .orderBy('lastSeenAt', descending: true)
            .snapshots()
            .map((snapshot) {
              final workers = snapshot.docs
                  .map(_workerInstanceFromDoc)
                  .toList();
              workers.sort((a, b) {
                final platformCompare = a.platformGroup.index.compareTo(
                  b.platformGroup.index,
                );
                if (platformCompare != 0) return platformCompare;
                return a.workerId.toLowerCase().compareTo(
                  b.workerId.toLowerCase(),
                );
              });
              return workers;
            });
      },
    );

enum WorkerStatus {
  starting,
  idle,
  busy,
  error,
  stopping,
  unknown,
}

enum WorkerPlatformGroup {
  macos,
  linux,
  other,
}

class WorkerInstance {
  const WorkerInstance({
    required this.id,
    required this.workerId,
    required this.version,
    required this.platform,
    required this.hostname,
    required this.pid,
    required this.status,
    required this.lastSeenAt,
    required this.updatedAt,
    this.startedAt,
    this.currentBuildJobId,
    this.currentRunId,
    this.consecutiveFailures = 0,
    this.lastError,
  });

  static const offlineAfter = Duration(minutes: 2);

  final String id;
  final String workerId;
  final String version;
  final String platform;
  final String hostname;
  final int? pid;
  final WorkerStatus status;
  final DateTime? startedAt;
  final DateTime lastSeenAt;
  final DateTime updatedAt;
  final String? currentBuildJobId;
  final String? currentRunId;
  final int consecutiveFailures;
  final String? lastError;

  WorkerPlatformGroup get platformGroup {
    final normalized = platform.toLowerCase();
    if (normalized == 'darwin' || normalized.contains('mac')) {
      return WorkerPlatformGroup.macos;
    }
    if (normalized == 'linux') {
      return WorkerPlatformGroup.linux;
    }
    return WorkerPlatformGroup.other;
  }

  bool get isOnline => DateTime.now().difference(lastSeenAt) < offlineAfter;

  bool get isBusy => isOnline && status == WorkerStatus.busy;

  bool get hasError => status == WorkerStatus.error || consecutiveFailures > 0;
}

WorkerInstance _workerInstanceFromDoc(
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) {
  final data = doc.data();
  return WorkerInstance(
    id: doc.id,
    workerId: data['workerId'] as String? ?? doc.id,
    version: data['version'] as String? ?? 'unknown',
    platform: data['platform'] as String? ?? 'unknown',
    hostname: data['hostname'] as String? ?? '',
    pid: data['pid'] is int ? data['pid'] as int : null,
    status: _workerStatusFromFirestore(data['status']),
    startedAt: data['startedAt'] == null
        ? null
        : dateTimeFromFirestore(data['startedAt']),
    lastSeenAt: dateTimeFromFirestore(data['lastSeenAt']),
    updatedAt: dateTimeFromFirestore(data['updatedAt']),
    currentBuildJobId: data['currentBuildJobId'] as String?,
    currentRunId: data['currentRunId'] as String?,
    consecutiveFailures: data['consecutiveFailures'] is int
        ? data['consecutiveFailures'] as int
        : 0,
    lastError: data['lastError'] as String?,
  );
}

WorkerStatus _workerStatusFromFirestore(Object? value) {
  final normalized = value is String ? value.toLowerCase() : '';
  return WorkerStatus.values.firstWhere(
    (status) => status.name == normalized,
    orElse: () => WorkerStatus.unknown,
  );
}
