import 'dart:convert';

import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/firebase/firestore.dart';
import 'package:dashboard/firebase/functions.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secret_manager_provider.freezed.dart';
part 'secret_manager_provider.g.dart';

@riverpod
class SecretManager extends _$SecretManager {
  @override
  Stream<List<Secret>> build() async* {
    const serverUrl = String.fromEnvironment('OPENCI_SERVER_URL');
    if (serverUrl.isEmpty) {
      throw UnimplementedError('OPENCI_SERVER_URL is not set');
    }

    final teamId = ref.watch(teamStateProvider).value?.id;
    if (teamId == null) {
      yield const [];
      return;
    }

    yield await _fetchSecrets(serverUrl, teamId);

    yield* Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
      return _fetchSecrets(serverUrl, teamId);
    });
  }

  Future<List<Secret>> _fetchSecrets(String serverUrl, String teamId) async {
    try {
      final url = Uri.parse('$serverUrl/teams/$teamId/secrets');
      final token = await ref.watch(firebaseIdTokenProvider.future);
      if (token == null) return const [];

      final response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return const [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = data['secrets'] as List<dynamic>;

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
    } catch (e) {
      return const [];
    }
  }

  Future<void> addSecret(String name, String value) async {
    const serverUrl = String.fromEnvironment('OPENCI_SERVER_URL');
    if (serverUrl.isEmpty) throw StateError('OPENCI_SERVER_URL is not set');

    final teamId = ref.read(teamStateProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');

    final url = Uri.parse('$serverUrl/teams/$teamId/secrets');
    final token = await ref.read(firebaseIdTokenProvider.future);
    if (token == null) throw StateError('User is not authenticated');

    final response = await http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'name': name,
            'value': value,
          }),
        )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) {
      throw StateError(
        'Failed to add secret: ${response.statusCode} ${response.body}',
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
    const serverUrl = String.fromEnvironment('OPENCI_SERVER_URL');
    if (serverUrl.isEmpty) throw StateError('OPENCI_SERVER_URL is not set');

    final teamId = ref.read(teamStateProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');

    final url = Uri.parse('$serverUrl/teams/$teamId/secrets/$documentId');
    final token = await ref.read(firebaseIdTokenProvider.future);
    if (token == null) throw StateError('User is not authenticated');

    final response = await http
        .get(
          url,
          headers: {
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) {
      throw StateError(
        'Failed to read secret: ${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['value'] as String? ?? '';
  }

  Future<void> deleteSecret({required String documentId}) async {
    const serverUrl = String.fromEnvironment('OPENCI_SERVER_URL');
    if (serverUrl.isEmpty) throw StateError('OPENCI_SERVER_URL is not set');

    final teamId = ref.read(teamStateProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');

    final url = Uri.parse('$serverUrl/teams/$teamId/secrets/$documentId');
    final token = await ref.read(firebaseIdTokenProvider.future);
    if (token == null) throw StateError('User is not authenticated');

    final response = await http
        .delete(
          url,
          headers: {
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) {
      throw StateError(
        'Failed to delete secret: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<void> generateCertificateKey() async {
    final functions = firebaseFunctions;
    final teamId = ref.read(teamStateProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');
    await functions.httpsCallable('generateCertificateKeyV1').call({
      'teamId': teamId,
    });
  }

  Future<void> setupAscApiKey({
    required String issuerId,
    required String keyId,
    required String privateKey,
  }) async {
    final functions = firebaseFunctions;
    final teamId = ref.read(teamStateProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');
    await functions.httpsCallable('setupAscApiKeyV1').call({
      'teamId': teamId,
      'issuerId': issuerId,
      'keyId': keyId,
      'privateKey': privateKey,
    });
  }

  Future<String> generateDeveloperIdCsr() async {
    final functions = firebaseFunctions;
    final teamId = ref.read(teamStateProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');
    final result = await functions
        .httpsCallable('generateDeveloperIdCsrV1')
        .call({
          'teamId': teamId,
        });
    final data = Map<String, dynamic>.from(result.data as Map);
    return data['csrPem'] as String? ?? '';
  }

  Future<void> registerDeveloperIdCertificate({
    required String certificateBase64,
  }) async {
    final functions = firebaseFunctions;
    final teamId = ref.read(teamStateProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');
    await functions.httpsCallable('registerDeveloperIdCertificateV1').call({
      'teamId': teamId,
      'certificateBase64': certificateBase64,
    });
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
