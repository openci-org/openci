import 'package:dashboard/firebase/dart_function_urls.dart';
import 'package:dashboard/firebase/firebase_config_provider.dart';
import 'package:dashboard/firebase_options.dart';
import 'package:dashboard/i18n/strings.g.dart';
import 'package:dashboard/revenue_cat/revenue_cat.dart';
import 'package:dashboard/root.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final selfHosted = await loadSelfHostedConfig();
  if (selfHosted != null) {
    await Firebase.initializeApp(options: selfHosted.toFirebaseOptions());
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  await LocaleSettings.useDeviceLocale();

  final selfHosted = await loadSelfHostedConfig();

  // Initialize Firebase. GoogleService-Info.plist is intentionally removed
  // from the macOS bundle so that Dart always controls which project is used.
  try {
    if (selfHosted != null) {
      debugPrint(
        '[OpenCI] Using self-hosted Firebase: ${selfHosted.projectId}',
      );
      await Firebase.initializeApp(options: selfHosted.toFirebaseOptions());
    } else {
      debugPrint('[OpenCI] Using default Firebase config');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } on FirebaseException catch (e) {
    // Ignore duplicate-app on hot restart.
    if (e.code != 'duplicate-app') rethrow;
    debugPrint('[OpenCI] Firebase already initialized (hot restart)');
  }

  initDartFunctionUrls(selfHosted);

  if (selfHosted == null) {
    await initializeRevenueCat();
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(
    TranslationProvider(
      child: ProviderScope(child: Root()),
    ),
  );
}
