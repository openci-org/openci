import 'dart:convert';

import 'package:dashboard/api/openci_api_client.dart';
import 'package:dashboard/app_strings.dart';
import 'package:dashboard/team/edit_team_bottom_sheet.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_shared/openci_shared.dart';

void main() {
  testWidgets(
    'saves the selected team name without sending GitHub connection fields',
    (tester) async {
      final team = Team(
        id: 'team-123',
        name: 'Original team',
        members: const ['user-123'],
        installationIds: const [123, 456],
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      final requests = <http.Request>[];
      final client = http.runWithClient(
        () => createOpenCIChopperClient(
          baseUrl: 'https://api.example.com',
          tokenProvider: () => 'api-client-token',
        ),
        () => MockClient((request) async {
          requests.add(request);
          return http.Response(
            '{"success":true}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teamListProvider.overrideWith(
              (ref) async => [
                team.copyWith(id: 'other-team', name: 'Other team'),
                team,
              ],
            ),
            openciApiServiceProvider.overrideWith(
              (ref) async => OpenCIApiService.create(client),
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    await showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => const EditTeamBottomSheet(),
                    );
                  },
                  child: const Text('Open team editor'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open team editor'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(team.name));
      await tester.pumpAndSettle();

      final nameField = find.byType(TextFormField);
      expect(nameField, findsOneWidget);
      expect(
        tester.widget<TextFormField>(nameField).controller!.text,
        team.name,
      );
      await tester.enterText(nameField, 'Renamed team');
      await tester.tap(find.widgetWithText(TextButton, t.team.editTeam));
      await tester.pumpAndSettle();

      expect(requests, hasLength(1));
      final request = requests.single;
      expect(request.method, 'PATCH');
      expect(
        request.url.toString(),
        'https://api.example.com/teams/team-123',
      );
      expect(jsonDecode(request.body), {'name': 'Renamed team'});
      expect(find.byType(EditTeamBottomSheet), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
