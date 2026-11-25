import 'package:dashboard/app_strings.dart';
import 'package:dashboard/build_logs/build_jobs_provider.dart';
import 'package:dashboard/cicd_log/detail/ci_cd_log_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Future<GoRouter> pumpRouter(WidgetTester tester, String initialLocation) async {
  final job = BuildJob(
    id: 'job',
    status: BuildJobStatus.SUCCESS,
    owner: 'owner',
    repo: 'repo',
    workflowName: 'CI',
    workflowFileName: 'ci.dart',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Text(state.uri.queryParameters['workflow'] ?? 'All workflows'),
        ),
      ),
      GoRoute(
        path: '/runs/:id',
        builder: (context, state) =>
            CicdLogDetailRoutePage(buildJobId: state.pathParameters['id']!),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    TranslationProvider(
      child: ProviderScope(
        overrides: [
          buildJobByIdProvider('job').overrideWith((ref) => Stream.value(job)),
          buildJobByIdProvider(
            'missing',
          ).overrideWith((ref) => Stream.value(null)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  for (final jobId in ['job', 'missing']) {
    testWidgets('closing a direct link to $jobId shows the dashboard', (
      tester,
    ) async {
      await pumpRouter(tester, '/runs/$jobId');
      expect(find.byType(CicdLogDetailRoutePage), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('All workflows'), findsOneWidget);
    });
  }

  testWidgets('closing a pushed log returns to the original workflow list', (
    tester,
  ) async {
    final router = await pumpRouter(tester, '/?workflow=iOS');
    final closed = router.push<void>('/runs/job');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('iOS'), findsOneWidget);
    await closed;
  });
}
