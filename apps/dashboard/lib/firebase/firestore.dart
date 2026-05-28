// ignore_for_file: constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:openci_shared/openci_shared.dart';
export 'package:openci_shared/openci_shared.dart';



FirebaseFirestore get firestore => FirebaseFirestore.instance;




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
