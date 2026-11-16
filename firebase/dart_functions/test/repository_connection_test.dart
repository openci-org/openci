import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_dart_functions/src/data_connect.dart';
import 'package:test/test.dart';

void main() {
  final legacy = {
    'id': 'legacy',
    'teamId': 'legacy-team',
    'accountId': '20',
    'installationId': '30',
    'status': 'active',
  };
  final repository = {
    ...legacy,
    'id': 'repository',
    'teamId': 'repository-team',
    'repositoryId': '10',
  };
  Future<PlanningConnection?> lookup(Map<String, Object?> data) {
    final store = DataConnectPlanningStore(
      client: MockClient((request) async {
        final body = jsonDecode(request.body) as Map;
        expect(body['operationName'], 'GetGitHubRepositoryConnection');
        expect(body['variables'], {
          'githubAppId': '1',
          'githubApiBaseUrl': 'https://api.github.com',
          'installationId': '30',
          'repositoryId': '10',
        });
        return http.Response(jsonEncode({'data': data}), 200);
      }),
      serviceUri: Uri.parse('https://sql.example.test'),
      githubAppId: '1',
      githubApiBaseUrl: 'https://api.github.com',
      githubBaseUrl: 'https://github.com',
    );
    return store.findConnection(30, 10);
  }

  test(
    'routes the selected repository and preserves legacy connections',
    () async {
      expect(
        (await lookup({'connection': repository}))?.teamId,
        'repository-team',
      );
      expect(
        (await lookup({'legacyConnection': legacy}))?.teamId,
        'legacy-team',
      );
      expect(
        (await lookup({
          'connection': repository,
          'legacyConnection': legacy,
        }))?.id,
        'repository',
      );
      expect(await lookup({}), isNull);
    },
  );

  test(
    'inactive or transferred repository claims cannot fall back to the whole organization',
    () async {
      for (final state in [
        {...repository, 'status': 'suspended'},
        {...repository, 'status': 'removed'},
        {...repository, 'installationId': '99'},
      ]) {
        expect(
          await lookup({'connection': state, 'legacyConnection': legacy}),
          isNull,
        );
      }
    },
  );
}
