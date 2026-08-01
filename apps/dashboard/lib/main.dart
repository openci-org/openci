import 'package:dashboard/firebase/firebase_config_provider.dart';
import 'package:dashboard/firebase_options.dart';
import 'package:dashboard/utilities/macos_updater_initializer.dart';
import 'package:dashboard/revenue_cat/revenue_cat.dart';
import 'package:dashboard/root.dart';
import 'package:dashboard/utilities/shared_preferences_provider.dart';
import 'package:dashboard/utilities/sentry_provider_observer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    if (kIsWeb) {
      usePathUrlStrategy();
    }

    var selfHosted = await loadSelfHostedConfig();
    if (!kIsWeb && selfHosted != null && selfHosted.appId.contains(':web:')) {
      selfHosted = selfHosted.copyWith(appId: '1:dummy:ios:dummy');
      await saveSelfHostedConfig(selfHosted);
    }

    final isConfigValid =
        selfHosted != null &&
        selfHosted.apiKey.isNotEmpty &&
        selfHosted.appId.isNotEmpty &&
        selfHosted.projectId.isNotEmpty &&
        !selfHosted.appId.contains('dummy') &&
        (kIsWeb || !selfHosted.appId.contains(':web:'));

    try {
      if (isConfigValid) {
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
      if (e.code != 'duplicate-app') rethrow;
      debugPrint('[OpenCI] Firebase already initialized (hot restart)');
    }

    if (selfHosted == null) {
      await initializeRevenueCat();
    }

    await initializeMacosUpdater();

    final sharedPreferences = await SharedPreferences.getInstance();

    final app = ProviderScope(
      observers: [
        SentryProviderObserver(),
      ],
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: Root(),
    );

    if (kDebugMode) {
      runApp(app);
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = const String.fromEnvironment('SENTRY_DSN');
        options.sendDefaultPii = true;
        options.enableLogs = true;
        options.tracesSampleRate = 1.0;
        // ignore: experimental_member_use
        options.profilesSampleRate = 1.0;
        options.replay.sessionSampleRate = 1.0;
        options.replay.onErrorSampleRate = 1.0;
        options.attachScreenshot = true;
        options.privacy.maskAllText = false;
        options.privacy.maskAllImages = false;
      },
      appRunner: () => runApp(
        SentryWidget(
          child: app,
        ),
      ),
    );
  } catch (e, s) {
    debugPrint('[OpenCI] CRITICAL INITIALIZATION ERROR: $e');
    debugPrintStack(stackTrace: s);
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SelectableText(
                'Initialization failed:\n$e\n\n$s',
                style: const TextStyle(
                  color: Colors.red,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
