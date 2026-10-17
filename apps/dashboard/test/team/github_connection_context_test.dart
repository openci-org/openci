import 'package:dashboard/team/github_connection_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const context = GitHubConnectionContext(
    profileId: 'cloud',
    apiUrl: 'https://api.openci.test',
    userId: 'user-1',
    teamId: 'team-1',
  );

  test('matches another instance with the same connection context', () {
    final sameContext = GitHubConnectionContext(
      profileId: 'cloud',
      apiUrl: 'https://api.openci.test',
      userId: 'user-1',
      teamId: 'team-1',
    );

    expect(context.matches(sameContext), isTrue);
  });

  test('does not match a different user', () {
    const otherContext = GitHubConnectionContext(
      profileId: 'cloud',
      apiUrl: 'https://api.openci.test',
      userId: 'user-2',
      teamId: 'team-1',
    );

    expect(context.matches(otherContext), isFalse);
  });

  test('does not match a different team', () {
    const otherContext = GitHubConnectionContext(
      profileId: 'cloud',
      apiUrl: 'https://api.openci.test',
      userId: 'user-1',
      teamId: 'team-2',
    );

    expect(context.matches(otherContext), isFalse);
  });

  test('does not match a different connection profile', () {
    const otherContext = GitHubConnectionContext(
      profileId: 'another-profile',
      apiUrl: 'https://api.openci.test',
      userId: 'user-1',
      teamId: 'team-1',
    );

    expect(context.matches(otherContext), isFalse);
  });

  test('does not match a different API URL', () {
    const otherContext = GitHubConnectionContext(
      profileId: 'cloud',
      apiUrl: 'https://ci.example.com',
      userId: 'user-1',
      teamId: 'team-1',
    );

    expect(context.matches(otherContext), isFalse);
  });

  test('does not match a missing context', () {
    expect(context.matches(null), isFalse);
  });
}
