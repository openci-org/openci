@TestOn('browser')
library;

import 'dart:async';
import 'dart:convert';

import 'package:dashboard/api/openci_api_client.dart';
import 'package:dashboard/app_strings.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/connections/active_connection_profile_provider.dart';
import 'package:dashboard/connections/connection_profile.dart';
import 'package:dashboard/connections/connection_store.dart';
import 'package:dashboard/connections/connection_store_provider.dart';
import 'package:dashboard/team/github_connection_context.dart';
import 'package:dashboard/team/github_connection_page.dart';
import 'package:dashboard/team/github_connection_storage.dart';
import 'package:dashboard/team/parse_github_connection_return.dart';
import 'package:dashboard/team/pending_github_connection_return_provider.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const profile = ConnectionProfile(
    id: 'self-hosted',
    name: 'Self hosted',
    apiUrl: 'https://ci.example.test',
    firebase: {},
  );
  const initiatingContext = GitHubConnectionContext(
    profileId: 'self-hosted',
    apiUrl: 'https://ci.example.test',
    userId: 'user-1',
    teamId: 'team-1',
  );
  final team = Team(
    id: 'team-1',
    name: 'Team 1',
    members: const ['user-1'],
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
  const reference = 'private-reference';
  late ConnectionStore store;
  late ProviderContainer container;
  late GoRouter router;
  late FutureOr<ConnectionProfile> selectedProfile;
  late FutureOr<Team> selectedTeam;
  late String? userId;
  late GitHubConnectionReturn? result;
  late List<http.Request> requests;
  late Future<http.Response> Function(http.Request) respond;
  Future<void>? apiReady;

  http.Response jsonResponse(Object body, {int status = 200}) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  http.Response sessionResponse() => jsonResponse({
    'success': true,
    'session': {
      'teamId': 'team-1',
      'githubUserId': 123,
      'expiresAt': DateTime.utc(2026, 10, 18, 12, 10).toIso8601String(),
    },
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = ConnectionStore(await SharedPreferences.getInstance(), profile);
    saveGitHubConnectionContext(initiatingContext);
    selectedProfile = profile;
    selectedTeam = team;
    userId = 'user-1';
    result = parseGitHubConnectionReturn('reference=$reference');
    requests = [];
    respond = (_) async => sessionResponse();
    apiReady = null;
  });

  tearDown(clearGitHubConnectionContext);

  Future<void> pumpPage(WidgetTester tester) async {
    final client = http.runWithClient(
      () => createOpenCIChopperClient(
        baseUrl: profile.apiUrl,
        tokenProvider: () => 'firebase-id-token',
      ),
      () => MockClient((request) {
        requests.add(request);
        return respond(request);
      }),
    );
    addTearDown(client.dispose);
    container = ProviderContainer.test(
      overrides: [
        connectionStoreProvider.overrideWithValue(store),
        activeConnectionProfileProvider(store).overrideWithBuild(
          (ref, notifier) => selectedProfile,
        ),
        selectedTeamProvider.overrideWith((ref) => selectedTeam),
        currentUserIdProvider.overrideWith((ref) => userId),
        pendingGitHubConnectionReturnProvider.overrideWithValue(
          PendingGitHubConnectionReturn(result),
        ),
        openciApiServiceProvider.overrideWith((ref) async {
          if (apiReady != null) await apiReady;
          return OpenCIApiService.create(client);
        }),
      ],
    );
    router = GoRouter(
      initialLocation: '/github/connection',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Dashboard')),
        ),
        GoRoute(
          path: '/github/connection',
          builder: (_, _) => const GitHubConnectionPage(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
  }

  void expectRestart() {
    expect(find.text(t.team.gitHubConnectionRestartRequired), findsOneWidget);
    expect(find.text(t.team.gitHubConnectionVerified), findsNothing);
    expect(find.textContaining(reference), findsNothing);
  }

  testWidgets('verifies the session and consumes the saved inputs once', (
    tester,
  ) async {
    final response = Completer<http.Response>();
    respond = (_) => response.future;
    await pumpPage(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(t.team.gitHubConnectionVerified), findsNothing);
    expect(takeGitHubConnectionContext(), isNull);
    expect(
      container.read(pendingGitHubConnectionReturnProvider).take(),
      isNull,
    );

    response.complete(sessionResponse());
    await tester.pumpAndSettle();

    expect(find.text(t.team.gitHubConnectionVerified), findsOneWidget);
    expect(requests.single.url.path, '/teams/team-1/github/session');
    expect(
      requests.single.headers['Authorization'],
      'Bearer firebase-id-token',
    );
    expect(jsonDecode(requests.single.body), {'reference': reference});
    expect(find.textContaining(reference), findsNothing);

    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsOneWidget);
    router.go('/github/connection');
    await tester.pumpAndSettle();
    expectRestart();
    expect(requests, hasLength(1));
  });

  testWidgets('shows cancellation without sending the reference', (
    tester,
  ) async {
    result = parseGitHubConnectionReturn('error=access_denied');
    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.text(t.team.gitHubConnectionCancelled), findsOneWidget);
    expect(requests, isEmpty);
    expect(takeGitHubConnectionContext(), isNull);
  });

  testWidgets('requires restarting without saved initiating context', (
    tester,
  ) async {
    clearGitHubConnectionContext();
    await pumpPage(tester);
    await tester.pumpAndSettle();

    expectRestart();
    expect(requests, isEmpty);
  });

  testWidgets('does not send the reference for a different team', (
    tester,
  ) async {
    selectedTeam = team.copyWith(id: 'team-2');
    await pumpPage(tester);
    await tester.pumpAndSettle();

    expectRestart();
    expect(requests, isEmpty);
  });

  testWidgets('waits for the profile and team to finish loading', (
    tester,
  ) async {
    final profileReady = Completer<ConnectionProfile>();
    final teamReady = Completer<Team>();
    selectedProfile = profileReady.future;
    selectedTeam = teamReady.future;
    await pumpPage(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(requests, isEmpty);
    profileReady.complete(profile);
    await tester.pump();
    expect(requests, isEmpty);

    teamReady.complete(team);
    await tester.pumpAndSettle();
    expect(find.text(t.team.gitHubConnectionVerified), findsOneWidget);
    expect(requests, hasLength(1));
  });

  testWidgets('rechecks the user after waiting for the API client', (
    tester,
  ) async {
    final ready = Completer<void>();
    apiReady = ready.future;
    await pumpPage(tester);

    userId = 'user-2';
    container.invalidate(currentUserIdProvider);
    ready.complete();
    await tester.pumpAndSettle();

    expectRestart();
    expect(requests, isEmpty);
  });

  testWidgets('rejects a response after the server profile changes', (
    tester,
  ) async {
    final response = Completer<http.Response>();
    respond = (_) => response.future;
    await pumpPage(tester);

    selectedProfile = profile.copyWith(apiUrl: 'https://other.example.test');
    container.invalidate(activeConnectionProfileProvider(store));
    response.complete(sessionResponse());
    await tester.pumpAndSettle();

    expectRestart();
    expect(requests, hasLength(1));
  });

  testWidgets('hides the verified state when the user signs out', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.pumpAndSettle();
    expect(find.text(t.team.gitHubConnectionVerified), findsOneWidget);

    userId = null;
    container.invalidate(currentUserIdProvider);
    await tester.pumpAndSettle();

    expectRestart();
    expect(requests, hasLength(1));
  });

  testWidgets('requires restarting if the server rejects the session', (
    tester,
  ) async {
    respond = (_) async => jsonResponse({'error': reference}, status: 403);
    await pumpPage(tester);
    await tester.pumpAndSettle();

    expectRestart();
  });

  testWidgets('shows a fixed message for a server failure', (tester) async {
    respond = (_) async => jsonResponse({'error': reference}, status: 500);
    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.text(t.team.gitHubConnectionCheckFailed), findsOneWidget);
    expect(find.textContaining(reference), findsNothing);
    expect(find.text(t.team.gitHubConnectionVerified), findsNothing);
  });

  testWidgets('stops if the page closes while preparing the API client', (
    tester,
  ) async {
    final ready = Completer<void>();
    apiReady = ready.future;
    await pumpPage(tester);
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();

    ready.complete();
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(requests, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
