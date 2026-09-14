import 'package:freezed_annotation/freezed_annotation.dart';

import '../build_step.dart';

part 'step_event.freezed.dart';
part 'step_event.g.dart';

@freezed
abstract class StepEvent with _$StepEvent {
  // ignore: invalid_annotation_target
  @JsonSerializable(explicitToJson: true)
  const factory StepEvent({
    required BuildStep step,
  }) = _StepEvent;

  factory StepEvent.fromJson(Map<String, Object?> json) =>
      _$StepEventFromJson(json);
}
