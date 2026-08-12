import 'dart:async';

import 'package:dashboard/api/openci_api_client.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secret_manager_provider.freezed.dart';
part 'secret_manager_provider.g.dart';

@riverpod
class SecretManager extends _$SecretManager {
  @override
  Stream<List<Secret>> build() async* {
    final teamId = ref.watch(selectedTeamProvider).value?.id;
    if (teamId == null) {
      yield const [];
      return;
    }

    yield await _fetchSecrets(teamId);

    yield* Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
      return _fetchSecrets(teamId);
    });
  }

  Future<List<Secret>> _fetchSecrets(String teamId) async {
    try {
      final api = ref.read(openciApiServiceProvider);
      final response = await api.getSecrets(teamId);

      if (!response.isSuccessful || response.body == null) return const [];

      final data = response.body!;
      final list = data['secrets'] as List<dynamic>? ?? [];

      return list.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        final name = map['name'] as String? ?? '';
        return Secret(
          id: name, // UIとの互換性のために、idにはnameを割り当てます
          name: name,
          teamId: map['teamId'] as String? ?? '',
          createdAt: DateTime.parse(map['createdAt'] as String).toLocal(),
          updatedAt: DateTime.parse(map['updatedAt'] as String).toLocal(),
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> addSecret(String name, String value) async {
    final teamId = ref.read(selectedTeamProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');

    final api = ref.read(openciApiServiceProvider);
    final response = await api.saveSecret(teamId, {
      'name': name,
      'value': value,
    });

    if (!response.isSuccessful) {
      throw StateError(
        'Failed to add secret: ${response.statusCode} ${response.error}',
      );
    }
  }

  Future<void> updateSecret({
    required String documentId,
    required String name,
    String? value,
  }) async {
    final nameChanged = documentId != name;

    // 1. 名前が変更されており、新しい値が入力されていない場合は、古いシークレットの値を読み込む
    String? effectiveValue = value;
    if (nameChanged && (effectiveValue == null || effectiveValue.isEmpty)) {
      effectiveValue = await readSecret(documentId: documentId);
    }

    // 2. 新しい名前（または同じ名前）でシークレットを新規追加・上書き更新
    if (effectiveValue != null && effectiveValue.isNotEmpty) {
      await addSecret(name, effectiveValue);
    }

    // 3. 名前が変更されていた場合は、古いシークレットを削除
    if (nameChanged) {
      await deleteSecret(documentId: documentId);
    }
  }

  Future<String> readSecret({required String documentId}) async {
    final teamId = ref.read(selectedTeamProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');

    final api = ref.read(openciApiServiceProvider);
    final response = await api.getSecretValue(teamId, documentId);

    if (!response.isSuccessful || response.body == null) {
      throw StateError(
        'Failed to read secret: ${response.statusCode} ${response.error}',
      );
    }

    return response.body!['value'] as String? ?? '';
  }

  Future<void> deleteSecret({required String documentId}) async {
    final teamId = ref.read(selectedTeamProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');

    final api = ref.read(openciApiServiceProvider);
    final response = await api.deleteSecret(teamId, documentId);

    if (!response.isSuccessful) {
      throw StateError(
        'Failed to delete secret: ${response.statusCode} ${response.error}',
      );
    }
  }

  Future<void> generateCertificateKey() async {
    final teamId = ref.read(selectedTeamProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');

    final api = ref.read(openciApiServiceProvider);
    final response = await api.generateCertificateKey(teamId);

    if (!response.isSuccessful) {
      throw StateError(
        'Failed to generate certificate key: ${response.statusCode} ${response.error}',
      );
    }
    ref.invalidateSelf();
  }

  Future<void> setupAscApiKey({
    required String issuerId,
    required String keyId,
    required String privateKey,
  }) async {
    final teamId = ref.read(selectedTeamProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');

    final api = ref.read(openciApiServiceProvider);
    final response = await api.setupAscApiKey(teamId, {
      'issuerId': issuerId,
      'keyId': keyId,
      'privateKey': privateKey,
    });

    if (!response.isSuccessful) {
      throw StateError(
        'Failed to setup App Store Connect API Key: ${response.statusCode} ${response.error}',
      );
    }
    ref.invalidateSelf();
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
