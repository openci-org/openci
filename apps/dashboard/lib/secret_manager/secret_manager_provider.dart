import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'secrets_backend.dart';

part 'secret_manager_provider.freezed.dart';
part 'secret_manager_provider.g.dart';

@riverpod
class SecretManager extends _$SecretManager {
  @override
  Stream<List<Secret>> build() async* {
    final user = await ref.watch(authStateChangesProvider.future);
    final teamId = ref.watch(selectedTeamProvider).value?.id;
    if (user == null || teamId == null) {
      yield [];
      return;
    }
    final connector = await ref.watch(secretsConnectorProvider.future);
    yield* connector
        .getSecrets(teamId: teamId)
        .ref()
        .subscribe()
        .map(
          (result) => result.data.secrets
              .map(
                (secret) => Secret(
                  id: secret.name,
                  name: secret.name,
                  teamId: secret.teamId,
                  createdAt: DateTime.fromMillisecondsSinceEpoch(
                    secret.createdAt.toInt() * 1000,
                    isUtc: true,
                  ),
                  updatedAt: DateTime.fromMillisecondsSinceEpoch(
                    secret.updatedAt.toInt() * 1000,
                    isUtc: true,
                  ),
                ),
              )
              .toList(),
        );
  }

  Future<Map<String, dynamic>> _call(
    String action,
    Map<String, dynamic> data,
  ) async {
    final team = ref.read(selectedTeamProvider);
    final user = ref.read(authStateChangesProvider);
    final teamId = team.value?.id;
    final uid = user.value?.uid;
    if (teamId == null ||
        uid == null ||
        team.isLoading ||
        user.isLoading ||
        team.hasError ||
        user.hasError) {
      throw StateError('Sign in to manage secrets');
    }
    final pending = ref.read(teamSecretsCallableProvider.future);
    bool sameContext() =>
        ref.mounted &&
        !ref.read(selectedTeamProvider).isLoading &&
        !ref.read(selectedTeamProvider).hasError &&
        !ref.read(authStateChangesProvider).isLoading &&
        !ref.read(authStateChangesProvider).hasError &&
        ref.read(selectedTeamProvider).value?.id == teamId &&
        ref.read(authStateChangesProvider).value?.uid == uid &&
        identical(ref.read(teamSecretsCallableProvider.future), pending);
    final callable = await pending;
    if (!sameContext()) throw StateError('Account or team changed');
    final result = await callable.call<Map<String, dynamic>>({
      'action': action,
      'teamId': teamId,
      ...data,
    });
    if (!sameContext()) throw StateError('Account or team changed');
    if (action != 'read') ref.invalidateSelf();
    return result.data;
  }

  Future<void> addSecret(String name, String value) async {
    await _call('save', {'name': name, 'value': value});
  }

  Future<void> updateSecret({
    required String documentId,
    required String name,
    String? value,
  }) async {
    if (documentId != name) {
      await _call('rename', {
        'name': documentId,
        'newName': name,
        if (value != null && value.isNotEmpty) 'value': value,
      });
    } else if (value != null && value.isNotEmpty) {
      await addSecret(name, value);
    }
  }

  Future<String> readSecret({required String documentId}) async =>
      (await _call('read', {'name': documentId}))['value'] as String;
  Future<void> deleteSecret({required String documentId}) async {
    await _call('delete', {'name': documentId});
  }

  Future<void> generateCertificateKey() async {
    await _call('generateCertificateKey', {});
  }
}

@freezed
abstract class Secret with _$Secret {
  const factory Secret({
    required String id,
    required String name,
    required String teamId,
    @DateTimeConverter() required DateTime createdAt,
    @DateTimeConverter() required DateTime updatedAt,
  }) = _Secret;

  factory Secret.fromJson(Map<String, Object?> json) => _$SecretFromJson(json);
}
