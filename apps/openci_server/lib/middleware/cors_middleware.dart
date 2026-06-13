import 'package:shelf/shelf.dart';

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS, PATCH',
  'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept, Authorization',
};

Middleware corsMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok(
          '',
          headers: _corsHeaders,
        );
      }

      final response = await innerHandler(request);
      return response.change(
        headers: _corsHeaders,
      );
    };
  };
}
