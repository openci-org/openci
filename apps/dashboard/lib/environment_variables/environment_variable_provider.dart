import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/utilities/date_time_converter.dart';
import 'package:dashboard/workflow/mock_workflow_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'environment_variable_provider.freezed.dart';
part 'environment_variable_provider.g.dart';

@riverpod
class EnvironmentVariableManager extends _$EnvironmentVariableManager {
  @override
  Stream<List<EnvironmentVariable>> build() {
    if (useMockData) {
      return Stream.value(getMockEnvironmentVariables());
    }

    throw UnimplementedError(
      'TODO: Migrate to Firebase Data Connect',
    );
  }

  Future<void> addEnvironmentVariable(
    String key,
    String value,
  ) async {
    final orgId = ref.read(teamStateProvider).requireValue.id;
    throw UnimplementedError(
      'TODO: Migrate to Firebase Data Connect (orgId: $orgId)',
    );
  }

  Future<void> updateEnvironmentVariable({
    required String documentId,
    required String key,
    required String value,
  }) async {
    throw UnimplementedError(
      'TODO: Migrate to Firebase Data Connect',
    );
  }

  Future<void> deleteEnvironmentVariable(String documentId) async {
    throw UnimplementedError(
      'TODO: Migrate to Firebase Data Connect',
    );
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
