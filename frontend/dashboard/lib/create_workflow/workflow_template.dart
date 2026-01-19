import 'package:freezed_annotation/freezed_annotation.dart';

part 'workflow_template.freezed.dart';
part 'workflow_template.g.dart';

const workflowTemplateList = [
  WorkflowTemplate(
    name: 'create_your_own_workflow',
    title: 'Create your own workflow',
  ),
  WorkflowTemplate(
    name: 'flutter_ci_cd',
    title: 'Flutter CI/CD',
  ),
  WorkflowTemplate(
    name: 'slack_notification',
    title: 'Slack Notification',
  ),
  WorkflowTemplate(
    name: 'email_notification',
    title: 'Email Notification',
  ),
  WorkflowTemplate(
    name: 'firebase_ci_cd',
    title: 'Firebase CI/CD',
  ),
  WorkflowTemplate(
    name: 'docker_ci_cd',
    title: 'Docker CI/CD',
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
