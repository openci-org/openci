import 'package:openci_shared/openci_shared.dart';

class BuildStepSummary {
  final String id;
  final String name;
  final BuildJobStatus status;
  final Duration duration;

  const BuildStepSummary({
    required this.id,
    required this.name,
    required this.status,
    required this.duration,
  });
}

const mockBuildSteps = [
  BuildStepSummary(
    id: 'setup',
    name: 'Set up job',
    status: BuildJobStatus.SUCCESS,
    duration: Duration(seconds: 12),
  ),
  BuildStepSummary(
    id: 'checkout',
    name: 'Checkout repository',
    status: BuildJobStatus.SUCCESS,
    duration: Duration(seconds: 4),
  ),
  BuildStepSummary(
    id: 'flutter_pub_get',
    name: 'Run flutter pub get',
    status: BuildJobStatus.SUCCESS,
    duration: Duration(seconds: 28),
  ),
  BuildStepSummary(
    id: 'flutter_analyze',
    name: 'Run flutter analyze',
    status: BuildJobStatus.SUCCESS,
    duration: Duration(seconds: 45),
  ),
  BuildStepSummary(
    id: 'flutter_test',
    name: 'Run flutter test',
    status: BuildJobStatus.FAILURE,
    duration: Duration(minutes: 2, seconds: 15),
  ),
  BuildStepSummary(
    id: 'post_checkout',
    name: 'Post Checkout repository',
    status: BuildJobStatus.SKIPPED,
    duration: Duration.zero,
  ),
];

const mockStepLogs = {
  'setup': [
    'Operating System: macOS 14.5 (23F79)',
    'Virtual Environment: Lume VM (Apple Silicon)',
    'Ssh Connection established successfully.',
    'Cleaning workspace...',
    'Installing runner dependencies...',
    'Preparing environment variables...',
    'Job Setup Completed.',
  ],
  'checkout': [
    'Syncing repository: openci-org/openci',
    'Getting Git version...',
    'git version 2.43.0',
    'git init "/tmp/openci-workspace"',
    'git remote add origin https://github.com/openci-org/openci.git',
    'git fetch --no-tags --prune --progress --no-recurse-submodules --depth=1 origin +refs/heads/main:refs/remotes/origin/main',
    'git checkout --progress --force -B main refs/remotes/origin/main',
    'git log -1 --format=\'%H\'',
    'Checked out commit: e7f0af36040d914169387b03bf7b197433d16bbb',
  ],
  'flutter_pub_get': [
    'Resolving dependencies in workspace...',
    'Running: flutter pub get',
    '  _fe_analyzer_shared 93.0.0',
    '  analyzer 10.0.1',
    '  build_runner 2.15.0',
    '  chopper 8.6.0',
    '  drift 2.33.0',
    '  flutter_riverpod 3.3.1',
    '  go_router 17.2.3',
    'Got dependencies (14.2s)!',
    'Precompiling executables...',
    'Done precompiling build_runner:build_runner.',
  ],
  'flutter_analyze': [
    'Running: flutter analyze',
    'Analyzing dashboard...',
    'Analyzing openci_server...',
    'Analyzing openci_shared...',
    'No issues found! (ran in 41.5s)',
  ],
  'flutter_test': [
    'Running: flutter test',
    '00:02 +0: test/widget_test.dart: Counter increments smoke test',
    '00:15 +1: test/models/build_job_test.dart: serialization success',
    '00:32 +2: test/routes/builds/commits_test.dart: routing and sorting logic',
    '00:54 +3: test/api/openci_api_service_test.dart: client requests validation',
    '01:10 +4: test/webhook_task/extract_commit_message_test.dart: extract message with fallback',
    '01:45 +5: test/auth/auth_provider_test.dart: login status propagation',
    '02:05 +6 -1: test/store_release/store_release_provider_test.dart: verify submission flow [E]',
    '  Expected: \'submitted\'',
    '    Actual: \'failed\'',
    '   Which: is not equal to \'submitted\'',
    '  ',
    '  package:test_api                          expect',
    '  test/store_release_provider_test.dart:45  main.<fn>',
    '  ',
    '02:15 +6 -1: Some tests failed.',
    'Error: Process completed with exit code 1.',
  ],
  'post_checkout': [
    'Skipping post action because previous steps failed.',
  ],
};
