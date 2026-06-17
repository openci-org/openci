import 'dart:io';

import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:openci_server/build_job/build_job_router.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/storage.dart';
import 'package:openci_server/team/team_router.dart';
import 'package:shelf_router/shelf_router.dart';

Router getRouter(
  StorageManager storage, {
  required AppDatabase db,
  FirebaseApp? firebaseApp,
  Map<String, String>? environment,
}) {
  final router = Router();
  final env = environment ?? Platform.environment;
  final appEnv = env['APP_ENV'] ?? 'development';

  router.mount(
    '/builds',
    BuildJobRouter(
      db: db,
      appEnv: appEnv,
    ).router.call,
  );

  router.mount(
    '/teams',
    TeamRouter(db: db).router.call,
  );

  return router;
}
