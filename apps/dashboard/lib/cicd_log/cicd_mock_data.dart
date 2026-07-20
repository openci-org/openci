import 'package:dashboard/build_logs/chips/job_status.dart';
import 'package:openci_shared/openci_shared.dart';

final mockCommits = [
  CicdCommitGroup(
    branch: 'main',
    commitSha: 'a1c3e4f',
    commitMessage: 'feat: add apple sign-in support to iOS app',
    status: BuildJobStatus.SUCCESS,
    createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
    workflows: [
      CicdWorkflowGroup(
        fileName: 'ios.yaml',
        status: BuildJobStatus.SUCCESS,
        duration: const Duration(minutes: 4, seconds: 20),
        stages: [
          [
            CicdJobGroup(
              id: 'job-1',
              label: 'checkout-and-setup',
              status: BuildJobStatus.SUCCESS,
            ),
          ],
          [
            CicdJobGroup(
              id: 'job-2',
              label: 'build-ipa',
              status: BuildJobStatus.SUCCESS,
            ),
            CicdJobGroup(
              id: 'job-3',
              label: 'deploy-testflight',
              status: BuildJobStatus.SUCCESS,
            ),
          ],
        ],
      ),
      CicdWorkflowGroup(
        fileName: 'android.yaml',
        status: BuildJobStatus.SUCCESS,
        duration: const Duration(minutes: 3, seconds: 15),
        stages: [
          [
            CicdJobGroup(
              id: 'job-4',
              label: 'build-apk',
              status: BuildJobStatus.SUCCESS,
            ),
          ],
        ],
      ),
    ],
  ),
  CicdCommitGroup(
    branch: 'feat/google-login',
    commitSha: '8d2f91a',
    commitMessage: 'fix(android): resolve build crash on Android 14',
    status: BuildJobStatus.FAILURE,
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    workflows: [
      CicdWorkflowGroup(
        fileName: 'ios.yaml',
        status: BuildJobStatus.SUCCESS,
        duration: const Duration(minutes: 4, seconds: 10),
        stages: [
          [
            CicdJobGroup(
              id: 'job-5',
              label: 'build-ipa',
              status: BuildJobStatus.SUCCESS,
            ),
          ],
        ],
      ),
      CicdWorkflowGroup(
        fileName: 'android.yaml',
        status: BuildJobStatus.FAILURE,
        duration: const Duration(minutes: 2, seconds: 30),
        stages: [
          [
            CicdJobGroup(
              id: 'job-6',
              label: 'setup-env',
              status: BuildJobStatus.SUCCESS,
            ),
          ],
          [
            CicdJobGroup(
              id: 'job-7',
              label: 'e2e-pixel-7 (Android 14)',
              status: BuildJobStatus.SUCCESS,
            ),
            CicdJobGroup(
              id: 'job-8',
              label: 'e2e-galaxy-s23 (Android 13)',
              status: BuildJobStatus.SUCCESS,
            ),
            CicdJobGroup(
              id: 'job-9',
              label: 'e2e-nexus-5x (Android 8.1)',
              status: BuildJobStatus.FAILURE,
            ),
          ],
        ],
      ),
    ],
  ),
  CicdCommitGroup(
    branch: 'fix/typo',
    commitSha: '3c8e7b2',
    commitMessage: 'docs: update README.md instruction details',
    status: BuildJobStatus.IN_PROGRESS,
    createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
    workflows: [
      CicdWorkflowGroup(
        fileName: 'static-analysis.yaml',
        status: BuildJobStatus.SUCCESS,
        duration: const Duration(seconds: 45),
        stages: [
          [
            CicdJobGroup(
              id: 'job-10',
              label: 'linter',
              status: BuildJobStatus.SUCCESS,
            ),
            CicdJobGroup(
              id: 'job-11',
              label: 'formatter-check',
              status: BuildJobStatus.SUCCESS,
            ),
          ],
        ],
      ),
      CicdWorkflowGroup(
        fileName: 'ios.yaml',
        status: BuildJobStatus.IN_PROGRESS,
        duration: const Duration(minutes: 2),
        stages: [
          [
            CicdJobGroup(
              id: 'job-12',
              label: 'npm-dependency-cache',
              status: BuildJobStatus.SUCCESS,
            ),
          ],
          [
            CicdJobGroup(
              id: 'job-13',
              label: 'build-ipa',
              status: BuildJobStatus.IN_PROGRESS,
            ),
          ],
        ],
      ),
    ],
  ),
];

ChipStatus toChipStatus(BuildJobStatus status) => switch (status) {
  BuildJobStatus.SUCCESS => ChipStatus.success,
  BuildJobStatus.FAILURE ||
  BuildJobStatus.CANCELLED ||
  BuildJobStatus.TIMED_OUT => ChipStatus.fail,
  BuildJobStatus.IN_PROGRESS => ChipStatus.inProgress,
  BuildJobStatus.QUEUED || BuildJobStatus.WAITING => ChipStatus.queued,
  BuildJobStatus.SKIPPED => ChipStatus.skipped,
};
