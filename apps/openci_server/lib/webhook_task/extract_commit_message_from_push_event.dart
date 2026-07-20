String? extractCommitMessageFromPushEvent(Map<String, dynamic> payload) {
  String? msg;
  if (payload['head_commit'] != null) {
    msg = payload['head_commit']['message'] as String?;
  } else if (payload['commits'] is List &&
      (payload['commits'] as List).isNotEmpty) {
    msg = (payload['commits'] as List).last['message'] as String?;
  }
  return msg;
}
