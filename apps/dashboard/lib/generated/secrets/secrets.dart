library secrets;

import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

part 'get_managed_secret_context.dart';

part 'commit_managed_secret.dart';

part 'rename_managed_secret.dart';

part 'delete_managed_secret.dart';

part 'queue_secret_version_cleanup.dart';

part 'get_due_secret_versions.dart';

part 'get_secret_version_references.dart';

part 'complete_secret_version_cleanup.dart';

part 'create_secret_reference.dart';

part 'update_secret_reference.dart';

part 'delete_secret_reference.dart';

part 'get_secrets.dart';

part 'get_secret_reference.dart';

String? bigIntToJson(BigInt? value) {
  return value?.toString();
}

BigInt bigIntFromJson(dynamic value) {
  return BigInt.parse(value);
}

class SecretsConnector {
  GetManagedSecretContextVariablesBuilder getManagedSecretContext({
    required String teamId,
    required String actorUid,
  }) {
    return GetManagedSecretContextVariablesBuilder(
      dataConnect,
      teamId: teamId,
      actorUid: actorUid,
    );
  }

  CommitManagedSecretVariablesBuilder commitManagedSecret({
    required String teamId,
    required String actorUid,
    required String name,
    required String path,
  }) {
    return CommitManagedSecretVariablesBuilder(
      dataConnect,
      teamId: teamId,
      actorUid: actorUid,
      name: name,
      path: path,
    );
  }

  RenameManagedSecretVariablesBuilder renameManagedSecret({
    required String teamId,
    required String actorUid,
    required String name,
    required String newName,
    required String expectedPath,
  }) {
    return RenameManagedSecretVariablesBuilder(
      dataConnect,
      teamId: teamId,
      actorUid: actorUid,
      name: name,
      newName: newName,
      expectedPath: expectedPath,
    );
  }

  DeleteManagedSecretVariablesBuilder deleteManagedSecret({
    required String teamId,
    required String actorUid,
    required String name,
    required String expectedPath,
  }) {
    return DeleteManagedSecretVariablesBuilder(
      dataConnect,
      teamId: teamId,
      actorUid: actorUid,
      name: name,
      expectedPath: expectedPath,
    );
  }

  QueueSecretVersionCleanupVariablesBuilder queueSecretVersionCleanup({
    required String path,
  }) {
    return QueueSecretVersionCleanupVariablesBuilder(
      dataConnect,
      path: path,
    );
  }

  GetDueSecretVersionsVariablesBuilder getDueSecretVersions() {
    return GetDueSecretVersionsVariablesBuilder(
      dataConnect,
    );
  }

  GetSecretVersionReferencesVariablesBuilder getSecretVersionReferences({
    required String path,
  }) {
    return GetSecretVersionReferencesVariablesBuilder(
      dataConnect,
      path: path,
    );
  }

  CompleteSecretVersionCleanupVariablesBuilder completeSecretVersionCleanup({
    required String path,
  }) {
    return CompleteSecretVersionCleanupVariablesBuilder(
      dataConnect,
      path: path,
    );
  }

  CreateSecretReferenceVariablesBuilder createSecretReference({
    required String teamId,
    required String name,
    required String secretVersionPath,
  }) {
    return CreateSecretReferenceVariablesBuilder(
      dataConnect,
      teamId: teamId,
      name: name,
      secretVersionPath: secretVersionPath,
    );
  }

  UpdateSecretReferenceVariablesBuilder updateSecretReference({
    required String teamId,
    required String name,
    required String expectedSecretVersionPath,
    required String secretVersionPath,
  }) {
    return UpdateSecretReferenceVariablesBuilder(
      dataConnect,
      teamId: teamId,
      name: name,
      expectedSecretVersionPath: expectedSecretVersionPath,
      secretVersionPath: secretVersionPath,
    );
  }

  DeleteSecretReferenceVariablesBuilder deleteSecretReference({
    required String teamId,
    required String name,
    required String expectedSecretVersionPath,
  }) {
    return DeleteSecretReferenceVariablesBuilder(
      dataConnect,
      teamId: teamId,
      name: name,
      expectedSecretVersionPath: expectedSecretVersionPath,
    );
  }

  GetSecretsVariablesBuilder getSecrets({
    required String teamId,
  }) {
    return GetSecretsVariablesBuilder(
      dataConnect,
      teamId: teamId,
    );
  }

  GetSecretReferenceVariablesBuilder getSecretReference({
    required String teamId,
    required String name,
  }) {
    return GetSecretReferenceVariablesBuilder(
      dataConnect,
      teamId: teamId,
      name: name,
    );
  }

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'asia-northeast1',
    'secrets',
    'openci-b1b91-service',
  );

  SecretsConnector({required this.dataConnect});
  static SecretsConnector get instance {
    CacheSettings cacheSettings = CacheSettings(
      maxAge: Duration(milliseconds: 5000),
      storage: CacheStorage.persistent,
    );

    return SecretsConnector(
      dataConnect: FirebaseDataConnect.instanceFor(
        connectorConfig: connectorConfig,

        cacheSettings: cacheSettings,

        sdkType: CallerSDKType.generated,
      ),
    );
  }

  FirebaseDataConnect dataConnect;
}
