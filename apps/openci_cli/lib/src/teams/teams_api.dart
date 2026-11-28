import '../credential_store/credential_config.dart';
import '../functions/callable_api.dart';

class TeamsApi extends CallableApi {
  TeamsApi(AuthProfile profile, {super.client, super.timeout})
    : super(profile, 'teamManagement');

  Future<FunctionResponse> getTeams() => call({'action': 'list'});
}
