import 'package:dashboard/app_strings.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/team/invite_team_member_bottom_sheet.dart';
import 'package:dashboard/team/selected_team_provider.dart';
import 'package:dashboard/team/team_members_api.dart';
import 'package:dashboard/team/team_members_bottom_sheet.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Api extends Fake implements TeamMembersApi {
  final removals = <(String, String)>[];
  final additions = <(String, String)>[];
  Object? error;
  @override
  Future<List<Map<String, dynamic>>> members(String teamId) async => [
    {'uid': 'self', 'email': 'self@example.test'},
    if (removals.isEmpty) {'uid': 'deleted-account'},
  ];
  @override
  Future<void> remove(String teamId, String userId) async {
    if (error != null) throw error!;
    removals.add((teamId, userId));
  }

  @override
  Future<void> add(String teamId, String email) async {
    if (error != null) throw error!;
    additions.add((teamId, email));
  }
}

class _SelectedTeamId extends SelectedTeamId {
  @override
  Future<String?> build() async => 'team';
}

void main() {
  late _Api api;
  late Team team;
  setUp(() {
    api = _Api();
    team = Team(
      id: 'team',
      name: 'Test team',
      members: const ['self', 'deleted-account'],
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
  });
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWith((ref) => 'self'),
          selectedTeamIdProvider.overrideWith(_SelectedTeamId.new),
          selectedTeamProvider.overrideWith((ref) async => team),
          teamListProvider.overrideWith((ref) async => [team]),
          teamMembersApiProvider.overrideWith((ref) async => api),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => SingleChildScrollView(child: child),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'only other members have removal controls, and confirmation refreshes the list',
    (tester) async {
      await pump(tester, const TeamMembersBottomSheet());
      expect(find.byIcon(Icons.person_remove_outlined), findsOneWidget);
      expect(find.text('deleted-account'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.person_remove_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.common.cancel));
      await tester.pumpAndSettle();
      expect(api.removals, isEmpty);
      await tester.tap(find.byIcon(Icons.person_remove_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.common.delete));
      await tester.pumpAndSettle();
      expect(api.removals, [('team', 'deleted-account')]);
      expect(find.text('deleted-account'), findsNothing);
      expect(find.text(t.team.removedSuccess), findsOneWidget);
    },
  );

  testWidgets('a failed removal keeps the member visible', (tester) async {
    api.error = StateError('private database details');
    await pump(tester, const TeamMembersBottomSheet());
    await tester.tap(find.byIcon(Icons.person_remove_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.common.delete));
    await tester.pumpAndSettle();
    expect(find.text('deleted-account'), findsOneWidget);
    expect(find.text(t.team.operationFailed), findsOneWidget);
    expect(api.removals, isEmpty);
  });

  testWidgets('invites the selected team member through the callable service', (
    tester,
  ) async {
    await pump(tester, const InviteTeamMemberBottomSheet());
    await tester.tap(find.text('Test team'));
    await tester.enterText(find.byType(TextFormField), ' member@example.test ');
    await tester.tap(find.widgetWithText(TextButton, t.common.invite));
    await tester.pumpAndSettle();
    expect(api.additions, [('team', 'member@example.test')]);
    expect(find.text(t.team.addedSuccess), findsOneWidget);
  });
}
