import 'package:dashboard/environment_variables/environment_variable_provider.dart';
import 'package:dashboard/secret_manager/secret_manager_provider.dart';
import 'package:dashboard/workflow/editor/workflow_editor_provider.dart';
import 'package:dashboard/workflow/list/workflow_list_provider.dart';
import 'package:dashboard/workflow/yaml_workflow.dart';
import 'package:dashboard/workflow/yaml_workflow_converter.dart';
import 'package:yaml/yaml.dart';

const useMockData = true;

const mockWorkflowYaml1 = '''
name: iOS Release Build
on:
  push:
    branches:
      - main
      - release/*
working_directory: mobile
steps:
  - name: Checkout
    uses: actions/checkout@v4
  - name: Setup Flutter
    uses: subosito/flutter-action@v2
    with:
      flutter-version: 3.38.7
      channel: stable
  - name: Install Dependencies
    run: flutter pub get
  - name: Run Tests
    run: flutter test
  - name: Build IPA
    run: flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
  - name: Upload to App Store Connect
    run: xcrun altool --upload-app -f build/ios/ipa/*.ipa
''';

const mockWorkflowYaml2 = '''
name: Pull Request Check
on:
  pull_request:
    branches:
      - main
      - develop
steps:
  - name: Checkout
    uses: actions/checkout@v4
  - name: Analyze Code
    run: flutter analyze
  - name: Run Tests
    run: flutter test --coverage
  - name: Check Formatting
    run: dart format --set-exit-if-changed .
''';

const mockWorkflowYaml3 = '''
name: Android Release
on:
  release:
    types:
      - published
working_directory: mobile
steps:
  - name: Setup Java
    run: echo "Setting up Java 17"
  - name: Build APK
    run: flutter build apk --release
  - name: Build App Bundle
    run: flutter build appbundle --release
  - name: Upload to Play Store
    run: fastlane supply --aab build/app/outputs/bundle/release/app-release.aab
''';

const mockWorkflowYaml4 = '''
name: Nightly E2E Tests
on:
  push:
    branches:
      - develop
steps:
  - name: Start Emulator
    run: emulator -avd Pixel_6_API_33 -no-audio -no-window
  - name: Run Integration Tests
    run: flutter test integration_test/
''';

const mockWorkflowYaml5 = '''
name: Tag Deploy
on:
  create:
    tags: true
steps:
  - name: Build Web
    run: flutter build web --release
  - name: Deploy to Firebase
    run: firebase deploy --only hosting
''';

final _mockYamls = {
  'mock-wf-1': mockWorkflowYaml1,
  'mock-wf-2': mockWorkflowYaml2,
  'mock-wf-3': mockWorkflowYaml3,
  'mock-wf-4': mockWorkflowYaml4,
  'mock-wf-5': mockWorkflowYaml5,
};

final _mockNames = {
  'mock-wf-1': 'iOS Release Build',
  'mock-wf-2': 'Pull Request Check',
  'mock-wf-3': 'Android Release',
  'mock-wf-4': 'Nightly E2E Tests',
  'mock-wf-5': 'Tag Deploy',
};

final _mockStatuses = {
  'mock-wf-1': 'success',
  'mock-wf-2': 'failure',
  'mock-wf-3': 'in_progress',
  'mock-wf-4': 'queued',
  'mock-wf-5': 'success',
};

YamlWorkflow _parseYaml(String raw) {
  final yamlMap = loadYaml(raw);
  return YamlWorkflowConverter.fromYamlMap(
    Map<String, dynamic>.from(yamlMap as Map),
  );
}

List<WorkflowListItem> getMockWorkflowList() {
  final now = DateTime.now();
  final offsets = [
    const Duration(minutes: 12),
    const Duration(hours: 1),
    const Duration(minutes: 3),
    const Duration(minutes: 1),
    const Duration(days: 2),
  ];

  final mockFilePaths = [
    '.openci/ios-release.yaml',
    '.openci/pr-check.yaml',
    '.openci/android-release.yaml',
    '.openci/nightly-e2e.yaml',
    '.openci/tag-deploy.yaml',
  ];

  final mockBranches = ['main', 'develop', 'main', 'develop', 'main'];

  return List.generate(5, (i) {
    final id = 'mock-wf-${i + 1}';
    final yamlRaw = _mockYamls[id]!;
    final parsed = _parseYaml(yamlRaw);

    final mockCommitShas = [
      'a1b2c3d',
      'f4e5d6c',
      '7a8b9c0',
      'deadbee',
      'cafe123',
    ];

    return WorkflowListItem(
      id: id,
      name: _mockNames[id]!,
      orgId: 'mock-org-1',
      yamlDefinition: yamlRaw,
      triggerSummary: YamlWorkflowConverter.triggerSummary(parsed.on),
      repository: 'open-ci-io/openci',
      branch: mockBranches[i],
      filePath: mockFilePaths[i],
      commitSha: mockCommitShas[i],
      lastBuildStatus: _mockStatuses[id],
      lastBuildAt: now.subtract(offsets[i]),
      createdAt: now.subtract(Duration(days: 30 - i * 5)),
      updatedAt: now.subtract(offsets[i]),
    );
  });
}

