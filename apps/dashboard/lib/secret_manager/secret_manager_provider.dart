import 'package:dashboard/firebase/dart_function_urls.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/firebase/dataconnect.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/utilities/date_time_converter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secret_manager_provider.freezed.dart';
part 'secret_manager_provider.g.dart';

@riverpod
class SecretManager extends _$SecretManager {
  @override
  Stream<List<Secret>> build() {
    return secretsStream();
  }

  Stream<List<Secret>> secretsStream() {
    final teamId = ref.watch(teamStateProvider).value?.id;
    if (teamId == null) return Stream.value([]);
    return dataConnector
        .listSecretsForTeam(teamId: teamId)
        .ref()
        .subscribe()
        .map(
          (result) => result.data.secrets
              .map(
                (secret) => Secret(
                  id: secret.id,
                  name: secret.name,
                  teamId: secret.teamId,
                  pathToSecret: secret.pathToSecret,
                  createdAt: dateTimeFromDataConnect(secret.createdAt),
                  updatedAt: dateTimeFromDataConnect(secret.updatedAt),
                ),
              )
              .toList(),
        );
  }

  Future<void> addSecret(String name, String value) async {
    final functions = FirebaseFunctions.instance;
    final teamId = ref.read(teamStateProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');
    await functions
        .httpsCallableFromUrl(dartFunctionUrl('createsecretv1'))
        .call({
          'name': name,
          'value': value,
          'teamId': teamId,
        });
  }

  Future<void> updateSecret({
    required String documentId,
    required String name,
    String? value,
  }) async {
    final functions = FirebaseFunctions.instance;
    final teamId = ref.read(teamStateProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');
    await functions
        .httpsCallableFromUrl(dartFunctionUrl('updatesecretv1'))
        .call({
          'documentId': documentId,
          'name': name,
          if (value != null && value.isNotEmpty) 'value': value,
          'teamId': teamId,
        });
  }

  Future<void> deleteSecret({required String documentId}) async {
    final functions = FirebaseFunctions.instance;
    final teamId = ref.read(teamStateProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');
    await functions
        .httpsCallableFromUrl(dartFunctionUrl('deletesecretv1'))
        .call({
          'documentId': documentId,
          'teamId': teamId,
        });
  }

  Future<void> generateCertificateKey() async {
    final functions = FirebaseFunctions.instance;
    final teamId = ref.read(teamStateProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');
    await functions
        .httpsCallableFromUrl(dartFunctionUrl('generatecertificatekeyv1'))
        .call({
          'teamId': teamId,
        });
  }

  Future<void> setupAscApiKey({
    required String issuerId,
    required String keyId,
    required String privateKey,
  }) async {
    final functions = FirebaseFunctions.instance;
    final teamId = ref.read(teamStateProvider).value?.id;
    if (teamId == null) throw StateError('team is not loaded yet');
    await functions
        .httpsCallableFromUrl(dartFunctionUrl('setup-asc-api-key-v1'))
        .call({
          'teamId': teamId,
          'issuerId': issuerId,
          'keyId': keyId,
          'privateKey': privateKey,
        });
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
