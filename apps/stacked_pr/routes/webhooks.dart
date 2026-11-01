import 'package:dart_frog/dart_frog.dart';
import 'package:stacked_pr_app/src/webhook.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: 405, headers: {'allow': 'POST'});
  }
  return context.read<WebhookReceiver>().accept(context.request);
}
