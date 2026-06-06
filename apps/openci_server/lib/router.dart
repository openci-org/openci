import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Router get router {
  final router = Router();

  router.get('/', (Request request) {
    return Response.ok(
      'OpenCI Server (Shelf) is running!\n',
      headers: {'content-type': 'text/plain'},
    );
  });

  return router;
}
