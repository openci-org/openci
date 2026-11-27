@TestOn('mac-os && vm')
library;

import 'dart:io';

import 'package:alchemist/alchemist.dart';
import 'package:dashboard/app_strings.dart';
import 'package:dashboard/auth/auth_page.dart';
import 'package:dashboard/connections/connection_profile.dart';
import 'package:dashboard/connections/connection_store.dart';
import 'package:dashboard/connections/connection_store_provider.dart';
import 'package:dashboard/connections/local_development_connection.dart';
import 'package:dashboard/utilities/shared_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _fontFamily = 'Dashboard Golden Hiragino Sans';

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final loader = FontLoader(_fontFamily);
    for (final weight in [3, 6]) {
      final font = File('/System/Library/Fonts/ヒラギノ角ゴシック W$weight.ttc');
      loader.addFont(font.readAsBytes().then(ByteData.sublistView));
    }
    await loader.load();
  });

  late ConnectionStore store;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    store = ConnectionStore(
      prefs,
      const ConnectionProfile(
        id: 'cloud',
        name: 'Cloud',
        apiUrl: 'https://example.com',
        firebase: {},
      ),
    );
  });

  await AlchemistConfig.runWithConfig(
    config: const AlchemistConfig(
      platformGoldensConfig: PlatformGoldensConfig(enabled: false),
      ciGoldensConfig: CiGoldensConfig(obscureText: false),
    ),
    run: () => goldenTest(
      'renders the Japanese login page',
      fileName: 'login',
      constraints: const BoxConstraints.tightFor(width: 960, height: 920),
      pumpBeforeTest: (tester) async {
        await tester.pumpAndSettle();
        expect(find.text(t.auth.login), findsOneWidget);
      },
      builder: () => TranslationProvider(
        child: ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(store.prefs),
            connectionStoreProvider.overrideWithValue(store),
            localDevelopmentConnectionProvider.overrideWithValue(null),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: AppLocale.ja.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: ThemeData(fontFamily: _fontFamily),
            home: const AuthPage(),
          ),
        ),
      ),
    ),
  );
}
