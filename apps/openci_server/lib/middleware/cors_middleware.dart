import 'dart:io';

import 'package:shelf/shelf.dart';

Middleware corsMiddleware({Map<String, String>? environment}) {
  final env = environment ?? Platform.environment;
  final origins = env['ALLOWED_ORIGINS'] ?? '';
  final list = origins
      .split(',')
      .map((o) => o.trim().replaceAll(RegExp(r'/$'), ''))
      .where((o) => o.isNotEmpty)
      .toList();
  final allowedOrigins = {
    'https://dashboard.openci.org',
    ...list,
  };

  bool isAllowed(String origin) {
    final sanitized = origin.trim().replaceAll(RegExp(r'/$'), '');
    if (allowedOrigins.contains(sanitized)) {
      return true;
    }
    try {
      final uri = Uri.parse(sanitized);
      return uri.host == 'localhost' || uri.host == '127.0.0.1';
    } catch (_) {
      return false;
    }
  }

  return (Handler innerHandler) {
    return (Request request) async {
      final origin = request.headers['origin'] ?? request.headers['Origin'];

      if (origin == null || !isAllowed(origin)) {
        return innerHandler(request);
      }

      final corsHeaders = {
        'Access-Control-Allow-Origin': origin,
        'Access-Control-Allow-Methods':
            'GET, POST, PUT, DELETE, OPTIONS, PATCH',
        'Access-Control-Allow-Headers':
            'Origin, Content-Type, Accept, Authorization',
        'Access-Control-Allow-Credentials': 'true',
      };

      if (request.method == 'OPTIONS') {
        return Response.ok(
          '',
          headers: corsHeaders,
        );
      }

      final response = await innerHandler(request);
      return response.change(
        headers: corsHeaders,
      );
    };
  };
}
