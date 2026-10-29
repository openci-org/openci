import 'package:dashboard/generated/github/github.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('GitHub metadata preserves IDs beyond JavaScript integer precision', () {
    final data = GetGitHubConnectionsData.fromJson({
      'connections': [
        {
          'id': 'connection',
          'teamId': 'team',
          'githubApiBaseUrl': 'https://api.github.com',
          'githubAppId': '9007199254740993',
          'installationId': '9007199254740994',
          'accountId': '9007199254740995',
          'accountType': 'Organization',
          'accountLogin': 'test-org',
          'status': 'active',
          'verifiedAt': '1790000000',
        },
      ],
    });
    final connection = data.connections.single;
    expect(connection.installationId, BigInt.parse('9007199254740994'));
    expect(connection.toJson()['githubAppId'], '9007199254740993');
    expect(
      connection.toJson(),
      isNot(contains('accessTokenSecretVersionPath')),
    );
  });

  test('absent connections and sessions deserialize as null', () {
    expect(
      GetActiveGitHubConnectionData.fromJson({'connection': null}).connection,
      isNull,
    );
    expect(
      GetGitHubConnectionSessionData.fromJson({'session': null}).session,
      isNull,
    );
  });

  test('expired consumed sessions may have no token reference', () {
    final data = GetExpiredGitHubConnectionCredentialsData.fromJson({
      'requests': [],
      'sessions': [
        {'id': 'session', 'accessTokenSecretVersionPath': null},
      ],
    });
    expect(data.requests, isEmpty);
    expect(data.sessions.single.accessTokenSecretVersionPath, isNull);
  });
}
