import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

import 'create_build_jobs.dart';
import 'data_connect.dart';
import 'github_workflows.dart';

Uri dataConnectServiceUri(Map<String, String> environment) {
  final project =
      environment['GCLOUD_PROJECT'] ?? environment['GOOGLE_CLOUD_PROJECT'];
  if (project == null || !RegExp(r'^[a-z][a-z0-9-]+$').hasMatch(project)) {
    throw StateError('Missing Firebase project');
  }
  final host = environment['DATA_CONNECT_EMULATOR_HOST'];
  var origin = 'https://firebasedataconnect.googleapis.com';
  if (host != null) {
    if (environment['FUNCTIONS_EMULATOR'] != 'true' ||
        !project.startsWith('demo-') ||
        !RegExp(r'^(127\.0\.0\.1|localhost):\d+$').hasMatch(host)) {
      throw StateError('SQL Connect emulator must use a local demo project');
    }
    origin = 'http://$host';
  }
  return Uri.parse(
    '$origin/v1/projects/$project/locations/asia-northeast1/services/openci-b1b91-service',
  );
}

Future<String> runPlanner(
  String taskId, {
  required Map<String, String> environment,
  required String githubAppId,
  required String githubPrivateKey,
  required String githubApiBaseUrl,
  required String githubBaseUrl,
}) async {
  final serviceUri = dataConnectServiceUri(environment);
  final http.Client sqlClient = serviceUri.scheme == 'http'
      ? http.Client()
      : await clientViaApplicationDefaultCredentials(
          scopes: ['https://www.googleapis.com/auth/cloud-platform'],
        );
  final githubClient = http.Client();
  try {
    final workflows = GitHubWorkflows(
      client: githubClient,
      apiBaseUrl: githubApiBaseUrl,
      appJwt: () => GitHubWorkflows.signAppJwt(githubAppId, githubPrivateKey),
      allowLocalHttp: environment['FUNCTIONS_EMULATOR'] == 'true',
    );
    final planner = BuildJobPlanner(
      store: DataConnectPlanningStore(
        client: sqlClient,
        serviceUri: serviceUri,
        githubAppId: githubAppId,
        githubApiBaseUrl: githubApiBaseUrl,
        githubBaseUrl: githubBaseUrl,
      ),
      fetchWorkflows: workflows.fetch,
    );
    return await planner.process(taskId);
  } finally {
    sqlClient.close();
    githubClient.close();
  }
}
