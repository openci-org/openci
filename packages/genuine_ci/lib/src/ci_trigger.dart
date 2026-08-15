import 'package:freezed_annotation/freezed_annotation.dart';

part 'ci_trigger.freezed.dart';

@freezed
abstract class CiTrigger with _$CiTrigger {
  const factory CiTrigger.push({
    required String branch,
  }) = _PushCiTrigger;

  const factory CiTrigger.pullRequest({
    required String branch,
  }) = _PullRequestCiTrigger;
}

typedef CITrigger = CiTrigger;
