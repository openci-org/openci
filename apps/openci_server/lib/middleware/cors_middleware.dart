import 'package:shelf/shelf.dart';

Middleware corsMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final origin = request.headers['origin'] ?? request.headers['Origin'];

      if (origin == null) {
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
