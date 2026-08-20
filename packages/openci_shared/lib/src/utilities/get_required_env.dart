import 'dart:io';

String getRequiredEnv(
  String key, {
  Map<String, String>? environment,
}) {
  final env = environment ?? Platform.environment;
  final value = env[key];
  if (value == null || value.isEmpty) {
    throw StateError('Required environment variable $key is not set.');
  }
  return value;
}
