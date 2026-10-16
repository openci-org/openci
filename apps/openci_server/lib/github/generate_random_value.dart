import 'dart:convert';
import 'dart:math';

import 'package:meta/meta.dart';

String generateRandomValue({@visibleForTesting Random? random}) {
  final generator = random ?? Random.secure();
  final bytes = List<int>.generate(32, (_) => generator.nextInt(256));
  return base64UrlEncode(bytes).replaceAll('=', '');
}
