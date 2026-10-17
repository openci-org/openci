@TestOn('browser')
library;

import 'dart:convert';

import 'package:dashboard/team/github_connection_context.dart';
import 'package:dashboard/team/github_connection_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;

void main() {
  const storageKey = 'github_connection_context_v1';
  const unrelatedKey = 'github_connection_storage_test_unrelated';
  const context = GitHubConnectionContext(
    profileId: 'self-hosted',
    apiUrl: 'https://ci.example.test/api',
    userId: 'user-1',
    teamId: 'team-1',
  );

  tearDown(() {
    web.window.sessionStorage.removeItem(storageKey);
    web.window.sessionStorage.removeItem(unrelatedKey);
    web.window.localStorage.removeItem(storageKey);
  });

  test('saves only the four context fields in session storage', () {
    web.window.localStorage.setItem(storageKey, 'keep-local-value');

    saveGitHubConnectionContext(context);

    expect(jsonDecode(web.window.sessionStorage.getItem(storageKey)!), {
      'profileId': 'self-hosted',
      'apiUrl': 'https://ci.example.test/api',
      'userId': 'user-1',
      'teamId': 'team-1',
    });
    expect(web.window.localStorage.getItem(storageKey), 'keep-local-value');
  });

  test('replaces the previous attempt with the latest context', () {
    saveGitHubConnectionContext(context);
    final nextContext = context.copyWith(teamId: 'team-2');

    saveGitHubConnectionContext(nextContext);

    final saved =
        jsonDecode(web.window.sessionStorage.getItem(storageKey)!)
            as Map<String, dynamic>;
    expect(GitHubConnectionContext.fromJson(saved), nextContext);
  });

  test('clears only the connection context and can be called again', () {
    web.window.sessionStorage.setItem(unrelatedKey, 'keep-session-value');
    saveGitHubConnectionContext(context);

    clearGitHubConnectionContext();
    clearGitHubConnectionContext();

    expect(web.window.sessionStorage.getItem(storageKey), isNull);
    expect(
      web.window.sessionStorage.getItem(unrelatedKey),
      'keep-session-value',
    );
  });
}
