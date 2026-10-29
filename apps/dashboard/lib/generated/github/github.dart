library github;

import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

part 'get_expired_git_hub_connection_credentials.dart';

part 'delete_expired_git_hub_connection_request.dart';

part 'delete_expired_git_hub_connection_session.dart';

part 'confirm_git_hub_connection.dart';

part 'get_git_hub_connections.dart';

part 'get_active_git_hub_connection.dart';

part 'create_git_hub_connection_request.dart';

part 'consume_git_hub_connection_request.dart';

part 'create_git_hub_connection_session.dart';

part 'get_git_hub_connection_session.dart';

String? bigIntToJson(BigInt? value) {
  return value?.toString();
}

BigInt bigIntFromJson(dynamic value) {
  return BigInt.parse(value);
}

class GithubConnector {
  GetExpiredGitHubConnectionCredentialsVariablesBuilder
  getExpiredGitHubConnectionCredentials() {
    return GetExpiredGitHubConnectionCredentialsVariablesBuilder(
      dataConnect,
    );
  }

  DeleteExpiredGitHubConnectionRequestVariablesBuilder
  deleteExpiredGitHubConnectionRequest({
    required String id,
  }) {
    return DeleteExpiredGitHubConnectionRequestVariablesBuilder(
      dataConnect,
      id: id,
    );
  }

  DeleteExpiredGitHubConnectionSessionVariablesBuilder
  deleteExpiredGitHubConnectionSession({
    required String id,
  }) {
    return DeleteExpiredGitHubConnectionSessionVariablesBuilder(
      dataConnect,
      id: id,
    );
  }

  ConfirmGitHubConnectionVariablesBuilder confirmGitHubConnection({
    required String teamId,
    required String userId,
    required String referenceHash,
    required String githubApiBaseUrl,
    required BigInt githubAppId,
    required BigInt installationId,
    required BigInt accountId,
    required String accountType,
    required String accountLogin,
  }) {
    return ConfirmGitHubConnectionVariablesBuilder(
      dataConnect,
      teamId: teamId,
      userId: userId,
      referenceHash: referenceHash,
      githubApiBaseUrl: githubApiBaseUrl,
      githubAppId: githubAppId,
      installationId: installationId,
      accountId: accountId,
      accountType: accountType,
      accountLogin: accountLogin,
    );
  }

  GetGitHubConnectionsVariablesBuilder getGitHubConnections({
    required String teamId,
  }) {
    return GetGitHubConnectionsVariablesBuilder(
      dataConnect,
      teamId: teamId,
    );
  }

  GetActiveGitHubConnectionVariablesBuilder getActiveGitHubConnection({
    required String githubApiBaseUrl,
    required BigInt githubAppId,
    required BigInt installationId,
  }) {
    return GetActiveGitHubConnectionVariablesBuilder(
      dataConnect,
      githubApiBaseUrl: githubApiBaseUrl,
      githubAppId: githubAppId,
      installationId: installationId,
    );
  }

  CreateGitHubConnectionRequestVariablesBuilder createGitHubConnectionRequest({
    required String id,
    required String userId,
    required String teamId,
    required String stateHash,
    required String codeVerifierSecretVersionPath,
  }) {
    return CreateGitHubConnectionRequestVariablesBuilder(
      dataConnect,
      id: id,
      userId: userId,
      teamId: teamId,
      stateHash: stateHash,
      codeVerifierSecretVersionPath: codeVerifierSecretVersionPath,
    );
  }

  ConsumeGitHubConnectionRequestVariablesBuilder
  consumeGitHubConnectionRequest({
    required String stateHash,
  }) {
    return ConsumeGitHubConnectionRequestVariablesBuilder(
      dataConnect,
      stateHash: stateHash,
    );
  }

  CreateGitHubConnectionSessionVariablesBuilder createGitHubConnectionSession({
    required String id,
    required String userId,
    required String teamId,
    required BigInt githubUserId,
    required String referenceHash,
    required String accessTokenSecretVersionPath,
  }) {
    return CreateGitHubConnectionSessionVariablesBuilder(
      dataConnect,
      id: id,
      userId: userId,
      teamId: teamId,
      githubUserId: githubUserId,
      referenceHash: referenceHash,
      accessTokenSecretVersionPath: accessTokenSecretVersionPath,
    );
  }

  GetGitHubConnectionSessionVariablesBuilder getGitHubConnectionSession({
    required String teamId,
    required String userId,
    required String referenceHash,
  }) {
    return GetGitHubConnectionSessionVariablesBuilder(
      dataConnect,
      teamId: teamId,
      userId: userId,
      referenceHash: referenceHash,
    );
  }

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'asia-northeast1',
    'github',
    'openci-b1b91-service',
  );

  GithubConnector({required this.dataConnect});
  static GithubConnector get instance {
    return GithubConnector(
      dataConnect: FirebaseDataConnect.instanceFor(
        connectorConfig: connectorConfig,

        sdkType: CallerSDKType.generated,
      ),
    );
  }

  FirebaseDataConnect dataConnect;
}
