import 'package:dashboard/team/github_connection_context.dart';
import 'package:dashboard/team/parse_github_connection_return.dart';
import 'package:openci_shared/openci_shared.dart';

Future<GitHubConnectionSession> fetchGitHubConnectionSession({
  required OpenCIApiService api,
  required GitHubConnectionContext initiatingContext,
  required String reference,
}) async {
  try {
    if (api.client.baseUrl != Uri.tryParse(initiatingContext.apiUrl)) {
      throw GitHubConnectionReturnError.forbidden;
    }
    final response = await api.getGitHubConnectionSession(
      initiatingContext.teamId,
      reference,
    );
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw GitHubConnectionReturnError.forbidden;
    }
    if (!response.isSuccessful || response.body?.success != true) {
      throw GitHubConnectionReturnError.connectionFailed;
    }
    final session = response.body!.session;
    if (session.teamId != initiatingContext.teamId) {
      throw GitHubConnectionReturnError.forbidden;
    }
    return session;
  } on GitHubConnectionReturnError {
    rethrow;
  } catch (_) {
    throw GitHubConnectionReturnError.connectionFailed;
  }
}
