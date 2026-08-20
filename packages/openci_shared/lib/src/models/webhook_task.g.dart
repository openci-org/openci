// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'webhook_task.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WebhookTask _$WebhookTaskFromJson(Map<String, dynamic> json) => _WebhookTask(
  id: json['id'] as String,
  deliveryId: json['deliveryId'] as String,
  eventType: json['eventType'] as String,
  payload: json['payload'] as String,
  status: json['status'] as String? ?? 'pending',
  retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
  errorMessage: json['errorMessage'] as String?,
  createdAt: const DateTimeConverter().fromJson(json['createdAt'] as Object),
  updatedAt: const DateTimeConverter().fromJson(json['updatedAt'] as Object),
);

Map<String, dynamic> _$WebhookTaskToJson(_WebhookTask instance) =>
    <String, dynamic>{
      'id': instance.id,
      'deliveryId': instance.deliveryId,
      'eventType': instance.eventType,
      'payload': instance.payload,
      'status': instance.status,
      'retryCount': instance.retryCount,
      'errorMessage': instance.errorMessage,
      'createdAt': const DateTimeConverter().toJson(instance.createdAt),
      'updatedAt': const DateTimeConverter().toJson(instance.updatedAt),
    };
