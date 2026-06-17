import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:test/test.dart';

import '../../routes/index.dart' as route;

void main() {
  group('GET /', () {
    test('responds with a 200 and "OpenCI Server (Shelf) is running!".', () {
      final context = TestRequestContext(
        path: '/',
      );
      final response = route.onRequest(context.context);
      expect(response, isOk);
      expect(response.statusCode, equals(200));
      expect(
        response.body(),
        completion(equals('OpenCI Server (Shelf) is running!')),
      );
    });
  });
}
