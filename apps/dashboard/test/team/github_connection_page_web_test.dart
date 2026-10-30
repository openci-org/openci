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
import '../helpers/github_connection_callable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

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
  const authorizationUrl =
      'https://github.example.test/login/oauth/authorize?state=new-state';
  const installationUrl =
      'https://github.example.test:8443/prefix/apps/openci/installations/new';
  late ConnectionStore store;
  late ProviderContainer container;
  late GoRouter router;
  late FutureOr<ConnectionProfile> selectedProfile;
  late FutureOr<Team> selectedTeam;
  late String? userId;
  late GitHubConnectionReturn? result;
  late List<http.Request> requests;
  late Future<http.Response> Function(http.Request) respond;
  late GitHubConnectionApi apiService;
  late int teamListReads;
  late UrlLauncherPlatform originalLauncher;
  late _RecordingUrlLauncher launcher;
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

  http.Response candidatesResponse() => jsonResponse({
    'success': true,
    'installationUrl': installationUrl,
    'candidates': [
      {
        'installationId': 456,
        'accountLogin': 'example-org',
        'accountType': 'Organization',
      },
      {
        'installationId': 789,
        'accountLogin': 'example-user',
        'accountType': 'User',
      },
    ],
  });

  Future<http.Response> successfulResponse(http.Request request) async {
    if ((callableData(request)['action'] == 'session')) {
      return sessionResponse();
    }
    if ((callableData(request)['action'] == 'confirm')) {
      return jsonResponse({'success': true});
    }
    return candidatesResponse();
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = ConnectionStore(await SharedPreferences.getInstance(), profile);
    saveGitHubConnectionContext(initiatingContext);
    selectedProfile = profile;
    selectedTeam = team;
    userId = 'user-1';
    result = parseGitHubConnectionReturn('reference=$reference');
    requests = [];
    respond = successfulResponse;
    apiReady = null;
    teamListReads = 0;
    originalLauncher = UrlLauncherPlatform.instance;
    launcher = _RecordingUrlLauncher();
    UrlLauncherPlatform.instance = launcher;
  });

  tearDown(() {
    clearGitHubConnectionContext();
    UrlLauncherPlatform.instance = originalLauncher;
  });

  GitHubConnectionApi createApi(String baseUrl) => GitHubConnectionApi(
    context: initiatingContext.copyWith(apiUrl: baseUrl),
    callable: TestGitHubCallable((request) {
      requests.add(request);
      return respond(request);
    }),
    isCurrent: () => true,
  );

  Future<void> pumpPage(WidgetTester tester) async {
    apiService = createApi(profile.apiUrl);
    container = ProviderContainer.test(
      overrides: [
        connectionStoreProvider.overrideWithValue(store),
        activeConnectionProfileProvider(store).overrideWithBuild(
          (ref, notifier) => selectedProfile,
        ),
        selectedTeamProvider.overrideWith((ref) => selectedTeam),
        teamListProvider.overrideWith((ref) {
          teamListReads++;
          return [team];
        }),
        currentUserIdProvider.overrideWith((ref) => userId),
        pendingGitHubConnectionReturnProvider.overrideWithValue(
          PendingGitHubConnectionReturn(result),
        ),
        githubConnectionApiProvider.overrideWith((ref) async {
          if (apiReady != null) await apiReady;
          return apiService;
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
    expect(find.text('example-org'), findsNothing);
    expect(find.text('example-user'), findsNothing);
    expect(find.textContaining(reference), findsNothing);
  }

  Future<void> selectOrganization(WidgetTester tester) async {
    await pumpPage(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('example-org'));
    await tester.pump();
  }

  Future<void> pumpEmptyCandidates(
    WidgetTester tester, {
    String? installationUrl,
  }) async {
    respond = (request) async => (callableData(request)['action'] == 'session')
        ? sessionResponse()
        : jsonResponse({
            'success': true,
            'candidates': [],
            'installationUrl': ?installationUrl,
          });
    await pumpPage(tester);
    await tester.pumpAndSettle();
  }

  List<http.Request> confirmationRequests() => requests
      .where((request) => (callableData(request)['action'] == 'confirm'))
      .toList();

  testWidgets('verifies the session before fetching and showing candidates', (
    tester,
  ) async {
    final session = Completer<http.Response>();
    final candidates = Completer<http.Response>();
    respond = (request) => (callableData(request)['action'] == 'session')
        ? session.future
        : candidates.future;
    await pumpPage(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(t.team.gitHubConnectionVerified), findsNothing);
    expect(takeGitHubConnectionContext(), isNull);
    expect(
      container.read(pendingGitHubConnectionReturnProvider).take(),
      isNull,
    );
    expect(callableData(requests.single)['action'], 'session');

    session.complete(sessionResponse());
    await tester.pump();
    expect(requests, hasLength(2));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('example-org'), findsNothing);

    candidates.complete(candidatesResponse());
    await tester.pumpAndSettle();

    expect(find.text(t.team.gitHubConnectionVerified), findsOneWidget);
    expect(find.text('example-org'), findsOneWidget);
    expect(find.text('example-user'), findsOneWidget);
    expect(find.text(t.team.gitHubAppInstallation), findsNothing);
    expect(find.text(t.team.gitHubAppInstallationUrlUnavailable), findsNothing);
    expect(find.byIcon(Icons.business), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
    expect(callableData(requests.last)['action'], 'candidates');
    expect(requests.last.method, 'POST');
    expect(callableData(requests.first), {
      'action': 'session',
      'teamId': 'team-1',
      'reference': reference,
    });
    expect(callableData(requests.last), {
      'action': 'candidates',
      'teamId': 'team-1',
      'reference': reference,
    });
    expect(find.textContaining(reference), findsNothing);

    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsOneWidget);
    router.go('/github/connection');
    await tester.pumpAndSettle();
    expectRestart();
    expect(requests, hasLength(2));
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
    expect(requests, hasLength(2));
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
    expect(requests, hasLength(2));
  });

  testWidgets('requires restarting if the server rejects the session', (
    tester,
  ) async {
    respond = (_) async => jsonResponse({'error': reference}, status: 403);
    await pumpPage(tester);
    await tester.pumpAndSettle();

    expectRestart();
    expect(requests, hasLength(1));
  });

  testWidgets('shows a fixed message for a server failure', (tester) async {
    respond = (_) async => jsonResponse({'error': reference}, status: 500);
    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.text(t.team.gitHubConnectionCheckFailed), findsOneWidget);
    expect(find.textContaining(reference), findsNothing);
    expect(find.text(t.team.gitHubConnectionVerified), findsNothing);
  });

  testWidgets('shows installation guidance when there are no candidates', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 240));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await pumpEmptyCandidates(tester);
    expect(
      find.text(t.team.gitHubConnectionTeam(name: 'Team 1')),
      findsOneWidget,
    );
    expect(find.text(t.team.gitHubConnectionNoCandidates), findsOneWidget);
    expect(
      find.text(t.team.gitHubAppInstallationUrlUnavailable),
      findsOneWidget,
    );
    expect(find.text(t.team.gitHubAppInstallation), findsNothing);

    await tester.scrollUntilVisible(find.byType(OutlinedButton), 100);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.widgetWithText(OutlinedButton, t.team.connectGitHub).hitTestable(),
      findsOneWidget,
    );
    expect(find.byType(ListTile), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    expect(requests, hasLength(2));
  });

  testWidgets(
    'opens the configured App URL and keeps connection retry available',
    (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 240));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await pumpEmptyCandidates(tester, installationUrl: installationUrl);

      expect(
        find.text(t.team.gitHubAppInstallationUrlUnavailable),
        findsNothing,
      );
      final installationLink = find.text(t.team.gitHubAppInstallation);
      await tester.ensureVisible(installationLink);
      await tester.pumpAndSettle();
      await tester.tap(installationLink);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(launcher.url, installationUrl);
      expect(launcher.options!.webOnlyWindowName, '_blank');
      expect(requests, hasLength(2));
      expect(confirmationRequests(), isEmpty);
      expect(takeGitHubConnectionContext(), isNull);

      respond = (_) async => jsonResponse({
        'success': true,
        'authorizationUrl': authorizationUrl,
      });
      await tester.ensureVisible(find.byType(OutlinedButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();

      expect(callableData(requests.last)['action'], 'start');
      expect(launcher.url, authorizationUrl);
      expect(launcher.options!.webOnlyWindowName, '_self');
      expect(takeGitHubConnectionContext(), initiatingContext);
      expect(confirmationRequests(), isEmpty);
    },
  );

  testWidgets(
    'shows configuration guidance instead of opening an invalid URL',
    (
      tester,
    ) async {
      await pumpEmptyCandidates(tester, installationUrl: 'javascript:alert(1)');

      expect(
        find.text(t.team.gitHubAppInstallationUrlUnavailable),
        findsOneWidget,
      );
      expect(find.text(t.team.gitHubAppInstallation), findsNothing);
      expect(find.textContaining('javascript:'), findsNothing);
      expect(
        find.widgetWithText(OutlinedButton, t.team.connectGitHub),
        findsOneWidget,
      );
      expect(launcher.url, isNull);
      expect(requests, hasLength(2));
    },
  );

  testWidgets('shows a message if the App page cannot be opened', (
    tester,
  ) async {
    launcher.launchResult = false;
    await pumpEmptyCandidates(tester, installationUrl: installationUrl);
    await tester.tap(find.text(t.team.gitHubAppInstallation));
    await tester.pumpAndSettle();

    expect(find.text(t.team.gitHubAppInstallationOpenFailed), findsOneWidget);
    expect(find.text(t.team.gitHubConnectionNoCandidates), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNotNull,
    );
    expect(requests, hasLength(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'starts a new connection for the same team after empty candidates',
    (
      tester,
    ) async {
      await pumpEmptyCandidates(tester);
      final authorization = Completer<http.Response>();
      respond = (_) => authorization.future;
      final retry = tester
          .widget<OutlinedButton>(find.byType(OutlinedButton))
          .onPressed!;
      retry();
      retry();
      await tester.pump();

      expect(requests, hasLength(3));
      final request = requests.last;
      expect(request.method, 'POST');
      expect(request.url.path, '/githubConnection');
      expect(request.url.query, isEmpty);
      expect(callableData(request), {'action': 'start', 'teamId': 'team-1'});
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNull,
      );
      expect(launcher.url, isNull);
      expect(takeGitHubConnectionContext(), isNull);

      authorization.complete(
        jsonResponse({
          'success': true,
          'authorizationUrl': authorizationUrl,
        }),
      );
      await tester.pumpAndSettle();

      expect(launcher.url, authorizationUrl);
      expect(takeGitHubConnectionContext(), initiatingContext);
      expect(confirmationRequests(), isEmpty);
      expect(find.textContaining(reference), findsNothing);
    },
  );

  testWidgets('allows another retry if starting a new connection fails', (
    tester,
  ) async {
    await pumpEmptyCandidates(tester);
    respond = (_) async => jsonResponse({'error': reference}, status: 502);
    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();

    expect(find.text(t.team.gitHubConnectionFailed), findsOneWidget);
    expect(find.textContaining(reference), findsNothing);
    expect(launcher.url, isNull);
    expect(takeGitHubConnectionContext(), isNull);

    respond = (_) async => jsonResponse({
      'success': true,
      'authorizationUrl': authorizationUrl,
    });
    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();

    expect(requests, hasLength(4));
    expect(launcher.url, authorizationUrl);
    expect(takeGitHubConnectionContext(), initiatingContext);
    expect(confirmationRequests(), isEmpty);
  });

  testWidgets('removes the empty-candidate retry if the team changes', (
    tester,
  ) async {
    await pumpEmptyCandidates(tester);
    selectedTeam = team.copyWith(id: 'team-2');
    container.invalidate(selectedTeamProvider);
    await tester.pumpAndSettle();

    expectRestart();
    expect(find.byType(OutlinedButton), findsNothing);
    expect(requests, hasLength(2));
    expect(launcher.url, isNull);
  });

  testWidgets('rejects candidates after the selected team changes', (
    tester,
  ) async {
    final candidates = Completer<http.Response>();
    respond = (request) async => (callableData(request)['action'] == 'session')
        ? sessionResponse()
        : candidates.future;
    await pumpPage(tester);
    expect(requests, hasLength(2));

    selectedTeam = team.copyWith(id: 'team-2');
    container.invalidate(selectedTeamProvider);
    candidates.complete(candidatesResponse());
    await tester.pumpAndSettle();

    expectRestart();
    expect(requests, hasLength(2));
  });

  testWidgets(
    'requires restarting if the session expires while fetching candidates',
    (
      tester,
    ) async {
      respond = (request) async =>
          (callableData(request)['action'] == 'session')
          ? sessionResponse()
          : jsonResponse({'error': reference}, status: 403);
      await pumpPage(tester);
      await tester.pumpAndSettle();

      expectRestart();
      expect(requests, hasLength(2));
    },
  );

  testWidgets('requires restarting when GitHub reauthorization is needed', (
    tester,
  ) async {
    respond = (request) async => (callableData(request)['action'] == 'session')
        ? sessionResponse()
        : jsonResponse({
            'code': 'github_reauthorization_required',
          }, status: 409);
    await pumpPage(tester);
    await tester.pumpAndSettle();

    expectRestart();
    expect(requests, hasLength(2));
  });

  testWidgets('does not expose candidate API failure details', (tester) async {
    respond = (request) async => (callableData(request)['action'] == 'session')
        ? sessionResponse()
        : jsonResponse({'error': reference}, status: 502);
    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.text(t.team.gitHubConnectionCheckFailed), findsOneWidget);
    expect(find.textContaining(reference), findsNothing);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets(
    'does not treat an unsuccessful response as an empty candidate list',
    (
      tester,
    ) async {
      respond = (request) async =>
          (callableData(request)['action'] == 'session')
          ? sessionResponse()
          : jsonResponse({'success': false, 'candidates': []});
      await pumpPage(tester);
      await tester.pumpAndSettle();

      expect(find.text(t.team.gitHubConnectionCheckFailed), findsOneWidget);
      expect(find.text(t.team.gitHubConnectionNoCandidates), findsNothing);
    },
  );

  testWidgets(
    'handles malformed candidates without displaying the raw response',
    (
      tester,
    ) async {
      respond = (request) async =>
          (callableData(request)['action'] == 'session')
          ? sessionResponse()
          : jsonResponse({'success': true, 'candidates': reference});
      await pumpPage(tester);
      await tester.pumpAndSettle();

      expect(find.text(t.team.gitHubConnectionCheckFailed), findsOneWidget);
      expect(find.textContaining(reference), findsNothing);
      expect(find.byType(ListTile), findsNothing);
    },
  );

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

  testWidgets(
    'confirms only the selected account and refreshes teams on success',
    (
      tester,
    ) async {
      final confirmed = Completer<http.Response>();
      respond = (request) => (callableData(request)['action'] == 'confirm')
          ? confirmed.future
          : successfulResponse(request);
      await pumpPage(tester);
      await tester.pumpAndSettle();
      final teams = container.listen(teamListProvider, (_, _) {});
      addTearDown(teams.close);
      await container.read(teamListProvider.future);

      expect(
        find.text(t.team.gitHubConnectionTeam(name: 'Team 1')),
        findsOneWidget,
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(confirmationRequests(), isEmpty);

      await tester.tap(find.text('example-user'));
      await tester.pump();
      await tester.tap(find.text('example-org'));
      await tester.pump();
      final confirm = tester
          .widget<FilledButton>(find.byType(FilledButton))
          .onPressed!;
      confirm();
      confirm();
      await tester.pump();

      final request = confirmationRequests().single;
      expect(request.url.path, '/githubConnection');
      expect(request.method, 'POST');
      expect(callableData(request), {
        'action': 'confirm',
        'teamId': 'team-1',
        'reference': reference,
        'installationId': 456,
      });
      expect(find.text(t.team.gitHubConnectionConfirming), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(
        tester
            .widget<RadioListTile<int>>(
              find.widgetWithText(RadioListTile<int>, 'example-user'),
            )
            .enabled,
        isFalse,
      );
      expect(find.text(t.team.gitHubConnectionCompleted), findsNothing);
      expect(teamListReads, 1);

      confirmed.complete(jsonResponse({'success': true}));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text(t.team.gitHubConnectionCompleted), findsOneWidget);
      expect(teamListReads, 2);
      expect(confirmationRequests(), hasLength(1));
    },
  );

  testWidgets('allows confirmation retry after an API failure', (tester) async {
    respond = (request) async => (callableData(request)['action'] == 'confirm')
        ? jsonResponse({'error': reference}, status: 502)
        : successfulResponse(request);
    await selectOrganization(tester);
    final teams = container.listen(teamListProvider, (_, _) {});
    addTearDown(teams.close);
    await container.read(teamListProvider.future);
    await tester.tap(find.text(t.team.gitHubConnectionConfirm));
    await tester.pumpAndSettle();

    expect(find.text(t.team.gitHubConnectionConfirmFailed), findsOneWidget);
    expect(find.textContaining(reference), findsNothing);
    expect(find.text(t.team.gitHubConnectionCompleted), findsNothing);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
    expect(teamListReads, 1);

    respond = successfulResponse;
    await tester.tap(find.text(t.team.gitHubConnectionConfirm));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text(t.team.gitHubConnectionCompleted), findsOneWidget);
    expect(teamListReads, 2);
    expect(confirmationRequests(), hasLength(2));
  });

  testWidgets(
    'requires restarting when confirmation rejects an expired session',
    (
      tester,
    ) async {
      respond = (request) async =>
          (callableData(request)['action'] == 'confirm')
          ? jsonResponse({'error': reference}, status: 403)
          : successfulResponse(request);
      await selectOrganization(tester);
      await tester.tap(find.text(t.team.gitHubConnectionConfirm));
      await tester.pumpAndSettle();

      expect(find.text(t.team.gitHubConnectionRestartRequired), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(find.text(t.team.gitHubConnectionCompleted), findsNothing);
      expect(find.textContaining(reference), findsNothing);
    },
  );

  testWidgets('requires restarting when the connection conflicts', (
    tester,
  ) async {
    respond = (request) async => (callableData(request)['action'] == 'confirm')
        ? jsonResponse({'code': 'github_connection_conflict'}, status: 409)
        : successfulResponse(request);
    await selectOrganization(tester);
    await tester.tap(find.text(t.team.gitHubConnectionConfirm));
    await tester.pumpAndSettle();

    expect(find.text(t.team.gitHubConnectionRestartRequired), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(find.text(t.team.gitHubConnectionCompleted), findsNothing);
  });

  testWidgets(
    'does not report success when confirmation returns success false',
    (
      tester,
    ) async {
      respond = (request) async =>
          (callableData(request)['action'] == 'confirm')
          ? jsonResponse({'success': false})
          : successfulResponse(request);
      await selectOrganization(tester);
      await tester.tap(find.text(t.team.gitHubConnectionConfirm));
      await tester.pumpAndSettle();

      expect(find.text(t.team.gitHubConnectionConfirmFailed), findsOneWidget);
      expect(find.text(t.team.gitHubConnectionCompleted), findsNothing);
      expect(find.text('Dashboard'), findsNothing);
    },
  );

  testWidgets('sanitizes malformed confirmation responses', (tester) async {
    respond = (request) async => (callableData(request)['action'] == 'confirm')
        ? jsonResponse({'success': reference})
        : successfulResponse(request);
    await selectOrganization(tester);
    await tester.tap(find.text(t.team.gitHubConnectionConfirm));
    await tester.pumpAndSettle();

    expect(find.text(t.team.gitHubConnectionConfirmFailed), findsOneWidget);
    expect(find.textContaining(reference), findsNothing);
    expect(find.text(t.team.gitHubConnectionCompleted), findsNothing);
  });

  testWidgets('does not send confirmation to a different API server', (
    tester,
  ) async {
    await selectOrganization(tester);
    apiService = createApi('https://other.example.test');
    container.invalidate(githubConnectionApiProvider);
    await tester.tap(find.text(t.team.gitHubConnectionConfirm));
    await tester.pumpAndSettle();

    expect(find.text(t.team.gitHubConnectionRestartRequired), findsOneWidget);
    expect(confirmationRequests(), isEmpty);
  });

  testWidgets('rechecks the user before sending confirmation', (tester) async {
    await selectOrganization(tester);
    final ready = Completer<void>();
    apiReady = ready.future;
    container.invalidate(githubConnectionApiProvider);
    await tester.tap(find.text(t.team.gitHubConnectionConfirm));
    await tester.pump();

    userId = 'user-2';
    container.invalidate(currentUserIdProvider);
    ready.complete();
    await tester.pumpAndSettle();

    expectRestart();
    expect(confirmationRequests(), isEmpty);
    expect(find.text(t.team.gitHubConnectionCompleted), findsNothing);
  });

  testWidgets('does not apply confirmation success after the team changes', (
    tester,
  ) async {
    final confirmed = Completer<http.Response>();
    respond = (request) => (callableData(request)['action'] == 'confirm')
        ? confirmed.future
        : successfulResponse(request);
    await selectOrganization(tester);
    final teams = container.listen(teamListProvider, (_, _) {});
    addTearDown(teams.close);
    await container.read(teamListProvider.future);
    await tester.tap(find.text(t.team.gitHubConnectionConfirm));
    await tester.pump();
    expect(confirmationRequests(), hasLength(1));

    selectedTeam = team.copyWith(id: 'team-2');
    container.invalidate(selectedTeamProvider);
    confirmed.complete(jsonResponse({'success': true}));
    await tester.pumpAndSettle();

    expectRestart();
    expect(find.text(t.team.gitHubConnectionCompleted), findsNothing);
    expect(find.text('Dashboard'), findsNothing);
    expect(teamListReads, 1);
  });

  testWidgets('does not show a completion message after the page closes', (
    tester,
  ) async {
    final confirmed = Completer<http.Response>();
    respond = (request) => (callableData(request)['action'] == 'confirm')
        ? confirmed.future
        : successfulResponse(request);
    await selectOrganization(tester);
    await tester.tap(find.text(t.team.gitHubConnectionConfirm));
    await tester.pump();
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();

    confirmed.complete(jsonResponse({'success': true}));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text(t.team.gitHubConnectionCompleted), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _RecordingUrlLauncher extends UrlLauncherPlatform {
  String? url;
  LaunchOptions? options;
  bool launchResult = true;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    this.url = url;
    this.options = options;
    return launchResult;
  }
}
