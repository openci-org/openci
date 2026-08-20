import 'package:freezed_annotation/freezed_annotation.dart';

import '../utilities/date_time_converter.dart';

part 'webhook_task.freezed.dart';
part 'webhook_task.g.dart';

@freezed
abstract class WebhookTask with _$WebhookTask {
  const factory WebhookTask({
    required String id,
    required String deliveryId,
    required String eventType,
    required String payload,
    @Default('pending') String status,
    @Default(0) int retryCount,
    String? errorMessage,
    @DateTimeConverter() required DateTime createdAt,
    @DateTimeConverter() required DateTime updatedAt,
  }) = _WebhookTask;

  factory WebhookTask.fromJson(Map<String, Object?> json) =>
      _$WebhookTaskFromJson(json);
}
