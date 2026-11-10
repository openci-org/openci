import 'dart:async';

import 'package:dashboard/app_locale_provider.dart';
import 'package:dashboard/app_strings.dart';
import 'package:dashboard/settings/language_selector.dart';
import 'package:dashboard/utilities/error_message.dart';
import 'package:dashboard/utilities/shared_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<SharedPreferences> preferences([String? language]) async {
    SharedPreferences.setMockInitialValues({
      localePreferenceKey: ?language,
    });
    return SharedPreferences.getInstance();
  }

  Future<void> pump(WidgetTester tester, SharedPreferences prefs) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(320, 700);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: TranslationProvider(child: const _LanguageApp()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> select(WidgetTester tester, String label) async {
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  for (final (device, expected) in [
    (const Locale('ja', 'JP'), AppLocale.ja),
    (const Locale('en', 'GB'), AppLocale.en),
    (const Locale('fr', 'FR'), AppLocale.en),
  ]) {
    testWidgets('uses $expected for device locale $device', (tester) async {
      tester.platformDispatcher.localesTestValue = [device];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      initializeLocale(await preferences());
      expect(LocaleSettings.currentLocale, expected);
    });
  }

  testWidgets('restores a saved choice before showing the application', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = [const Locale('ja')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final prefs = await preferences('en');
    initializeLocale(prefs);
    await pump(tester, prefs);
    expect(find.text('Sign in to your account'), findsOneWidget);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
      const Locale('en'),
    );
  });

  testWidgets('switches live, persists, and resumes following the device', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = [const Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final prefs = await preferences();
    initializeLocale(prefs);
    await pump(tester, prefs);
    expect(find.text('Sign in to your account'), findsOneWidget);

    await select(tester, '日本語');
    expect(find.text('アカウントにサインイン'), findsOneWidget);
    expect(prefs.getString(localePreferenceKey), 'ja');
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
      const Locale('ja'),
    );

    tester.platformDispatcher.localesTestValue = [const Locale('en')];
    await tester.pumpAndSettle();
    expect(find.text('アカウントにサインイン'), findsOneWidget);

    await select(tester, '端末の設定に合わせる');
    expect(find.text('Sign in to your account'), findsOneWidget);
    expect(prefs.containsKey(localePreferenceKey), isFalse);
    tester.platformDispatcher.localesTestValue = [const Locale('ja')];
    await tester.pumpAndSettle();
    expect(find.text('アカウントにサインイン'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the saved selection and reports a persistence failure', (
    tester,
  ) async {
    final prefs = _FailingPreferences();
    initializeLocale(prefs);
    await pump(tester, prefs);
    await select(tester, 'English');
    expect(LocaleSettings.currentLocale, AppLocale.ja);
    expect(
      tester
          .widget<DropdownButton<String>>(find.byType(DropdownButton<String>))
          .value,
      'ja',
    );
    expect(find.text('言語設定を保存できませんでした。もう一度お試しください。'), findsOneWidget);
  });

  testWidgets('uses the latest selection when saves complete out of order', (
    tester,
  ) async {
    final prefs = _DelayedPreferences();
    final container = ProviderContainer.test(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    final controller = container.read(localePreferenceProvider.notifier);
    final first = controller.setLocale(AppLocale.en);
    final second = controller.setLocale(AppLocale.ja);
    prefs.saves[1].complete(true);
    await second;
    prefs.saves[0].complete(true);
    await first;
    expect(container.read(localePreferenceProvider), AppLocale.ja);
    expect(LocaleSettings.currentLocale, AppLocale.ja);
  });

  test('renders stored errors in the language selected at display time', () {
    final error = DashboardException('member_not_registered');
    expect(
      dashboardErrorMessage(error, AppLocale.en.translations),
      'Ask this user to create a Dashboard account first.',
    );
    expect(
      dashboardErrorMessage(error, AppLocale.ja.translations),
      '追加するユーザーは先にDashboardへ登録してください。',
    );
    expect(AppLocale.en.translations.team.membersCount(count: 1), '1 member');
    expect(AppLocale.en.translations.team.membersCount(count: 2), '2 members');
  });
}

class _LanguageApp extends StatelessWidget {
  const _LanguageApp();

  @override
  Widget build(BuildContext context) => MaterialApp(
    locale: TranslationProvider.of(context).flutterLocale,
    supportedLocales: AppLocaleUtils.supportedLocales,
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: Builder(
      builder: (context) => Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(context.t.auth.signInSubtitle),
              const LanguageSelector(),
            ],
          ),
        ),
      ),
    ),
  );
}

class _FailingPreferences extends Fake implements SharedPreferences {
  @override
  String? getString(String key) => 'ja';

  @override
  Future<bool> setString(String key, String value) async => false;
}

class _DelayedPreferences extends Fake implements SharedPreferences {
  final saves = <Completer<bool>>[];

  @override
  String? getString(String key) => null;

  @override
  Future<bool> setString(String key, String value) {
    final result = Completer<bool>();
    saves.add(result);
    return result.future;
  }
}
