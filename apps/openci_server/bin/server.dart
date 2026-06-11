import 'dart:io';

import 'package:firebase_admin_sdk/firebase_admin_sdk.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/middleware.dart';
import 'package:openci_server/router.dart';
import 'package:openci_server/settings/server_settings.dart';
import 'package:openci_server/settings/storage_settings.dart';
import 'package:openci_server/storage.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

void main(List<String> args) async {
  AppDatabase db;
  try {
    db = AppDatabase();
  } catch (e) {
    stderr.writeln('Failed to initialize database connection: $e');
    exit(1);
  }

  ({InternetAddress ip, int port}) serverSettings;
  try {
    serverSettings = loadServerSettings();
  } catch (e) {
    stderr.writeln('Error loading server settings: $e');
    await db.close();
    exit(1);
  }

  StorageSettings storageSettings;
  try {
    storageSettings = loadStorageSettings();
  } catch (e) {
    stderr.writeln('Error loading storage settings: $e');
    await db.close();
    exit(1);
  }

  StorageManager storage;
  try {
    storage = StorageManager(storageSettings);
    await storage.initialize();
  } catch (e) {
    stderr.writeln('Failed to initialize storage connection: $e');
    await db.close();
    exit(1);
  }

  FirebaseApp firebaseApp;
  try {
    firebaseApp = FirebaseApp.initializeApp();
  } catch (e) {
    stderr.writeln('Failed to initialize Firebase App: $e');
    await db.close();
    exit(1);
  }

  final handler = applyMiddleware(
    getRouter(storage, db: db, firebaseApp: firebaseApp),
    firebaseApp: firebaseApp,
  );

  HttpServer server;
  try {
    server = await shelf_io.serve(
      handler,
      serverSettings.ip,
      serverSettings.port,
    );
  } catch (e) {
    stderr.writeln('Failed to start server: $e');
    await db.close();
    exit(1);
  }
  stdout.writeln(
    'OpenCI Shelf Server listening on http://${server.address.host}:${server.port}',
  );
}
