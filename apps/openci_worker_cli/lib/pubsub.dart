import 'dart:convert';
import 'dart:io';

import 'package:googleapis/pubsub/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:logging/logging.dart';

final _log = Logger('PubSub');

typedef PubSubMessage = ({String buildJobId, String ackId});

Future<PubsubApi> initPubSub(String serviceAccountPath) async {
  final json = jsonDecode(File(serviceAccountPath).readAsStringSync())
      as Map<String, dynamic>;
  final credentials = ServiceAccountCredentials.fromJson(json);
  final client = await clientViaServiceAccount(
    credentials,
    [PubsubApi.pubsubScope],
  );
  _log.info('Pub/Sub client initialized');
  return PubsubApi(client);
}

Future<PubSubMessage?> pullMessage(
  PubsubApi pubsub,
  String subscription,
) async {
  final response = await pubsub.projects.subscriptions.pull(
    PullRequest(maxMessages: 1),
    subscription,
  );

  final messages = response.receivedMessages;
  if (messages == null || messages.isEmpty) return null;

  final msg = messages.first;
  final data = msg.message?.data;
  final ackId = msg.ackId;
  if (data == null || ackId == null) return null;

  return (buildJobId: utf8.decode(base64Decode(data)), ackId: ackId);
}

Future<void> acknowledge(
  PubsubApi pubsub,
  String subscription,
  String ackId,
) async {
  await pubsub.projects.subscriptions.acknowledge(
    AcknowledgeRequest(ackIds: [ackId]),
    subscription,
  );
}
