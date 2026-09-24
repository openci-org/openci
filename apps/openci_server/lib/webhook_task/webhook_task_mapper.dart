import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';

extension DriftWebhookTaskMapper on DriftWebhookTask {
  WebhookTask toShared() {
    return WebhookTask(
      id: id,
      deliveryId: deliveryId,
      eventType: eventType,
      payload: payload,
      status: status,
      retryCount: retryCount,
      errorMessage: errorMessage,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension WebhookTaskMapper on WebhookTask {
  DriftWebhookTask toDrift() {
    return DriftWebhookTask(
      id: id,
      deliveryId: deliveryId,
      eventType: eventType,
      payload: payload,
      status: status,
      retryCount: retryCount,
      errorMessage: errorMessage,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
