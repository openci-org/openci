import 'dart:async';

import 'package:build_job_worker/build_job_worker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:openci_shared/test_helpers.dart';
import 'package:test/test.dart';

class _MockOpenCIApiService extends Mock implements OpenCIApiService {}

void main() {
  const pollInterval = Duration(milliseconds: 20);
  late OpenCIApiService api;
  late BuildJob firstJob;
  late BuildJob secondJob;
  late List<BuildJob> executed;
  late List<(Object, StackTrace)> errors;
  late Future<BuildJobStatus> Function(BuildJob) executeJob;
  late Future<int> Function() getMaxConcurrentJobs;
  var stopRequested = false;

  Future<void> run({Duration interval = pollInterval}) => runBuildJobWorker(
    api: api,
    getMaxConcurrentJobs: () => getMaxConcurrentJobs(),
    executeJob: (job) {
      executed.add(job);
      return executeJob(job);
    },
    shouldStop: () => stopRequested,
    onError: (error, stackTrace) => errors.add((error, stackTrace)),
    pollInterval: interval,
  );

  setUp(() {
    api = _MockOpenCIApiService();
    stopRequested = false;
    executed = [];
    errors = [];
    getMaxConcurrentJobs = () async => 1;
    final now = DateTime.utc(2026, 9, 7);
    firstJob = BuildJob(
      id: 'job-1',
      status: BuildJobStatus.IN_PROGRESS,
      owner: 'acme',
      repo: 'app',
      workflowName: 'CI',
      workflowFileName: 'ci.dart',
      createdAt: now,
      updatedAt: now,
    );
    secondJob = firstJob.copyWith(id: 'job-2');
    executeJob = (_) async {
      stopRequested = true;
      return BuildJobStatus.SUCCESS;
    };
    when(
      () => api.claimNextJob(const {}),
    ).thenAnswer((_) async => createMockResponse({'job': firstJob.toJson()}));
  });

  group('runBuildJobWorker', () {
    test(
      'passes the claimed job to the executor and stops after it finishes',
      () async {
        await run();

        expect(executed, [firstJob]);
        expect(errors, isEmpty);
        verify(() => api.claimNextJob(const {})).called(1);
        verifyNoMoreInteractions(api);
      },
    );

    test('does not claim a job if stopping was already requested', () async {
      stopRequested = true;

      await run();

      expect(executed, isEmpty);
      expect(errors, isEmpty);
      verifyZeroInteractions(api);
    });

    for (final interval in [Duration.zero, const Duration(seconds: -1)]) {
      test('rejects a nonpositive poll interval: $interval', () async {
        await expectLater(run(interval: interval), throwsArgumentError);

        expect(executed, isEmpty);
        verifyZeroInteractions(api);
      });
    }

    test('fills two slots and reuses a completed slot', () async {
      final thirdJob = firstJob.copyWith(id: 'job-3');
      final jobs = [firstJob, secondJob, thirdJob];
      final completions = [Completer<void>(), Completer<void>()];
      final fullPoll = Completer<void>();
      final thirdStarted = Completer<void>();
      var claims = 0;
      getMaxConcurrentJobs = () async {
        if (executed.length == 2 && !fullPoll.isCompleted) fullPoll.complete();
        return 2;
      };
      when(() => api.claimNextJob(const {})).thenAnswer((_) async {
        return createMockResponse({'job': jobs[claims++].toJson()});
      });
      executeJob = (job) async {
        if (job.id == thirdJob.id) {
          stopRequested = true;
          thirdStarted.complete();
        } else {
          await completions[jobs.indexOf(job)].future;
        }
        return BuildJobStatus.SUCCESS;
      };

      var stopped = false;
      final worker = run().then((_) => stopped = true);
      await fullPoll.future;
      await Future<void>.delayed(Duration.zero);
      expect(claims, 2);
      expect(executed, [firstJob, secondJob]);

      completions.first.complete();
      await thirdStarted.future;
      expect(claims, 3);
      expect(stopped, isFalse);
      completions.last.complete();
      await worker;
      expect(executed, jobs);
      expect(errors, isEmpty);
    });

    for (final failure in [null, StateError('Capacity unavailable')]) {
      test(
        'pauses claims for ${failure ?? 'zero capacity'} and retries',
        () async {
          final firstPoll = Completer<void>();
          var polls = 0;
          getMaxConcurrentJobs = () async {
            if (++polls == 1) {
              firstPoll.complete();
              if (failure != null) throw failure;
              return 0;
            }
            return 1;
          };

          final worker = run();
          await firstPoll.future;
          await Future<void>.delayed(Duration.zero);
          verifyZeroInteractions(api);
          expect(executed, isEmpty);
          await worker;
          expect(polls, 2);
          expect(executed, [firstJob]);
          expect(
            errors.map((entry) => entry.$1),
            failure == null ? <Object>[] : [failure],
          );
        },
      );
    }

    test('does not claim after stopping during a capacity request', () async {
      final capacity = Completer<int>();
      getMaxConcurrentJobs = () => capacity.future;

      final worker = run();
      stopRequested = true;
      capacity.complete(2);
      await worker;

      verifyZeroInteractions(api);
      expect(executed, isEmpty);
    });

    test('uses increased capacity while a job is still running', () async {
      final finishFirst = Completer<void>();
      final secondStarted = Completer<void>();
      var polls = 0;
      var claims = 0;
      getMaxConcurrentJobs = () async => ++polls == 1 ? 1 : 2;
      when(() => api.claimNextJob(const {})).thenAnswer((_) async {
        final job = claims++ == 0 ? firstJob : secondJob;
        return createMockResponse({'job': job.toJson()});
      });
      executeJob = (job) async {
        if (job.id == firstJob.id) {
          await finishFirst.future;
        } else {
          stopRequested = true;
          secondStarted.complete();
        }
        return BuildJobStatus.SUCCESS;
      };

      final worker = run();
      await secondStarted.future;
      expect(claims, 2);
      expect(finishFirst.isCompleted, isFalse);
      finishFirst.complete();
      await worker;
      expect(errors, isEmpty);
    });

    test(
      'respects reduced capacity without interrupting running jobs',
      () async {
        final completions = [Completer<void>(), Completer<void>()];
        final reducedPoll = Completer<void>();
        final afterCompletionPoll = Completer<void>();
        var polls = 0;
        var claims = 0;
        getMaxConcurrentJobs = () async {
          polls++;
          if (polls == 2) reducedPoll.complete();
          if (polls == 3) afterCompletionPoll.complete();
          return polls == 1 ? 2 : 1;
        };
        when(() => api.claimNextJob(const {})).thenAnswer((_) async {
          final job = claims++ == 0 ? firstJob : secondJob;
          return createMockResponse({'job': job.toJson()});
        });
        executeJob = (job) async {
          await completions[job.id == firstJob.id ? 0 : 1].future;
          return BuildJobStatus.SUCCESS;
        };

        final worker = run();
        await reducedPoll.future;
        expect(
          completions.every((completion) => !completion.isCompleted),
          isTrue,
        );
        completions.first.complete();
        await afterCompletionPoll.future;
        await Future<void>.delayed(Duration.zero);
        expect(claims, 2);
        stopRequested = true;
        completions.last.complete();
        await worker;
        expect(errors, isEmpty);
      },
    );

    test('reports a synchronous executor exception', () async {
      final error = StateError('Synchronous failure');
      executeJob = (_) {
        stopRequested = true;
        throw error;
      };

      await run();

      expect(errors.single.$1, same(error));
      expect(executed, [firstJob]);
    });

    test(
      'waits when the queue is empty, then processes the next job',
      () async {
        final emptyResponse = Completer<void>();
        var claims = 0;
        when(() => api.claimNextJob(const {})).thenAnswer((_) async {
          claims++;
          if (claims == 1) {
            emptyResponse.complete();
            return createMockResponse({'job': null});
          }
          return createMockResponse({'job': firstJob.toJson()});
        });

        final worker = run();
        await emptyResponse.future;
        await Future<void>.delayed(Duration.zero);

        expect(claims, 1);
        expect(executed, isEmpty);
        await worker;
        expect(claims, 2);
        expect(executed, [firstJob]);
        expect(errors, isEmpty);
      },
    );

    for (final firstResult in [
      BuildJobStatus.SUCCESS,
      BuildJobStatus.FAILURE,
    ]) {
      test('continues to another job after a $firstResult result', () async {
        var claims = 0;
        when(() => api.claimNextJob(const {})).thenAnswer((_) async {
          final job = claims++ == 0 ? firstJob : secondJob;
          return createMockResponse({'job': job.toJson()});
        });
        executeJob = (job) async {
          if (job.id == firstJob.id) return firstResult;
          stopRequested = true;
          return BuildJobStatus.SUCCESS;
        };

        await run();

        expect(executed, [firstJob, secondJob]);
        expect(claims, 2);
        expect(errors, isEmpty);
      });
    }

    test(
      'does not claim another job until execution and cleanup finish',
      () async {
        final executionStarted = Completer<void>();
        final executionFinished = Completer<void>();
        final cleanupStarted = Completer<void>();
        final cleanupFinished = Completer<void>();
        var claims = 0;
        when(() => api.claimNextJob(const {})).thenAnswer((_) async {
          final job = claims++ == 0 ? firstJob : secondJob;
          return createMockResponse({'job': job.toJson()});
        });
        executeJob = (job) async {
          if (job.id == firstJob.id) {
            executionStarted.complete();
            await executionFinished.future;
            cleanupStarted.complete();
            await cleanupFinished.future;
          } else {
            stopRequested = true;
          }
          return BuildJobStatus.SUCCESS;
        };

        final worker = run();
        await executionStarted.future;

        expect(claims, 1);
        executionFinished.complete();
        await cleanupStarted.future;
        expect(claims, 1);
        expect(executed, [firstJob]);
        cleanupFinished.complete();
        await worker;
        expect(claims, 2);
        expect(executed, [firstJob, secondJob]);
      },
    );

    test('reports an HTTP claim error, waits and continues', () async {
      final failedResponse = Completer<void>();
      var claims = 0;
      when(() => api.claimNextJob(const {})).thenAnswer((_) async {
        claims++;
        if (claims == 1) {
          failedResponse.complete();
          return createMockResponse<Map<String, dynamic>>({}, statusCode: 503);
        }
        return createMockResponse({'job': firstJob.toJson()});
      });

      final worker = run();
      await failedResponse.future;
      await Future<void>.delayed(Duration.zero);

      expect(claims, 1);
      expect(executed, isEmpty);
      expect(errors.single.$1, isA<StateError>());
      expect(errors.single.$1.toString(), contains('HTTP 503'));
      await worker;
      expect(claims, 2);
      expect(executed, [firstJob]);
    });

    test('preserves a thrown claim error and stack while continuing', () async {
      final error = StateError('Connection failed');
      final stack = StackTrace.fromString('Claim failed here');
      var claims = 0;
      when(() => api.claimNextJob(const {})).thenAnswer((_) async {
        if (claims++ == 0) Error.throwWithStackTrace(error, stack);
        return createMockResponse({'job': firstJob.toJson()});
      });

      await run();

      expect(claims, 2);
      expect(executed, [firstJob]);
      expect(errors.single.$1, same(error));
      expect(errors.single.$2.toString(), stack.toString());
    });

    test(
      'reports an executor exception, waits and continues to the next job',
      () async {
        final error = StateError('Executor failed');
        final stack = StackTrace.fromString('Execution failed here');
        final executionStarted = Completer<void>();
        var claims = 0;
        when(() => api.claimNextJob(const {})).thenAnswer((_) async {
          final job = claims++ == 0 ? firstJob : secondJob;
          return createMockResponse({'job': job.toJson()});
        });
        executeJob = (job) async {
          if (job.id == firstJob.id) {
            executionStarted.complete();
            Error.throwWithStackTrace(error, stack);
          }
          stopRequested = true;
          return BuildJobStatus.SUCCESS;
        };

        final worker = run();
        await executionStarted.future;
        await Future<void>.delayed(Duration.zero);

        expect(claims, 1);
        expect(errors.single.$1, same(error));
        expect(errors.single.$2.toString(), stack.toString());
        await worker;
        expect(claims, 2);
        expect(executed, [firstJob, secondJob]);
        expect(errors, hasLength(1));
      },
    );

    test(
      'finishes a job claimed while stopping instead of abandoning it',
      () async {
        final claimStarted = Completer<void>();
        final claimedJob = Completer<BuildJob>();
        final executionStarted = Completer<void>();
        final cleanupFinished = Completer<void>();
        var stopped = false;
        when(() => api.claimNextJob(const {})).thenAnswer((_) async {
          claimStarted.complete();
          final job = await claimedJob.future;
          return createMockResponse({'job': job.toJson()});
        });
        executeJob = (_) async {
          executionStarted.complete();
          await cleanupFinished.future;
          return BuildJobStatus.SUCCESS;
        };

        final worker = run().then((_) => stopped = true);
        await claimStarted.future;
        stopRequested = true;
        claimedJob.complete(firstJob);
        await executionStarted.future;

        expect(executed, [firstJob]);
        expect(stopped, isFalse);
        cleanupFinished.complete();
        await worker;
        expect(stopped, isTrue);
        verify(() => api.claimNextJob(const {})).called(1);
      },
    );

    test(
      'waits for the running job to finish when stopping is requested',
      () async {
        final executionStarted = Completer<void>();
        final cleanupFinished = Completer<void>();
        var stopped = false;
        executeJob = (_) async {
          executionStarted.complete();
          await cleanupFinished.future;
          return BuildJobStatus.SUCCESS;
        };

        final worker = run().then((_) => stopped = true);
        await executionStarted.future;
        stopRequested = true;
        await Future<void>.delayed(Duration.zero);

        expect(stopped, isFalse);
        cleanupFinished.complete();
        await worker;
        expect(stopped, isTrue);
        verify(() => api.claimNextJob(const {})).called(1);
      },
    );

    test(
      'does not claim again if stopping is requested during idle waiting',
      () async {
        final emptyResponse = Completer<void>();
        when(() => api.claimNextJob(const {})).thenAnswer((_) async {
          emptyResponse.complete();
          return createMockResponse({'job': null});
        });

        final worker = run();
        await emptyResponse.future;
        await Future<void>.delayed(Duration.zero);
        stopRequested = true;
        await worker;

        expect(executed, isEmpty);
        verify(() => api.claimNextJob(const {})).called(1);
      },
    );

    test(
      'skips idle waiting when stopping is requested during an empty claim',
      () async {
        when(() => api.claimNextJob(const {})).thenAnswer((_) async {
          stopRequested = true;
          return createMockResponse({'job': null});
        });

        await run(
          interval: const Duration(minutes: 1),
        ).timeout(const Duration(seconds: 1));

        expect(executed, isEmpty);
        verify(() => api.claimNextJob(const {})).called(1);
      },
    );
  });
}
