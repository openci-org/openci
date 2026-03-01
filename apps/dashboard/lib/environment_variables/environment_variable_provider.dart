import 'package:dashboard/supabase/supabase_provider.dart';
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

    final supabase = ref.read(supabaseClientProvider);

    return supabase
        .from('environment_variables')
        .stream(primaryKey: ['id'])
        .eq('is_secret', false)
        .order('key')
        .map((rows) {
          return rows
              .map(
                (row) => EnvironmentVariable(
                  id: row['id'] as String,
                  key: row['key'] as String,
                  value: row['value'] as String? ?? '',
                  teamId: row['team_id'] as String,
                  autoIncrement: row['auto_increment'] as bool? ?? false,
                  createdAt: DateTime.parse(row['created_at'] as String),
                  updatedAt: DateTime.parse(row['updated_at'] as String),
                ),
              )
              .toList();
        });
  }

  Future<void> addEnvironmentVariable(
    String key,
    String value,
  ) async {
    final supabase = ref.read(supabaseClientProvider);
    final orgId = ref.read(teamStateProvider).requireValue.id;

    await supabase.from('environment_variables').insert({
      'team_id': orgId,
      'key': key,
      'value': value,
      'is_secret': false,
    });
  }

  Future<void> updateEnvironmentVariable({
    required String documentId,
    required String key,
    required String value,
  }) async {
    final supabase = ref.read(supabaseClientProvider);
    await supabase
        .from('environment_variables')
        .update({
          'key': key,
          'value': value,
        })
        .eq('id', documentId);
  }

  Future<void> deleteEnvironmentVariable(String documentId) async {
    final supabase = ref.read(supabaseClientProvider);
    await supabase.from('environment_variables').delete().eq('id', documentId);
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
