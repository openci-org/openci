import 'package:dashboard/dataconnect_generated/generated.dart';
import 'package:dashboard/firebase_options.dart';
import 'package:dashboard/revenue_cat/revenue_cat.dart';
import 'package:dashboard/root.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseDataConnect.instanceFor(
      connectorConfig: DashboardConnector.connectorConfig,
      sdkType: CallerSDKType.generated,
    ).useDataConnectEmulator('localhost', 9399);
  }

  await initializeRevenueCat();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(
    ProviderScope(
      child: Root(),
    ),
  );
}
