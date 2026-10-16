import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:meta/meta.dart';
import 'package:openci_server/auth/server_access_policy.dart';

Middleware serverAccessPolicyProvider({
  @visibleForTesting Map<String, String>? environment,
}) {
  final policy = ServerAccessPolicy.fromEnvironment(
    environment ?? Platform.environment,
  );
  return provider<ServerAccessPolicy>((context) => policy);
}
