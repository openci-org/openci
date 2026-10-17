import 'package:dashboard/team/github_connection_context.dart';
import 'package:dashboard/team/parse_github_connection_return.dart';

String readGitHubConnectionReference({
  required GitHubConnectionReturn? result,
  required GitHubConnectionContext? initiatingContext,
  required GitHubConnectionContext? currentContext,
}) {
  final error = result?.error;
  if (error != null) throw error;

  final reference = result?.reference;
  if (reference == null) {
    throw GitHubConnectionReturnError.invalidResult;
  }
  if (initiatingContext == null || initiatingContext != currentContext) {
    throw GitHubConnectionReturnError.forbidden;
  }
  return reference;
}
