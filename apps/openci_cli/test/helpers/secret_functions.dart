import 'dart:convert';

import 'package:http/http.dart' as http;

const secretFunctionUrl =
    'https://asia-northeast1-test-project.cloudfunctions.net/teamSecrets';

Map<String, dynamic> secretData(http.Request request) =>
    (jsonDecode(request.body) as Map<String, dynamic>)['data']
        as Map<String, dynamic>;

String secretAction(http.Request request) =>
    request.url.path.endsWith('/teamSecrets')
    ? secretData(request)['action'] as String
    : 'refresh';

// Command tests specify the callable result. Authentication refresh responses
// retain their own wire format.
http.Response functionResponse(
  String body,
  int status, {
  Map<String, String>? headers,
}) {
  Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException {
    return http.Response(body, status, headers: headers ?? {});
  }
  final auth = decoded is Map && decoded.containsKey('id_token');
  return http.Response(
    auth ? body : jsonEncode({'result': decoded}),
    status,
    headers: headers ?? {'content-type': 'application/json'},
  );
}
