import 'dart:async';

import 'package:dashboard/app_strings.dart';
import 'package:dashboard/billing/billing_api.dart';
import 'package:dashboard/billing/billing_error_message.dart';
import 'package:dashboard/billing/billing_response.dart';
import 'package:dashboard/team/delete_team_bottom_sheet.dart';
import 'package:dashboard/team/selected_team_provider.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import '../helpers/billing_callable.dart';

class _Selection extends SelectedTeamId {
  final saved = <String>[];
  @override
  Future<String?> build() async => 'team';
  @override
  Future<void> saveSelectedTeamId(String teamId) async {
    saved.add(teamId);
  }
}

void main() {
  for (final succeeds in [false, true]) {
    testWidgets(
      succeeds
          ? 'switches teams after confirmed deletion'
          : 'keeps the selected team when an active subscription blocks deletion',
      (tester) async {
        final completed = Completer<void>();
        final requests = <http.Request>[];
        final callable = TestBillingCallable((request) async {
          requests.add(request);
          await completed.future;
          return http.Response('{"success":true}', 200);
        });
        final selection = _Selection();
        final team = Team(
          id: 'team',
          name: 'Delete this team',
          members: const ['user'],
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        );
        final container = ProviderContainer(
          overrides: [
            billingApiProvider.overrideWith(
              (ref) async =>
                  BillingApi(callable: callable, isCurrent: () => ref.mounted),
            ),
            selectedTeamIdProvider.overrideWith(() => selection),
            teamListProvider.overrideWith(
              (ref) async => [
                team,
                team.copyWith(id: 'other', name: 'Other team'),
              ],
            ),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const SingleChildScrollView(
                        child: DeleteTeamBottomSheet(),
                      ),
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(team.name));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.common.delete));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(billingCallData(requests.single), {
          'action': 'deleteTeam',
          'teamId': 'team',
        });
        expect(selection.saved, isEmpty);
        if (succeeds) {
          completed.complete();
        } else {
          completed.completeError(
            const BillingException('subscription_exists'),
          );
        }
        await tester.pumpAndSettle();
        expect(selection.saved, succeeds ? ['other'] : isEmpty);
        expect(
          find.byType(DeleteTeamBottomSheet),
          succeeds ? findsNothing : findsOneWidget,
        );
        if (!succeeds) {
          expect(
            find.text(
              billingErrorMessage(
                const BillingException('subscription_exists'),
              ),
            ),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
}
