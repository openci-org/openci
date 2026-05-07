// ignore_for_file: constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';

FirebaseFirestore get firestore => FirebaseFirestore.instance;

enum BuildJobStatus {
  WAITING,
  QUEUED,
  IN_PROGRESS,
  SUCCESS,
  FAILURE,
  CANCELLED,
  SKIPPED,
  TIMED_OUT,
}

const teamsCollection = 'teams_v0';
const usersCollection = 'users_v0';
const buildJobsCollection = 'build_jobs_v0';
const workerInstancesCollection = 'worker_instances_v0';
const workflowsCollection = 'workflows_v1';
const workflowFilesCollection = 'workflow_files_v0';
const secretsCollection = 'secrets_v0';
const environmentVariablesCollection = 'environment_variables_v0';

DateTime dateTimeFromFirestore(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  return DateTime.fromMillisecondsSinceEpoch(0);
}

Map<String, Object?> firestoreMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

List<Object?> firestoreList(Object? value) => value is List ? value : const [];

BuildJobStatus buildJobStatusFromFirestore(Object? value) {
  final normalized = value is String ? value.toUpperCase() : '';
  return BuildJobStatus.values.firstWhere(
    (status) => status.name == normalized,
    orElse: () => throw StateError('Unknown BuildJobStatus: $value'),
  );
}
