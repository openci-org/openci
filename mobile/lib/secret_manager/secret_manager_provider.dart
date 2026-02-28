import 'package:dashboard/supabase/supabase_provider.dart';
import 'package:dashboard/utilities/date_time_converter.dart';
import 'package:dashboard/workflow/mock_workflow_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secret_manager_provider.freezed.dart';
part 'secret_manager_provider.g.dart';

@riverpod
class SecretManager extends _$SecretManager {
  @override
  Stream<List<Secret>> build() {
    if (useMockData) {
      return Stream.value(getMockSecrets());
    }
    return secretsStream();
  }

  Stream<List<Secret>> secretsStream() {
    final supabase = ref.read(supabaseClientProvider);

    return supabase
        .from('environment_variables')
        .stream(primaryKey: ['id'])
        .eq('is_secret', true)
        .map((rows) {
          return rows
              .where((r) => r['org_id'] != null)
              .map(
                (row) => Secret(
                  id: row['id'] as String,
                  name: row['key'] as String,
                  teamId: row['org_id'] as String,
                  pathToSecret: row['vault_secret_id']?.toString(),
                  createdAt: DateTime.parse(row['created_at'] as String),
                  updatedAt: DateTime.parse(row['updated_at'] as String),
                ),
              )
              .toList();
        });
  }

  Future<void> addSecret(String name, String value) async {
    throw UnimplementedError(
      'Secret creation requires Vault integration. Coming soon.',
    );
  }

  Future<void> updateSecret({
    required String documentId,
    required String name,
    String? value,
  }) async {
    final supabase = ref.read(supabaseClientProvider);
    await supabase
        .from('environment_variables')
        .update({
          'key': name,
        })
        .eq('id', documentId);
  }
}

@freezed
abstract class Secret with _$Secret {
  const factory Secret({
    required String id,
    required String name,
    required String teamId,
    String? pathToSecret,
    @DateTimeConverter() required DateTime createdAt,
    @DateTimeConverter() required DateTime updatedAt,
  }) = _Secret;

  factory Secret.fromJson(Map<String, Object?> json) => _$SecretFromJson(json);
}
