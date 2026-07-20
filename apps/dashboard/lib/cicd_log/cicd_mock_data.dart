import 'package:dashboard/build_logs/chips/job_status.dart';

final mockCommits = [
  MockCommitData(
    branch: 'main',
    commitSha: 'a1c3e4f',
    commitMessage: 'feat: add apple sign-in support to iOS app',
    status: MockStatus.success,
    timeAgo: '10分前',
    triggerType: 'push',
    workflows: [
      MockWorkflowData(
        fileName: 'ios.yaml',
        status: MockStatus.success,
        duration: '4分20秒',
        dependencies: [
          MockJobGroup(
            label: 'checkout-and-setup',
            status: MockStatus.success,
          ),
        ],
        leafJobs: [
          MockJobGroup(label: 'build-ipa', status: MockStatus.success),
          MockJobGroup(
            label: 'deploy-testflight',
            status: MockStatus.success,
          ),
        ],
      ),
      MockWorkflowData(
        fileName: 'android.yaml',
        status: MockStatus.success,
        duration: '3分15秒',
        dependencies: [],
        leafJobs: [
          MockJobGroup(label: 'build-apk', status: MockStatus.success),
        ],
      ),
    ],
  ),
  MockCommitData(
    branch: 'feat/google-login',
    commitSha: '8d2f91a',
    commitMessage: 'fix(android): resolve build crash on Android 14',
    status: MockStatus.failure,
    timeAgo: '1時間前',
    triggerType: 'pull_request',
    prNumber: 42,
    workflows: [
      MockWorkflowData(
        fileName: 'ios.yaml',
        status: MockStatus.success,
        duration: '4分10秒',
        dependencies: [],
        leafJobs: [
          MockJobGroup(label: 'build-ipa', status: MockStatus.success),
        ],
      ),
      MockWorkflowData(
        fileName: 'android.yaml',
        status: MockStatus.failure,
        duration: '2分30秒',
        dependencies: [
          MockJobGroup(label: 'setup-env', status: MockStatus.success),
        ],
        leafJobs: [
          MockJobGroup(
            label: 'e2e-pixel-7 (Android 14)',
            status: MockStatus.success,
          ),
          MockJobGroup(
            label: 'e2e-galaxy-s23 (Android 13)',
            status: MockStatus.success,
          ),
          MockJobGroup(
            label: 'e2e-nexus-5x (Android 8.1)',
            status: MockStatus.failure,
          ),
        ],
      ),
    ],
  ),
  MockCommitData(
    branch: 'fix/typo',
    commitSha: '3c8e7b2',
    commitMessage: 'docs: update README.md instruction details',
    status: MockStatus.inProgress,
    timeAgo: '実行中',
    triggerType: 'push',
    workflows: [
      MockWorkflowData(
        fileName: 'static-analysis.yaml',
        status: MockStatus.success,
        duration: '45秒',
        dependencies: [],
        leafJobs: [
          MockJobGroup(label: 'linter', status: MockStatus.success),
          MockJobGroup(
            label: 'formatter-check',
            status: MockStatus.success,
          ),
        ],
      ),
      MockWorkflowData(
        fileName: 'ios.yaml',
        status: MockStatus.inProgress,
        duration: '2分経過',
        dependencies: [
          MockJobGroup(
            label: 'npm-dependency-cache',
            status: MockStatus.success,
          ),
        ],
        leafJobs: [
          MockJobGroup(label: 'build-ipa', status: MockStatus.inProgress),
        ],
      ),
    ],
  ),
];

enum MockStatus { success, failure, inProgress }

ChipStatus toChipStatus(MockStatus status) => switch (status) {
  MockStatus.success => ChipStatus.success,
  MockStatus.failure => ChipStatus.fail,
  MockStatus.inProgress => ChipStatus.inProgress,
};

class MockCommitData {
  final String branch;
  final String commitSha;
  final String commitMessage;
  final MockStatus status;
  final String timeAgo;
  final String triggerType; // 'push' or 'pull_request'
  final int? prNumber;
  final List<MockWorkflowData> workflows;

  MockCommitData({
    required this.branch,
    required this.commitSha,
    required this.commitMessage,
    required this.status,
    required this.timeAgo,
    required this.triggerType,
    this.prNumber,
    required this.workflows,
  });
}

class MockWorkflowData {
  final String fileName;
  final MockStatus status;
  final String duration;
  final List<MockJobGroup> dependencies;
  final List<MockJobGroup> leafJobs;

  MockWorkflowData({
    required this.fileName,
    required this.status,
    required this.duration,
    required this.dependencies,
    required this.leafJobs,
  });
}

class MockJobGroup {
  final String label;
  final MockStatus status;

  MockJobGroup({
    required this.label,
    required this.status,
  });
}
