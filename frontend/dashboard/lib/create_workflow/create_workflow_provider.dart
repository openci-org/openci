import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'create_workflow_provider.freezed.dart';
part 'create_workflow_provider.g.dart';

@riverpod
class CreateWorkflow extends _$CreateWorkflow {
  @override
  CreateWorkflowState build() => CreateWorkflowState(
    isCreated: false,
    selectedRepository: '',
    selectedWorkingDirectory: '/',
    selectedTriggerType: TriggerType.pullRequest,
    selectedTriggerBranch: 'develop',
  );

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
}

enum TriggerType {
  pullRequest,
  push
  ;

  @override
  toString() {
    switch (this) {
      case TriggerType.pullRequest:
        return 'pull_request';
      case TriggerType.push:
        return 'push';
    }
  }

  static TriggerType fromValue(String value) {
    switch (value) {
      case 'pull_request':
        return TriggerType.pullRequest;
      case 'push':
        return TriggerType.push;
      default:
        throw ArgumentError('Invalid TriggerType value: $value');
    }
  }
}

@freezed
abstract class CreateWorkflowState with _$CreateWorkflowState {
  const factory CreateWorkflowState({
    required bool isCreated,
    required String selectedRepository,
    required String selectedWorkingDirectory,
    required TriggerType selectedTriggerType,
    required String selectedTriggerBranch,
  }) = _CreateWorkflowState;

  factory CreateWorkflowState.fromJson(Map<String, Object?> json) =>
      _$CreateWorkflowStateFromJson(json);
}
