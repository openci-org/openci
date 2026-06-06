import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

void main(List<String> args) async {
  final router = Router();

  router.get('/', (Request request) {
    return Response.ok(
      'OpenCI Server (Shelf) is running!\n',
      headers: {'content-type': 'text/plain'},
    );
  });

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router.call);

  final ip = InternetAddress.loopbackIPv4;
  const port = 8080;

  final server = await shelf_io.serve(handler, ip, port);
  stdout.writeln(
    'OpenCI Shelf Server listening on http://${server.address.host}:${server.port}',
  );
}
