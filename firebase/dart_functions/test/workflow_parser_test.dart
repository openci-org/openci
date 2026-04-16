import 'package:test/test.dart';

import 'package:dart_functions/github/workflow_parser.dart';

void main() {
  group('matchesTrigger', () {
    group('on is a string', () {
      test('matches when trigger type equals on value', () {
        final parsed = {'on': 'push'};
        expect(matchesTrigger(parsed, 'push', 'main'), isTrue);
      });

      test('does not match different trigger type', () {
        final parsed = {'on': 'push'};
        expect(matchesTrigger(parsed, 'release', null), isFalse);
      });

      test('maps pullRequest to pull_request', () {
        final parsed = {'on': 'pull_request'};
        expect(matchesTrigger(parsed, 'pullRequest', 'main'), isTrue);
      });
    });

    group('on is a list', () {
      test('matches when trigger type is in list', () {
        final parsed = {
          'on': ['push', 'pull_request'],
        };
        expect(matchesTrigger(parsed, 'push', 'main'), isTrue);
        expect(matchesTrigger(parsed, 'pullRequest', 'main'), isTrue);
      });

      test('does not match when trigger type is not in list', () {
        final parsed = {
          'on': ['push'],
        };
        expect(matchesTrigger(parsed, 'release', null), isFalse);
      });
    });

    group('on is a map', () {
      test('matches when trigger key exists with null value', () {
        final parsed = {
          'on': {'push': null},
        };
        expect(matchesTrigger(parsed, 'push', 'main'), isTrue);
      });

      test('does not match when trigger key is absent', () {
        final parsed = {
          'on': {'push': null},
        };
        expect(matchesTrigger(parsed, 'release', null), isFalse);
      });

      test('matches when branch is in branches list', () {
        final parsed = {
          'on': {
            'push': {
              'branches': ['main', 'develop'],
            },
          },
        };
        expect(matchesTrigger(parsed, 'push', 'main'), isTrue);
        expect(matchesTrigger(parsed, 'push', 'develop'), isTrue);
      });

      test('does not match when branch is not in branches list', () {
        final parsed = {
          'on': {
            'push': {
              'branches': ['main'],
            },
          },
        };
        expect(matchesTrigger(parsed, 'push', 'feature/x'), isFalse);
      });

      test('matches when triggerBranch is null (tag/release)', () {
        final parsed = {
          'on': {
            'release': {
              'branches': ['main'],
            },
          },
        };
        expect(matchesTrigger(parsed, 'release', null), isTrue);
      });

      test('matches map with empty config', () {
        final parsed = {
          'on': {'tag': {}},
        };
        expect(matchesTrigger(parsed, 'tag', null), isTrue);
      });
    });

    test('returns false when on is missing', () {
      expect(matchesTrigger({}, 'push', 'main'), isFalse);
    });
  });

  group('extractJobs', () {
    test('extracts a simple single job', () {
      final parsed = {
        'jobs': {
          'build': {
            'runs-on': 'macos',
            'steps': [
              {'name': 'Checkout', 'uses': 'actions/checkout@v3'},
              {'name': 'Build', 'run': 'flutter build'},
            ],
          },
        },
      };

      final jobs = extractJobs(parsed);
      expect(jobs, hasLength(1));
      expect(jobs[0].jobKey, 'build');
      expect(jobs[0].runsOn, 'macos');
      expect(jobs[0].needs, isEmpty);
      expect(jobs[0].steps, hasLength(2));
      expect(jobs[0].steps[0].uses, 'actions/checkout@v3');
      expect(jobs[0].steps[1].run, 'flutter build');
    });

    test('extracts uses step with params', () {
      final parsed = {
        'jobs': {
          'deploy': {
            'steps': [
              {
                'name': 'Deploy',
                'uses': 'firebase/deploy@v1',
                'with': {'project': 'my-project', 'token': 'abc123'},
              },
            ],
          },
        },
      };

      final jobs = extractJobs(parsed);
      expect(jobs[0].steps[0].withParams, {
        'project': 'my-project',
        'token': 'abc123',
      });
    });

    test('parses needs as list', () {
      final parsed = {
        'jobs': {
          'build': {
            'steps': [
              {'name': 'Build', 'run': 'echo build'},
            ],
          },
          'deploy': {
            'needs': ['build'],
            'steps': [
              {'name': 'Deploy', 'run': 'echo deploy'},
            ],
          },
        },
      };

      final jobs = extractJobs(parsed);
      final deploy = jobs.firstWhere((j) => j.jobKey == 'deploy');
      expect(deploy.needs, ['build']);
    });

    test('parses needs as string', () {
      final parsed = {
        'jobs': {
          'build': {
            'steps': [
              {'name': 'Build', 'run': 'echo build'},
            ],
          },
          'deploy': {
            'needs': 'build',
            'steps': [
              {'name': 'Deploy', 'run': 'echo deploy'},
            ],
          },
        },
      };

      final jobs = extractJobs(parsed);
      final deploy = jobs.firstWhere((j) => j.jobKey == 'deploy');
      expect(deploy.needs, ['build']);
    });

    test('skips jobs with no steps', () {
      final parsed = {
        'jobs': {
          'empty': {'runs-on': 'macos', 'steps': []},
          'valid': {
            'steps': [
              {'name': 'Run', 'run': 'echo hi'},
            ],
          },
        },
      };

      final jobs = extractJobs(parsed);
      expect(jobs, hasLength(1));
      expect(jobs[0].jobKey, 'valid');
    });

    test('skips invalid step entries', () {
      final parsed = {
        'jobs': {
          'build': {
            'steps': [
              null,
              'not a map',
              {'name': 'Valid', 'run': 'echo ok'},
            ],
          },
        },
      };

      final jobs = extractJobs(parsed);
      expect(jobs[0].steps, hasLength(1));
    });

    test('returns empty list when no jobs key', () {
      expect(extractJobs({}), isEmpty);
    });

    test('converts with values to strings', () {
      final parsed = {
        'jobs': {
          'build': {
            'steps': [
              {
                'name': 'Step',
                'uses': 'some/action@v1',
                'with': {'count': 42, 'enabled': true},
              },
            ],
          },
        },
      };

      final jobs = extractJobs(parsed);
      expect(jobs[0].steps[0].withParams, {'count': '42', 'enabled': 'true'});
    });
  });

  group('workflowFileDocId', () {
    test('generates stable doc ID', () {
      expect(
        workflowFileDocId('team1', 'owner/repo', 'main', 'ci.yaml'),
        'team1_owner_repo_main_ci.yaml',
      );
    });
  });
}
