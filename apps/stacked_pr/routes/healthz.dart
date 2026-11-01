import 'package:dart_frog/dart_frog.dart';

Response onRequest(RequestContext context) {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: 405, headers: {'allow': 'GET'});
  }
  return Response.json(body: {'status': 'ok'}, headers: {'cache-control': 'no-store'});
}
