import 'dart:async';
import 'dart:convert';

import 'package:dashboard/api/openci_api_client.dart';
import 'package:dashboard/app_strings.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/connections/active_connection_profile_provider.dart';
import 'package:dashboard/connections/connection_profile.dart';
import 'package:dashboard/connections/connection_store.dart';
import 'package:dashboard/connections/connection_store_provider.dart';
import 'package:dashboard/team/github_connection_storage.dart';
import 'package:dashboard/team/switch_team_bottom_sheet.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

void main() {
  final team = Team(
    id: 'selected-team',
    name: 'Selected team',
    members: const ['user-123'],
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
  const authorizationUrl =
      'https://github.com/login/oauth/authorize?state=test-state';
  final successResponse = http.Response(
    jsonEncode({'success': true, 'authorizationUrl': authorizationUrl}),
    200,
    headers: {'content-type': 'application/json'},
  );
  late UrlLauncherPlatform originalLauncher;
  late _RecordingUrlLauncher launcher;
  late List<http.Request> requests;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    originalLauncher = UrlLauncherPlatform.instance;
    launcher = _RecordingUrlLauncher();
    UrlLauncherPlatform.instance = launcher;
    requests = [];
  });
  tearDown(() {
    UrlLauncherPlatform.instance = originalLauncher;
    if (kIsWeb) clearGitHubConnectionContext();
  });

  Future<void> pumpSheet(
    WidgetTester tester,
    Future<http.Response> Function(http.Request) respond,
  ) async {
    const profile = ConnectionProfile(
      id: 'cloud',
      name: 'Cloud',
      apiUrl: 'https://api.openci.test',
      firebase: {},
    );
    final store = ConnectionStore(
      await SharedPreferences.getInstance(),
      profile,
    );
    final client = http.runWithClient(
      () => createOpenCIChopperClient(
        baseUrl: 'https://api.openci.test',
        tokenProvider: () => 'firebase-id-token',
      ),
      () => MockClient((request) async {
        requests.add(request);
        return respond(request);
      }),
    );
    addTearDown(client.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectionStoreProvider.overrideWithValue(store),
          activeConnectionProfileProvider(store).overrideWithBuild(
            (ref, notifier) => profile,
          ),
          currentUserIdProvider.overrideWithValue('user-123'),
          teamListProvider.overrideWith(
            (ref) async => [
              team.copyWith(id: 'other-team', name: 'Other team'),
              team,
            ],
          ),
          selectedTeamProvider.overrideWith((ref) async => team),
          openciApiServiceProvider.overrideWith(
            (ref) async => OpenCIApiService.create(client),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SwitchTeamBottomSheet(
              onMembers: () {},
              onInvite: () {},
              onCreate: () {},
              onEdit: () {},
              onDelete: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the GitHub connection button only on web', (tester) async {
    await pumpSheet(tester, (_) async => successResponse);

    expect(
      find.text(t.team.connectGitHub),
      kIsWeb ? findsOneWidget : findsNothing,
    );
    expect(find.text('Selected team'), findsOneWidget);
    expect(find.text(t.team.members), findsOneWidget);
    expect(requests, isEmpty);
  });

  testWidgets('starts the selected team connection and opens its URL', (
    tester,
  ) async {
    await pumpSheet(tester, (_) async => successResponse);

    await tester.tap(find.text(t.team.connectGitHub));
    await tester.pumpAndSettle();

    expect(requests, hasLength(1));
    expect(requests.single.method, 'POST');
    expect(
      requests.single.url.path,
      '/teams/selected-team/github/connect',
    );
    expect(
      requests.single.headers['Authorization'],
      'Bearer firebase-id-token',
    );
    expect(launcher.url, authorizationUrl);
    expect(launcher.options?.mode, PreferredLaunchMode.externalApplication);
    expect(launcher.options?.webOnlyWindowName, '_self');
  }, skip: !kIsWeb);

  testWidgets('shows an API failure and allows retrying', (tester) async {
    var response = http.Response('{"success":false}', 403);
    await pumpSheet(tester, (_) async => response);

    await tester.tap(find.text(t.team.connectGitHub));
    await tester.pumpAndSettle();

    expect(find.text(t.team.gitHubConnectionFailed), findsOneWidget);
    expect(launcher.url, isNull);

    response = successResponse;
    await tester.tap(find.text(t.team.connectGitHub));
    await tester.pumpAndSettle();

    expect(requests, hasLength(2));
    expect(launcher.url, authorizationUrl);
  }, skip: !kIsWeb);

  testWidgets('prevents duplicate requests and navigation after dismissal', (
    tester,
  ) async {
    final response = Completer<http.Response>();
    await pumpSheet(tester, (_) => response.future);
    final onPressed = tester
        .widget<OutlinedButton>(find.byType(OutlinedButton))
        .onPressed!;

    onPressed();
    onPressed();
    await tester.pump();

    expect(requests, hasLength(1));
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    response.complete(successResponse);
    await tester.pumpAndSettle();

    expect(launcher.url, isNull);
    expect(tester.takeException(), isNull);
  }, skip: !kIsWeb);
}

class _RecordingUrlLauncher extends UrlLauncherPlatform {
  String? url;
  LaunchOptions? options;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    this.url = url;
    this.options = options;
    return true;
  }
}
