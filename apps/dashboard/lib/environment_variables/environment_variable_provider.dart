import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard/firebase/firestore.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/utilities/date_time_converter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'environment_variable_provider.freezed.dart';
part 'environment_variable_provider.g.dart';

@riverpod
class EnvironmentVariableManager extends _$EnvironmentVariableManager {
  @override
  Stream<List<EnvironmentVariable>> build() {
    final teamId = ref.watch(teamStateProvider).value?.id;
    if (teamId == null) return Stream.value([]);

    return firestore
        .collection(environmentVariablesCollection)
        .where('teamId', isEqualTo: teamId)
        .orderBy('key')
        .snapshots()
        .map(
          (result) => result.docs
              .map((doc) {
                final data = doc.data();
                return EnvironmentVariable(
                  id: doc.id,
                  key: data['key'] as String? ?? '',
                  value: data['value'] as String? ?? '',
                  teamId: data['teamId'] as String? ?? '',
                  autoIncrement: data['autoIncrement'] as bool? ?? false,
                  createdAt: dateTimeFromFirestore(data['createdAt']),
                  updatedAt: dateTimeFromFirestore(data['updatedAt']),
                );
              })
              .toList(),
        );
  }

  Future<void> addEnvironmentVariable(
    String key,
    String value,
  ) async {
    final teamId = ref.read(teamStateProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');
    final id = const Uuid().v4();
    final timestamp = FieldValue.serverTimestamp();
    await firestore.collection(environmentVariablesCollection).doc(id).set({
      'id': id,
      'key': key,
      'value': value,
      'teamId': teamId,
      'autoIncrement': false,
      'createdAt': timestamp,
      'updatedAt': timestamp,
    });
  }

  Future<void> updateEnvironmentVariable({
    required String documentId,
    required String key,
    required String value,
  }) async {
    final teamId = ref.read(teamStateProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');
    await firestore.collection(environmentVariablesCollection).doc(documentId).update({
      'key': key,
      'value': value,
      'teamId': teamId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteEnvironmentVariable(String documentId) async {
    final teamId = ref.read(teamStateProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');
    await firestore.collection(environmentVariablesCollection).doc(documentId).delete();
  }
}

@freezed
abstract class EnvironmentVariable with _$EnvironmentVariable {
  const factory EnvironmentVariable({
    required String id,
    required String key,
    required String value,
    required String teamId,
    @Default(false) bool autoIncrement,
    @DateTimeConverter() required DateTime createdAt,
    @DateTimeConverter() required DateTime updatedAt,
  }) = _EnvironmentVariable;

  factory EnvironmentVariable.fromJson(Map<String, Object?> json) =>
      _$EnvironmentVariableFromJson(json);
}
