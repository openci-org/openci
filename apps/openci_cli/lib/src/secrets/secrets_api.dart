import 'package:http/http.dart' as http;

import '../credential_store/credential_config.dart';
import '../functions/callable_api.dart';

typedef SecretResponse = FunctionResponse;

class SecretsApi extends CallableApi {
  SecretsApi(AuthProfile profile, {http.Client? client})
    : super(profile, 'teamSecrets', client: client);

  Future<SecretResponse> getSecrets(String teamId) =>
      call({'action': 'list', 'teamId': teamId});
  Future<SecretResponse> saveSecret(
    String teamId,
    Map<String, dynamic> value,
  ) => call({'action': 'save', 'teamId': teamId, ...value});
  Future<SecretResponse> deleteSecret(String teamId, String name) =>
      call({'action': 'delete', 'teamId': teamId, 'name': name});
  Future<SecretResponse> generateCertificateKey(String teamId) =>
      call({'action': 'generateCertificateKey', 'teamId': teamId});
}

Uri secretFunctionEndpoint(AuthProfile profile) =>
    firebaseFunctionEndpoint(profile, 'teamSecrets');
