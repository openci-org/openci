import 'dart:convert';

import 'package:dashboard/api/openci_api_client.dart';
import 'package:dashboard/app_strings.dart';
import 'package:dashboard/auth/auth_page.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/connections/local_development_connection.dart';
import 'package:dashboard/team/selected_team_provider.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/utilities/shared_preferences_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final localMode in [false, true]) {
    testWidgets('shows the active connection indicator: local=$localMode', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final saved = jsonEncode({
        'apiKey': 'saved-key',
        'appId': '1:123:web:saved',
        'projectId': 'saved-production-project',
      });
      SharedPreferences.setMockInitialValues({'sh_firebase_config': saved});
      final prefs = await SharedPreferences.getInstance();
      final local = LocalDevelopmentConnection.parse(
        mode: 'true',
        apiUrl: 'http://127.0.0.1:8080',
        emulatorHost: '127.0.0.1',
        emulatorPort: '9099',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            localDevelopmentConnectionProvider.overrideWithValue(
              localMode ? local : null,
            ),
          ],
          child: const MaterialApp(home: AuthPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Local Auth Emulator · demo-openci'),
        localMode ? findsOneWidget : findsNothing,
      );
      expect(
        find.text('saved-production-project'),
        localMode ? findsNothing : findsOneWidget,
      );
      expect(prefs.getString('sh_firebase_config'), saved);
      expect(tester.takeException(), isNull);
    });
  }

  for (final statusCode in [200, 500]) {
    testWidgets('creates the signup team through the API: $statusCode', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'selected_team_id:cloud': 'previous-team',
      });
      final prefs = await SharedPreferences.getInstance();
      final requests = <http.Request>[];
      final client = http.runWithClient(
        () => createOpenCIChopperClient(
          baseUrl: 'https://api.example.com',
          tokenProvider: () => 'api-client-token',
        ),
        () => MockClient((request) async {
          requests.add(request);
          return http.Response(
            statusCode == 200 ? '{"id":"new-user"}' : 'Team creation failed',
            statusCode,
            headers: {
              'content-type': statusCode == 200
                  ? 'application/json'
                  : 'text/plain',
            },
          );
        }),
      );
      addTearDown(client.dispose);
      final container = ProviderContainer.test(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          firebaseAuthProvider.overrideWith((ref) async => _Auth()),
          openciApiServiceProvider.overrideWith(
            (ref) async => OpenCIApiService.create(client),
          ),
          teamListProvider.overrideWith((ref) async => []),
        ],
      );
      container.listen(selectedTeamIdProvider, (_, _) {});
      await container.read(selectedTeamIdProvider.future);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: AuthPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'user@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'test-password');
      final button = find.widgetWithText(OutlinedButton, t.auth.createAccount);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(requests, hasLength(1));
      final request = requests.single;
      expect(request.method, 'POST');
      expect(request.url.toString(), 'https://api.example.com/teams');
      expect(request.headers['Authorization'], 'Bearer api-client-token');
      expect(jsonDecode(request.body), {'id': 'new-user', 'name': 'new-user'});
      if (statusCode == 200) {
        expect(prefs.getString('selected_team_id:cloud'), 'new-user');
        expect(container.read(selectedTeamIdProvider).value, 'new-user');
        expect(find.byType(SnackBar), findsNothing);
      } else {
        expect(prefs.getString('selected_team_id:cloud'), 'previous-team');
        expect(find.textContaining('Team creation failed'), findsOneWidget);
      }
      expect(tester.widget<OutlinedButton>(button).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    });
  }
}

class _Auth extends Fake implements FirebaseAuth {
  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async => _Credential();
}

class _Credential extends Fake implements UserCredential {
  @override
  User get user => _User();
}

class _User extends Fake implements User {
  @override
  String get uid => 'new-user';

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async =>
      'credential-token';
}
