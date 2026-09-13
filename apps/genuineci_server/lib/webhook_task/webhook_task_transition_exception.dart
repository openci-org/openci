class WebhookTaskNotFoundException implements Exception {
  const WebhookTaskNotFoundException();
}

class InvalidWebhookTaskStatusException implements Exception {
  const InvalidWebhookTaskStatusException(this.status);

  final String status;
}
