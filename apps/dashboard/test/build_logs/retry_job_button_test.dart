import 'dart:async';

import 'package:dashboard/app_strings.dart';
import 'package:dashboard/build_logs/build_jobs_provider.dart';
import 'package:dashboard/build_logs/build_repository.dart';
import 'package:dashboard/cicd_log/detail/build_step_providers.dart';
import 'package:dashboard/cicd_log/detail/ci_cd_log_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository implements BuildRepository {
  final requests = <({String id, int expectedRetryCount})>[];
  Future<void> Function() respond = () async {};

  @override
  Future<void> retryJob({
    required String id,
    required int expectedRetryCount,
  }) {
    requests.add((id: id, expectedRetryCount: expectedRetryCount));
    return respond();
  }

  @override
  Stream<BuildJob?> watchJob(String id) => throw UnimplementedError();

  @override
  Stream<List<BuildJob>> watchJobs(String teamId) => throw UnimplementedError();
}

void main() {
  late _Repository repository;
  late BuildJob job;
  late StreamController<BuildJob?> updates;
  late ProviderContainer container;
  late int subscriptions;

  setUp(() {
    LocaleSettings.setLocaleSync(AppLocale.en);
    repository = _Repository();
    job = BuildJob(
      id: 'job',
      teamId: 'team',
      owner: 'openci-org',
      repo: 'openci',
      workflowName: 'CI',
      workflowFileName: 'ci.dart',
      status: BuildJobStatus.FAILURE,
      runsOn: 'macos-latest',
      retryCount: 3,
      latestRunId: 'previous-run',
      failureSummary: 'Previous failure',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    subscriptions = 0;
    updates = StreamController<BuildJob?>.broadcast();
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        buildRepositoryProvider.overrideWith((ref) => repository),
        buildJobByIdProvider('job').overrideWith((ref) async* {
          subscriptions++;
          yield job;
          yield* updates.stream;
        }),
        for (final runId in ['previous-run', 'new-run'])
          buildStepSummariesProvider(
            buildJobId: 'job',
            runId: runId,
          ).overrideWith(
            (ref) async => [
              BuildStep(
                id: 'test',
                runId: runId,
                name: '$runId step',
                status: BuildJobStatus.SUCCESS,
                durationMs: 1000,
                stepOrder: 0,
                createdAt: DateTime.utc(2026),
                updatedAt: DateTime.utc(2026),
              ),
            ],
          ),
      ],
    );
    addTearDown(() {
      container.dispose();
      unawaited(updates.close());
    });
    addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));
  });

  Future<void> show(WidgetTester tester) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: CicdLogDetailRoutePage(buildJobId: 'job'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> emit(WidgetTester tester, BuildJob next) async {
    job = next;
    updates.add(next);
    await tester.pumpAndSettle();
  }

  Finder retryButton() => find.widgetWithText(TextButton, t.logs.retryJob);

  testWidgets('offers retries only for supported terminal jobs', (
    tester,
  ) async {
    await show(tester);
    for (final status in [
      BuildJobStatus.SUCCESS,
      BuildJobStatus.FAILURE,
      BuildJobStatus.CANCELLED,
      BuildJobStatus.TIMED_OUT,
    ]) {
      await emit(tester, job.copyWith(status: status));
      expect(retryButton(), findsOneWidget, reason: status.name);
    }
    await emit(
      tester,
      job.copyWith(status: BuildJobStatus.FAILURE, runsOn: 'linux-latest'),
    );
    expect(retryButton(), findsOneWidget);
    for (final status in [
      BuildJobStatus.WAITING,
      BuildJobStatus.QUEUED,
      BuildJobStatus.IN_PROGRESS,
      BuildJobStatus.SKIPPED,
    ]) {
      await emit(tester, job.copyWith(status: status));
      expect(retryButton(), findsNothing, reason: status.name);
    }
    await emit(
      tester,
      job.copyWith(status: BuildJobStatus.FAILURE, runsOn: 'ubuntu-latest'),
    );
    expect(retryButton(), findsNothing);
    await emit(tester, job.copyWith(runsOn: null));
    expect(retryButton(), findsNothing);
    await emit(tester, job.copyWith(runsOn: 'macos-latest', teamId: null));
    expect(retryButton(), findsNothing);
    expect(repository.requests, isEmpty);
  });

  testWidgets('sends once and follows the retry into its new logs', (
    tester,
  ) async {
    final pending = Completer<void>();
    repository.respond = () => pending.future;
    await show(tester);
    final submit = tester.widget<TextButton>(retryButton()).onPressed!;
    submit();
    submit();
    await tester.pump();
    expect(repository.requests, [(id: 'job', expectedRetryCount: 3)]);
    expect(
      tester
          .widget<TextButton>(
            find.widgetWithText(TextButton, t.logs.retrySubmitting),
          )
          .onPressed,
      isNull,
    );

    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text(t.logs.retryQueued), findsOneWidget);
    expect(subscriptions, greaterThan(1));
    // A stale terminal snapshot must not re-enable an accepted request.
    expect(
      tester
          .widget<TextButton>(
            find.widgetWithText(TextButton, t.logs.retryRequested),
          )
          .onPressed,
      isNull,
    );
    expect(find.text('previous-run step'), findsOneWidget);

    await emit(
      tester,
      job.copyWith(status: BuildJobStatus.QUEUED, retryCount: 4),
    );
    expect(find.text(t.logs.retryWaitingPreviousLogs), findsOneWidget);
    expect(find.text('previous-run step'), findsOneWidget);
    expect(find.text('Previous failure'), findsNothing);
    expect(retryButton(), findsNothing);

    await emit(
      tester,
      job.copyWith(status: BuildJobStatus.IN_PROGRESS, latestRunId: 'new-run'),
    );
    expect(find.text('new-run step'), findsOneWidget);
    expect(find.text('previous-run step'), findsNothing);
    expect(find.text(t.logs.retryWaitingPreviousLogs), findsNothing);
    expect(repository.requests, hasLength(1));
  });

  testWidgets('reconciles errors and requires another click to retry', (
    tester,
  ) async {
    final pending = Completer<void>();
    repository.respond = () => pending.future;
    await show(tester);
    await tester.tap(retryButton());
    await tester.pump();
    // The request could have succeeded but its response was lost. A later
    // terminal attempt and new counter must never cause an automatic retry.
    job = job.copyWith(retryCount: 4);
    pending.completeError(StateError('internal response details'));
    await tester.pumpAndSettle();
    expect(find.text(t.logs.retryFailed), findsOneWidget);
    expect(find.textContaining('internal response details'), findsNothing);
    expect(repository.requests, hasLength(1));
    expect(tester.widget<TextButton>(retryButton()).onPressed, isNotNull);

    repository.respond = () async {};
    await tester.tap(retryButton());
    await tester.pumpAndSettle();
    expect(repository.requests, [
      (id: 'job', expectedRetryCount: 3),
      (id: 'job', expectedRetryCount: 4),
    ]);
  });

  testWidgets('switching connections discards the previous request UI', (
    tester,
  ) async {
    final previous = repository;
    final pending = Completer<void>();
    previous.respond = () => pending.future;
    await show(tester);
    await tester.tap(retryButton());
    await tester.pump();

    repository = _Repository();
    container.invalidate(buildRepositoryProvider);
    await tester.pumpAndSettle();
    pending.completeError(StateError('old connection failed'));
    await tester.pumpAndSettle();
    expect(find.text(t.logs.retryFailed), findsNothing);
    expect(repository.requests, isEmpty);
    expect(tester.takeException(), isNull);

    await tester.tap(retryButton());
    await tester.pumpAndSettle();
    expect(repository.requests, [(id: 'job', expectedRetryCount: 3)]);
    expect(previous.requests, hasLength(1));
  });

  testWidgets('finishing after leaving the page does not update disposed UI', (
    tester,
  ) async {
    final pending = Completer<void>();
    repository.respond = () => pending.future;
    await show(tester);
    await tester.tap(retryButton());
    await tester.pumpWidget(const SizedBox.shrink());
    pending.complete();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a translated accessible button on a narrow screen', (
    tester,
  ) async {
    LocaleSettings.setLocaleSync(AppLocale.ja);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await show(tester);
    expect(find.byTooltip('再実行'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('再実行'));
    await tester.pumpAndSettle();
    expect(find.text('再実行を受け付けました。'), findsOneWidget);
    expect(repository.requests, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('explains waiting when the retried job has no earlier run', (
    tester,
  ) async {
    job = job.copyWith(status: BuildJobStatus.QUEUED, latestRunId: null);
    await show(tester);
    expect(find.text(t.logs.retryWaiting), findsOneWidget);
    expect(find.text(t.logs.retryWaitingPreviousLogs), findsNothing);
  });
}
