import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:openci_server/build_job/build_job_router.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/environment_value/environment_value.dart';
import 'package:openci_server/middleware/apply_middleware.dart';
import 'package:openci_server/team/team_router.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

final routerProvider = Provider<Router>((ref) {
  final router = Router();
  final db = ref.read(databaseProvider);
  final envValue = ref.read(environmentValueProvider);

  router.get('/', (Request request) {
    return Response.ok(
      'OpenCI Server (Shelf) is running!\n',
      headers: {'content-type': 'text/plain'},
    );
  });

  router.mount(
    '/builds',
    BuildJobRouter(
      db: db,
      appEnv: envValue.appEnv,
    ).router.call,
  );

  router.mount(
    '/teams',
    ref.read(teamRouterProvider).router.call,
  );

  return router;
});

final firebaseAppProvider = Provider<FirebaseApp?>((ref) {
  return FirebaseApp.initializeApp();
});

final handlerProvider = Provider<Handler>((ref) {
  final firebaseApp = ref.watch(firebaseAppProvider);
  final router = ref.watch(routerProvider);
  return applyMiddleware(
    router,
    firebaseApp: firebaseApp,
  );
});
