import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/billing/billing_proxy.dart';
import 'package:openci_server/billing/worker_billing_route.dart';

Future<Response> onRequest(RequestContext context) =>
    workerBillingRoute(context, WorkerBillingOperation.report);