WorkflowEditorState getMockEditorState(String workflowId) {
  final yamlRaw = _mockYamls[workflowId] ?? mockWorkflowYaml1;
  final name = _mockNames[workflowId] ?? 'Mock Workflow';
  final parsed = _parseYaml(yamlRaw);

  final mockFilePaths = {
    'mock-wf-1': '.openci/ios-release.yaml',
    'mock-wf-2': '.openci/pr-check.yaml',
    'mock-wf-3': '.openci/android-release.yaml',
    'mock-wf-4': '.openci/nightly-e2e.yaml',
    'mock-wf-5': '.openci/tag-deploy.yaml',
  };

  final mockBranches = {
    'mock-wf-1': 'main',
    'mock-wf-2': 'develop',
    'mock-wf-3': 'main',
    'mock-wf-4': 'develop',
    'mock-wf-5': 'main',
  };

  return WorkflowEditorState(
    workflowId: workflowId,
    orgId: 'mock-org-1',
    dbName: name,
    yamlRaw: yamlRaw,
    parsedWorkflow: parsed,
    repository: 'open-ci-io/openci',
    branch: mockBranches[workflowId] ?? 'main',
    filePath: mockFilePaths[workflowId] ?? '.openci/workflow.yaml',
    commitSha: 'a1b2c3d4e5f6789012345678901234567890abcd',
  );
}

List<Secret> getMockSecrets() {
  final now = DateTime.now();
  return [
    Secret(
      id: 'mock-secret-1',
      name: 'APP_STORE_CONNECT_API_KEY',
      teamId: 'mock-org-1',
      pathToSecret: 'secrets/app_store_key',
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now.subtract(const Duration(days: 2)),
    ),
    Secret(
      id: 'mock-secret-2',
      name: 'GITHUB_TOKEN',
      teamId: 'mock-org-1',
      pathToSecret: 'secrets/github_token',
      createdAt: now.subtract(const Duration(days: 25)),
      updatedAt: now.subtract(const Duration(days: 1)),
    ),
    Secret(
      id: 'mock-secret-3',
      name: 'SIGNING_CERTIFICATE_P12',
      teamId: 'mock-org-1',
      pathToSecret: 'secrets/signing_cert',
      createdAt: now.subtract(const Duration(days: 20)),
      updatedAt: now.subtract(const Duration(days: 5)),
    ),
    Secret(
      id: 'mock-secret-4',
      name: 'FIREBASE_SERVICE_ACCOUNT',
      teamId: 'mock-org-1',
      pathToSecret: 'secrets/firebase_sa',
      createdAt: now.subtract(const Duration(days: 15)),
      updatedAt: now.subtract(const Duration(days: 3)),
    ),
  ];
}

List<EnvironmentVariable> getMockEnvironmentVariables() {
  final now = DateTime.now();
  return [
    EnvironmentVariable(
      id: 'mock-env-1',
      key: 'OPENCI_RUN_NUMBER',
      value: '42',
      teamId: 'mock-org-1',
      autoIncrement: true,
      createdAt: now.subtract(const Duration(days: 60)),
      updatedAt: now.subtract(const Duration(hours: 2)),
    ),
    EnvironmentVariable(
      id: 'mock-env-2',
      key: 'FLUTTER_VERSION',
      value: '3.38.7',
      teamId: 'mock-org-1',
      createdAt: now.subtract(const Duration(days: 14)),
      updatedAt: now.subtract(const Duration(days: 1)),
    ),
    EnvironmentVariable(
      id: 'mock-env-3',
      key: 'XCODE_VERSION',
      value: '16.2',
      teamId: 'mock-org-1',
      createdAt: now.subtract(const Duration(days: 10)),
      updatedAt: now.subtract(const Duration(days: 3)),
    ),
    EnvironmentVariable(
      id: 'mock-env-4',
      key: 'BUILD_CONFIGURATION',
      value: 'release',
      teamId: 'mock-org-1',
      createdAt: now.subtract(const Duration(days: 7)),
      updatedAt: now.subtract(const Duration(days: 1)),
    ),
  ];
}
