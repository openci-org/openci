@TestOn('browser')
library;

import 'dart:async';
import 'dart:convert';

import 'package:dashboard/team/github_connection_api.dart';
import 'package:dashboard/app_strings.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/connections/active_connection_profile_provider.dart';
import 'package:dashboard/connections/connection_profile.dart';
import 'package:dashboard/connections/connection_store.dart';
import 'package:dashboard/connections/connection_store_provider.dart';
import 'package:dashboard/team/connect_github_button.dart';
import 'package:dashboard/team/github_connection_context.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import '../helpers/github_connection_callable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:web/web.dart' as web;

const _storageKey = 'github_connection_context_v1';

void main() {
  const profile = ConnectionProfile(
    id: 'self-hosted',
    name: 'Self hosted',
    apiUrl: 'https://ci.example.test',
    firebase: {},
  );
  const authorizationUrl =
      'https://github.example.test/login/oauth/authorize?state=test-state';
  final successResponse = http.Response(
    jsonEncode({'success': true, 'authorizationUrl': authorizationUrl}),
    200,
    headers: {'content-type': 'application/json'},
  );
  late ConnectionStore store;
  late ProviderContainer container;
  late FutureOr<ConnectionProfile> selectedProfile;
  late Team selectedTeam;
  late String? userId;
  late Future<http.Response> Function(http.Request) respond;
  late List<http.Request> requests;
  late UrlLauncherPlatform originalLauncher;
  late _RecordingUrlLauncher launcher;
  Future<void>? apiReady;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = ConnectionStore(await SharedPreferences.getInstance(), profile);
    selectedProfile = profile;
    selectedTeam = Team(
      id: 'team-1',
      name: 'Team 1',
      members: const ['user-1'],
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    userId = 'user-1';
    respond = (_) async => successResponse;
    requests = [];
    apiReady = null;
    originalLauncher = UrlLauncherPlatform.instance;
    launcher = _RecordingUrlLauncher();
    UrlLauncherPlatform.instance = launcher;
  });

  tearDown(() {
    UrlLauncherPlatform.instance = originalLauncher;
    web.window.sessionStorage.removeItem(_storageKey);
  });

  Future<void> pumpButton(WidgetTester tester) async {
    final api = GitHubConnectionApi(
      context: GitHubConnectionContext(
        profileId: profile.id,
        apiUrl: profile.apiUrl,
        userId: 'user-1',
        teamId: 'team-1',
      ),
      callable: TestGitHubCallable((request) {
        requests.add(request);
        return respond(request);
      }),
      isCurrent: () => true,
    );
    container = ProviderContainer.test(
      overrides: [
        connectionStoreProvider.overrideWithValue(store),
        activeConnectionProfileProvider(store).overrideWithBuild(
          (ref, notifier) => selectedProfile,
        ),
        selectedTeamProvider.overrideWith((ref) => selectedTeam),
        currentUserIdProvider.overrideWith((ref) => userId),
        githubConnectionApiProvider.overrideWith((ref) async {
          if (apiReady != null) await apiReady;
          return api;
        }),
      ],
    );
    await container.read(activeConnectionProfileProvider(store).future);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: ConnectGitHubButton()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<Completer<http.Response>> startPendingConnection(
    WidgetTester tester,
  ) async {
    final response = Completer<http.Response>();
    respond = (_) => response.future;
    await pumpButton(tester);
    await tester.tap(find.text(t.team.connectGitHub));
    await tester.pump();
    expect(requests, hasLength(1));
    expect(web.window.sessionStorage.getItem(_storageKey), isNull);
    return response;
  }

  void expectConnectionCancelled() {
    expect(launcher.url, isNull);
    expect(web.window.sessionStorage.getItem(_storageKey), isNull);
    expect(find.text(t.team.gitHubConnectionFailed), findsOneWidget);
  }

  testWidgets('saves the initiating context before opening GitHub', (
    tester,
  ) async {
    await pumpButton(tester);

    await tester.tap(find.text(t.team.connectGitHub));
    await tester.pumpAndSettle();

    expect(callableData(requests.single), {
      'action': 'start',
      'teamId': 'team-1',
    });
    expect(launcher.url, authorizationUrl);
    expect(jsonDecode(launcher.savedContext!), {
      'profileId': profile.id,
      'apiUrl': profile.apiUrl,
      'userId': 'user-1',
      'teamId': 'team-1',
    });
    expect(
      web.window.sessionStorage.getItem(_storageKey),
      launcher.savedContext,
    );
  });

  testWidgets('clears old context on an API failure and allows retry', (
    tester,
  ) async {
    web.window.sessionStorage.setItem(_storageKey, 'previous-attempt');
    respond = (_) async => http.Response('{"success":false}', 403);
    await pumpButton(tester);

    await tester.tap(find.text(t.team.connectGitHub));
    await tester.pumpAndSettle();
    expectConnectionCancelled();

    respond = (_) async => successResponse;
    await tester.tap(find.text(t.team.connectGitHub));
    await tester.pumpAndSettle();
    expect(launcher.savedContext, isNotNull);
  });

  testWidgets('clears the saved context if opening GitHub fails', (
    tester,
  ) async {
    launcher.succeeds = false;
    await pumpButton(tester);

    await tester.tap(find.text(t.team.connectGitHub));
    await tester.pumpAndSettle();

    expect(launcher.savedContext, isNotNull);
    expect(web.window.sessionStorage.getItem(_storageKey), isNull);
    expect(find.text(t.team.gitHubConnectionFailed), findsOneWidget);
  });

  testWidgets('cancels if the selected team changes during the request', (
    tester,
  ) async {
    final response = await startPendingConnection(tester);
    selectedTeam = selectedTeam.copyWith(id: 'team-2');
    container.invalidate(selectedTeamProvider);

    response.complete(successResponse);
    await tester.pumpAndSettle();

    expectConnectionCancelled();
  });

  testWidgets('cancels if the user changes during the request', (tester) async {
    final response = await startPendingConnection(tester);
    userId = 'user-2';
    container.invalidate(currentUserIdProvider);

    response.complete(successResponse);
    await tester.pumpAndSettle();

    expectConnectionCancelled();
  });

  testWidgets('cancels if the profile changes during the request', (
    tester,
  ) async {
    final response = await startPendingConnection(tester);
    selectedProfile = profile.copyWith(id: 'another-profile');
    container.invalidate(activeConnectionProfileProvider(store));

    response.complete(successResponse);
    await tester.pumpAndSettle();

    expectConnectionCancelled();
  });

  testWidgets('cancels if the same profile changes its API URL', (
    tester,
  ) async {
    final response = await startPendingConnection(tester);
    selectedProfile = profile.copyWith(apiUrl: 'https://other.example.test');
    container.invalidate(activeConnectionProfileProvider(store));

    response.complete(successResponse);
    await tester.pumpAndSettle();

    expectConnectionCancelled();
  });

  testWidgets('does not use the previous profile while switching', (
    tester,
  ) async {
    final response = await startPendingConnection(tester);
    final nextProfile = Completer<ConnectionProfile>();
    selectedProfile = nextProfile.future;
    container.invalidate(activeConnectionProfileProvider(store));

    response.complete(successResponse);
    await tester.pumpAndSettle();

    expectConnectionCancelled();
    nextProfile.complete(profile);
    await tester.pumpAndSettle();
  });

  testWidgets('checks the context again before sending the API request', (
    tester,
  ) async {
    final ready = Completer<void>();
    apiReady = ready.future;
    await pumpButton(tester);
    await tester.tap(find.text(t.team.connectGitHub));
    await tester.pump();
    userId = null;
    container.invalidate(currentUserIdProvider);

    ready.complete();
    await tester.pumpAndSettle();

    expect(requests, isEmpty);
    expectConnectionCancelled();
  });

  testWidgets('does not save or navigate after the button is dismissed', (
    tester,
  ) async {
    final response = await startPendingConnection(tester);
    await tester.pumpWidget(const SizedBox.shrink());

    response.complete(successResponse);
    await tester.pumpAndSettle();

    expect(launcher.url, isNull);
    expect(web.window.sessionStorage.getItem(_storageKey), isNull);
    expect(tester.takeException(), isNull);
  });
}

class _RecordingUrlLauncher extends UrlLauncherPlatform {
  String? url;
  String? savedContext;
  bool succeeds = true;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    this.url = url;
    savedContext = web.window.sessionStorage.getItem(_storageKey);
    return succeeds;
  }
}
