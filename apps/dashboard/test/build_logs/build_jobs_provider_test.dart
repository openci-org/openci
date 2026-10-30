import 'dart:async';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/build_logs/build_jobs_provider.dart';
import 'package:dashboard/build_logs/build_repository.dart';
import 'package:dashboard/team/selected_team_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeUser extends Fake implements User {}

class FakeRepository implements BuildRepository {
  final jobs = StreamController<BuildJob?>();
  @override
  Stream<BuildJob?> watchJob(String id) => jobs.stream;
  @override
  Stream<List<BuildJob>> watchJobs(String teamId) => throw UnimplementedError();
}

class _SelectedTeam extends SelectedTeamId {
  @override
  Future<String?> build() async => 'initial-team';
  @override
  Future<void> saveSelectedTeamId(String teamId) async {
    state = AsyncData(teamId);
  }
}

void main() {
  testWidgets('subscribes through FSC and receives job state changes', (
    tester,
  ) async {
    final repository = FakeRepository();
    final ready = Completer<BuildRepository>();
    final container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith(
          (ref) => Stream.value(FakeUser()),
        ),
        buildRepositoryProvider.overrideWith((ref) => ready.future),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(repository.jobs.close);
    final provider = buildJobByIdProvider('job');
    container.listen(provider, (_, _) {});
    await tester.pump();
    expect(container.read(provider).isLoading, isTrue);
    ready.complete(repository);
    await tester.pump();
    final job = BuildJob(
      id: 'job',
      status: BuildJobStatus.QUEUED,
      owner: 'owner',
      repo: 'repo',
      workflowName: 'CI',
      workflowFileName: 'ci.dart',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    repository.jobs.add(job);
    await tester.pump();
    expect(container.read(provider).requireValue, job);
    repository.jobs.add(job.copyWith(status: BuildJobStatus.SUCCESS));
    await tester.pump();
    expect(
      container.read(provider).requireValue!.status,
      BuildJobStatus.SUCCESS,
    );
  });
  test(
    'later job notifications do not undo a deliberate team switch',
    () async {
      final repository = FakeRepository();
      final container = ProviderContainer.test(
        overrides: [
          authStateChangesProvider.overrideWith(
            (ref) => Stream.value(FakeUser()),
          ),
          buildRepositoryProvider.overrideWith((ref) => repository),
          selectedTeamIdProvider.overrideWith(_SelectedTeam.new),
        ],
      );
      container.listen(buildJobByIdProvider('job'), (_, _) {});
      container.listen(selectedTeamIdProvider, (_, _) {});
      await container.read(selectedTeamIdProvider.future);
      await container.pump();
      final job = BuildJob(
        id: 'job',
        teamId: 'job-team',
        status: BuildJobStatus.IN_PROGRESS,
        owner: 'owner',
        repo: 'repo',
        workflowName: 'CI',
        workflowFileName: 'ci.dart',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      repository.jobs.add(job);
      await container.read(buildJobByIdProvider('job').future);
      expect(container.read(selectedTeamIdProvider).requireValue, 'job-team');
      await container
          .read(selectedTeamIdProvider.notifier)
          .saveSelectedTeamId('other-team');
      repository.jobs.add(job.copyWith(status: BuildJobStatus.SUCCESS));
      await container.pump();
      expect(container.read(selectedTeamIdProvider).requireValue, 'other-team');
      await repository.jobs.close();
    },
  );

  test('adapts FSC Int64 and encoded matrix values', () {
    final job = buildJobFromFsc({
      'id': 'job',
      'status': 'IN_PROGRESS',
      'owner': 'owner',
      'repo': 'repo',
      'workflowName': 'CI',
      'workflowFileName': 'ci.dart',
      'createdAt': '1735689600',
      'updatedAt': '1735689601',
      'runCount': '2',
      'pullRequestNumber': '42',
      'matrix': '{"os":"macos"}',
      'needs': '["prepare"]',
      'githubBaseUrl': 'https://github.test',
    });
    expect(job.createdAt, DateTime.utc(2025));
    expect(job.runCount, 2);
    expect(job.matrix, {'os': 'macos'});
    expect(job.needs, ['prepare']);
    expect(job.githubBaseUrl, 'https://github.test');
  });
}
