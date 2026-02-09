import 'package:freezed_annotation/freezed_annotation.dart';

part 'workflow_template.freezed.dart';
part 'workflow_template.g.dart';

const workflowTemplateList = [
  WorkflowTemplate(
    name: 'write_your_code',
    title: 'Write your code',
  ),
  WorkflowTemplate(
    name: 'save_secret_file',
    title: 'Save secret file',
  ),
  WorkflowTemplate(
    name: 'react_native_expo_cd_ios',
    title: 'React Native (Expo) CD (iOS)',
  ),
  WorkflowTemplate(
    name: 'react_native_expo_cd_android',
    title: 'React Native (Expo) CD (Android)',
  ),
  WorkflowTemplate(
    name: 'set_version_ios_with_tag',
    title: 'Set Version (iOS) with Tag',
  ),
  WorkflowTemplate(
    name: 'set_version_android_with_tag',
    title: 'Set Version (Android) with Tag',
  ),
];

@freezed
abstract class WorkflowTemplate with _$WorkflowTemplate {
  const factory WorkflowTemplate({
    required String name,
    required String title,
  }) = _WorkflowTemplate;

  factory WorkflowTemplate.fromJson(Map<String, Object?> json) =>
      _$WorkflowTemplateFromJson(json);
}
