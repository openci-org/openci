import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_cli_plus/src/credential_store/credential_config.dart';
import 'package:openci_cli_plus/src/mcp/build_api.dart';
import 'package:test/test.dart';

void main() {
  test('retryBuildJob sends the observed zero count in one mutation', () async {
    const profile = AuthProfile(
      authType: 'firebase',
      firebaseProjectId: 'demo-openci',
      token: 'test-token',
    );
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      return http.Response('{"data":{"retried":1}}', 200);
    });

    final api = BuildApi(profile, client);
    final result = await api.retryBuildJob(jobId: 'job', expectedRetryCount: 0);

    final request = requests.single;
    expect(request.method, 'POST');
    expect(request.url.path, endsWith('/connectors/builds:executeMutation'));
    expect(request.headers['X-Firebase-Auth-Token'], profile.token);
    expect(jsonDecode(request.body), {
      'operationName': 'RetryBuildJob',
      'variables': {'id': 'job', 'expectedRetryCount': 0},
    });
    expect(result, {'retried': 1});
  });
}
