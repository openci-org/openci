import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'initial_workflow_setup_provider.freezed.dart';
part 'initial_workflow_setup_provider.g.dart';

enum TriggerType {
  pullRequest,
  push,
  tag,
  release,
  ;

  @override
  toString() {
    switch (this) {
      case TriggerType.pullRequest:
        return 'pullRequest';
      case TriggerType.push:
        return 'push';
      case TriggerType.tag:
        return 'tag';
      case TriggerType.release:
        return 'release';
    }
  }

  static TriggerType fromValue(String value) {
    switch (value) {
      case 'pullRequest':
        return TriggerType.pullRequest;
      case 'push':
        return TriggerType.push;
      case 'tag':
        return TriggerType.tag;
      case 'release':
        return TriggerType.release;
      default:
        throw ArgumentError('Invalid TriggerType value: $value');
    }
  }
}

@riverpod
class InitialWorkflowSetup extends _$InitialWorkflowSetup {
  @override
  InitialWorkflowSetupState build() => InitialWorkflowSetupState(
    isCreated: false,
    name: '',
    selectedRepository: '',
    selectedWorkingDirectory: '',
    selectedTriggerType: TriggerType.push,
    selectedTriggerBranch: '',
  );

  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  void updateIsCreated(bool value) {
    state = state.copyWith(isCreated: value);
  }

  void updateSelectedRepository(String repository) {
    state = state.copyWith(selectedRepository: repository);
  }

  void updateSelectedWorkingDirectory(String directory) {
    state = state.copyWith(selectedWorkingDirectory: directory);
  }

  void updateSelectedTriggerType(TriggerType type) {
    state = state.copyWith(selectedTriggerType: type);
  }

  void updateSelectedTriggerBranch(String branch) {
    state = state.copyWith(selectedTriggerBranch: branch);
  }

  Future<void> save({
    required String name,
    required String selectedRepository,
    required String selectedWorkingDirectory,
    String? selectedTriggerBranch,
  }) async {
    throw UnimplementedError(
      'Workflow creation via GitHub commit is not yet implemented. '
      'Workflows are managed as .openci/*.yaml files in the repository.',
    );
  }
}

@Freezed(makeCollectionsUnmodifiable: false)
abstract class InitialWorkflowSetupState with _$InitialWorkflowSetupState {
  const factory InitialWorkflowSetupState({
    required bool isCreated,
    required String name,
    required String selectedRepository,
    required String selectedWorkingDirectory,
    required TriggerType selectedTriggerType,
    required String selectedTriggerBranch,
  }) = _InitialWorkflowSetupState;

  factory InitialWorkflowSetupState.fromJson(Map<String, Object?> json) =>
      _$InitialWorkflowSetupStateFromJson(json);
}
