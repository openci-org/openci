import 'dart:async';
import 'dart:convert';

import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/openci_server_url_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final workerInstancesProvider =
    StreamProvider.autoDispose<List<WorkerInstance>>(
      (ref) async* {
        final serverUrl = ref.watch(openciServerUrlProvider);
        final token = await ref.watch(authedFirebaseIdTokenProvider.future);

        Future<List<WorkerInstance>> fetchWorkers(String token) async {
          try {
            final url = Uri.parse('$serverUrl/workers');
            final response = await http
                .get(
                  url,
                  headers: {
                    'Authorization': 'Bearer $token',
                  },
                )
                .timeout(const Duration(seconds: 5));

            if (response.statusCode != 200) return const <WorkerInstance>[];

            final data = jsonDecode(response.body) as Map<String, dynamic>;
            final list = data['workers'] as List<dynamic>;

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

        yield await fetchWorkers(token);
        await for (final _ in Stream.periodic(const Duration(seconds: 10))) {
          yield await fetchWorkers(token);
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
