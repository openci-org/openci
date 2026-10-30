import 'dart:async';

import 'package:dashboard/team/github_connection_api.dart';
import 'package:dashboard/team/github_connection_context.dart';
import 'package:dashboard/team/parse_github_connection_return.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../helpers/github_connection_callable.dart';

void main() {
  const context = GitHubConnectionContext(
    profileId: 'profile',
    apiUrl: 'https://api.test',
    userId: 'user',
    teamId: 'team',
  );

  test(
    'does not send a stale callable or accept its result after a context change',
    () async {
      var current = false;
      final calls = <http.Request>[];
      final response = Completer<http.Response>();
      final api = GitHubConnectionApi(
        context: context,
        callable: TestGitHubCallable((request) {
          calls.add(request);
          return response.future;
        }),
        isCurrent: () => current,
      );
      await expectLater(
        api.start(),
        throwsA(GitHubConnectionReturnError.forbidden),
      );
      expect(calls, isEmpty);
      current = true;
      final pending = api.confirm('private-reference', 123);
      expect(callableData(calls.single), {
        'action': 'confirm',
        'teamId': 'team',
        'reference': 'private-reference',
        'installationId': 123,
      });
      current = false;
      response.complete(http.Response('{"success":true}', 200));
      await expectLater(
        pending,
        throwsA(GitHubConnectionReturnError.forbidden),
      );
    },
  );
}
