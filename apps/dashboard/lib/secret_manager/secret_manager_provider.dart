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
    throw UnimplementedError(
      'TODO: Migrate to Firebase Data Connect',
    );
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
    throw UnimplementedError(
      'TODO: Migrate to Firebase Data Connect',
    );
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
