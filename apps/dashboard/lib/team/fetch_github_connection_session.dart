import 'package:dashboard/team/github_connection_context.dart';
import 'package:dashboard/team/parse_github_connection_return.dart';
import 'package:openci_shared/openci_shared.dart';

import 'github_connection_api.dart';

Future<GitHubConnectionSession> fetchGitHubConnectionSession({
  required GitHubConnectionApi api,
  required GitHubConnectionContext initiatingContext,
  required String reference,
}) async {
  try {
    if (api.context != initiatingContext) {
      throw GitHubConnectionReturnError.forbidden;
    }
    final session = await api.session(reference);
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
