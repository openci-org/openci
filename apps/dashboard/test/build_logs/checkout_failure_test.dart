import 'package:dashboard/build_logs/build_jobs_provider.dart';
import 'package:dashboard/cicd_log/detail/build_step_providers.dart';
import 'package:dashboard/cicd_log/detail/ci_cd_log_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const summary =
    'This pull request has merge conflicts with its base branch. '
    'Resolve the conflicts and push the updated branch to run CI.';

Future<void> pumpJob(
  WidgetTester tester,
  BuildJobStatus status, {
  bool previousLogsUnavailable = false,
}) async {
  final job = BuildJob(
    id: 'job',
    status: status,
    owner: 'owner',
    repo: 'repo',
    workflowName: 'CI',
    workflowFileName: 'ci.dart',
    failureSummary: summary,
    latestRunId: previousLogsUnavailable ? 'previous-run' : null,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        buildJobByIdProvider('job').overrideWith((ref) => Stream.value(job)),
        if (previousLogsUnavailable)
          buildStepSummariesProvider(
            buildJobId: 'job',
            runId: 'previous-run',
          ).overrideWith(
            (ref) => throw StateError('Previous logs unavailable'),
          ),
      ],
      child: MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(2),
          ),
          child: child!,
        ),
        home: const CicdLogDetailRoutePage(buildJobId: 'job'),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final size in [const Size(320, 640), const Size(1200, 800)]) {
    testWidgets(
      'shows and copies the checkout failure without a run at $size',
      (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        String? copied;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = (call.arguments as Map)['text'] as String;
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );

        await pumpJob(tester, BuildJobStatus.FAILURE);

        expect(find.text('ビルドの失敗理由'), findsOneWidget);
        expect(find.text(summary), findsOneWidget);
        expect(find.text('ログステップがありません'), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('全体のログをコピー'));
        await tester.pump();
        expect(copied, summary);
      },
    );
  }

  testWidgets(
    'keeps the checkout failure visible if previous logs cannot load',
    (
      tester,
    ) async {
      await pumpJob(
        tester,
        BuildJobStatus.FAILURE,
        previousLogsUnavailable: true,
      );

      expect(find.text(summary), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final status in [
    BuildJobStatus.QUEUED,
    BuildJobStatus.IN_PROGRESS,
    BuildJobStatus.SUCCESS,
    BuildJobStatus.CANCELLED,
  ]) {
    testWidgets('hides the previous failure summary when the job is $status', (
      tester,
    ) async {
      await pumpJob(tester, status);

      expect(find.text(summary), findsNothing);
      expect(find.text('ビルドの失敗理由'), findsNothing);
    });
  }
}
