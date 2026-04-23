import 'package:cloud_firestore/cloud_firestore.dart' as cloud;
import 'package:dashboard/firebase/firestore.dart';
import 'package:dashboard/firebase/firestore_paths.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/utilities/date_time_converter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
        .withConverter(
          fromFirestore: (snapshot, _) =>
              EnvironmentVariable.fromJson(snapshot.data()!),
          toFirestore: (envVar, _) => envVar.toJson(),
        )
        .where('teamId', isEqualTo: teamId)
        .orderBy('key')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> addEnvironmentVariable(
    String key,
    String value,
  ) async {
    final teamId = ref.read(teamStateProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');
    final docRef = firestore.collection(environmentVariablesCollection).doc();
    await docRef.set(
      EnvironmentVariable(
        id: docRef.id,
        key: key,
        value: value,
        teamId: teamId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ).toJson(),
    );
  }

  Future<void> updateEnvironmentVariable({
    required String documentId,
    required String key,
    required String value,
  }) async {
    await firestore
        .collection(environmentVariablesCollection)
        .doc(documentId)
        .update({
          'key': key,
          'value': value,
          'updatedAt': cloud.Timestamp.fromDate(DateTime.now()),
        });
  }

  Future<void> deleteEnvironmentVariable(String documentId) async {
    await firestore
        .collection(environmentVariablesCollection)
        .doc(documentId)
        .delete();
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
