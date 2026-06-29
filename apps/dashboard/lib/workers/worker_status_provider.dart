import 'dart:async';

import 'package:dashboard/api/openci_api_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final workerInstancesProvider =
    StreamProvider.autoDispose<List<WorkerInstance>>(
      (ref) async* {
        Future<List<WorkerInstance>> fetchWorkers() async {
          try {
            final apiService = ref.read(openciApiServiceProvider);
            final response = await apiService.getWorkers();

            if (!response.isSuccessful) return const <WorkerInstance>[];

            final data = response.body ?? <String, dynamic>{};
            final list = data['workers'] as List<dynamic>? ?? [];

            final workers = list.map((item) {
              final map = Map<String, dynamic>.from(item as Map);
              return WorkerInstance(
                id: map['id'] as String,
                version: map['version'] as String? ?? 'unknown',
                platform: map['platform'] as String? ?? 'unknown',
                status: _workerStatusFromString(map['status']),
                lastSeenAt: DateTime.parse(
                  map['lastSeenAt'] as String,
                ).toLocal(),
              );
            }).toList();

            workers.sort((a, b) {
              final platformCompare = a.platformGroup.index.compareTo(
                b.platformGroup.index,
              );
              if (platformCompare != 0) return platformCompare;
              return a.id.toLowerCase().compareTo(
                b.id.toLowerCase(),
              );
            });

            return workers;
          } catch (e) {
            return const <WorkerInstance>[];
          }
        }

        yield await fetchWorkers();
        await for (final _ in Stream.periodic(const Duration(seconds: 10))) {
          yield await fetchWorkers();
        }
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
    required this.version,
    required this.platform,
    required this.status,
    required this.lastSeenAt,
  });

  static const offlineAfter = Duration(minutes: 2);

  final String id;
  final String version;
  final String platform;
  final WorkerStatus status;
  final DateTime lastSeenAt;

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

  bool get hasError => status == WorkerStatus.error;
}

WorkerStatus _workerStatusFromString(Object? value) {
  final normalized = value is String ? value.toLowerCase() : '';
  return WorkerStatus.values.firstWhere(
    (status) => status.name == normalized,
    orElse: () => WorkerStatus.unknown,
  );
}
