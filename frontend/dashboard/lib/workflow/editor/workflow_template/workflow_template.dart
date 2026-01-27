import 'package:freezed_annotation/freezed_annotation.dart';

part 'workflow_template.freezed.dart';
part 'workflow_template.g.dart';

const workflowTemplateList = [
  WorkflowTemplate(
    name: 'write_your_code',
    title: 'Write your code',
  ),
  WorkflowTemplate(
    name: 'react_native_cd_ios',
    title: 'React Native CD (iOS)',
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
