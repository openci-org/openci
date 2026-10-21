import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:openci_server/auth/internal_api_middleware.dart';
import 'package:openci_server/billing/billing_proxy.dart';
import 'package:openci_server/billing/billing_proxy_config.dart';

Handler middleware(Handler handler) {
  final config = BillingProxyConfig.fromEnvironment(Platform.environment);
  final proxy = config == null ? null : BillingProxy(config, http.Client());
  return handler
      .use(provider<BillingProxy?>((_) => proxy))
      .use(internalApiMiddleware());
}
