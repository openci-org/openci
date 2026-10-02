import 'package:freezed_annotation/freezed_annotation.dart';

part 'ci_trigger.freezed.dart';

@freezed
abstract class CITrigger with _$CITrigger {
  const factory CITrigger.push({
    required String branch,
    List<String>? whenChanged,
  }) = _PushCITrigger;

  const factory CITrigger.pullRequest({
    required String branch,
    List<String>? whenChanged,
  }) = _PullRequestCITrigger;
}
