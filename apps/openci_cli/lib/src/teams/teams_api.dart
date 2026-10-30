import 'package:http/http.dart' as http;

import '../credential_store/credential_config.dart';
import '../functions/callable_api.dart';

class TeamsApi extends CallableApi {
  TeamsApi(
    AuthProfile profile, {
    http.Client? client,
    Duration timeout = const Duration(seconds: 65),
  }) : super(profile, 'teamManagement', client: client, timeout: timeout);

  Future<FunctionResponse> getTeams() => call({'action': 'list'});
}
