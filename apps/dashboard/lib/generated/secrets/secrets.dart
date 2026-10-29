library secrets;

import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

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
    return SecretsConnector(
      dataConnect: FirebaseDataConnect.instanceFor(
        connectorConfig: connectorConfig,

        sdkType: CallerSDKType.generated,
      ),
    );
  }

  FirebaseDataConnect dataConnect;
}
