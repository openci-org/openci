import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Handler applyMiddleware(Router router) {
  return const Pipeline().addMiddleware(logRequests()).addHandler(router.call);
}
