import 'dart:convert';

import 'package:dart_frog/dart_frog.dart';

class BadRequestException implements Exception {
  const BadRequestException(this.message);

  final String message;

  @override
  String toString() => message;
}

extension RequestContextJsonExtension on RequestContext {
  Future<Map<String, dynamic>> jsonBody() async {
    try {
      final body = await request.body();
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Body must be a JSON object');
      }
      return decoded;
    } on FormatException catch (e) {
      throw BadRequestException('Invalid JSON format: $e');
    }
  }
}
