import 'package:dashboard/firebase/dataconnect.dart';
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

    return dataConnector
        .listEnvironmentVariablesForTeam(teamId: teamId)
        .ref()
        .subscribe()
        .map(
          (result) => result.data.environmentVariables
              .map(
                (envVar) => EnvironmentVariable(
                  id: envVar.id,
                  key: envVar.key,
                  value: envVar.value,
                  teamId: envVar.teamId,
                  autoIncrement: envVar.autoIncrement.value ?? false,
                  createdAt: dateTimeFromDataConnect(envVar.createdAt),
                  updatedAt: dateTimeFromDataConnect(envVar.updatedAt),
                ),
              )
              .toList(),
        );
  }

  Future<void> addEnvironmentVariable(
    String key,
    String value,
  ) async {
    final teamId = ref.read(teamStateProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');
    await dataConnector
        .createEnvironmentVariable(
          id: const Uuid().v4(),
          envKey: key,
          value: value,
          teamId: teamId,
        )
        .autoIncrement(false)
        .execute();
  }

  Future<void> updateEnvironmentVariable({
    required String documentId,
    required String key,
    required String value,
  }) async {
    final teamId = ref.read(teamStateProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');
    await dataConnector
        .updateEnvironmentVariable(
          id: documentId,
          teamId: teamId,
          envKey: key,
          value: value,
        )
        .execute();
  }

  Future<void> deleteEnvironmentVariable(String documentId) async {
    final teamId = ref.read(teamStateProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');
    await dataConnector
        .deleteEnvironmentVariable(id: documentId, teamId: teamId)
        .execute();
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
