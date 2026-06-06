import 'package:openci_server/middleware.dart';
import 'package:openci_server/router.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  group('Server API Tests', () {
    late Handler handler;

    setUp(() {
      handler = applyMiddleware(router);
    });

    test('GET / returns 200 and welcome message', () async {
      final request = Request('GET', Uri.parse('http://localhost/'));
      final response = await handler(request);

      expect(response.statusCode, equals(200));
      expect(await response.readAsString(), contains('OpenCI Server (Shelf) is running!'));
    });
  });
}
