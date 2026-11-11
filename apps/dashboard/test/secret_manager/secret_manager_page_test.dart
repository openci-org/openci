import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/app_strings.dart';
import 'package:dashboard/secret_manager/secret_manager_page.dart';
import 'package:dashboard/secret_manager/secret_manager_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final locale in AppLocale.values) {
    testWidgets('retries saving a secret in ${locale.languageCode}', (
      tester,
    ) async {
      final strings = locale.translations;
      final secrets = _Secrets();
      await _pumpPage(tester, locale, secrets);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      final submit = find.widgetWithText(
        FilledButton,
        strings.secrets.addSecret,
      );
      await _submit(tester, submit);
      expect(find.text(strings.secrets.enterSecretName), findsOneWidget);
      expect(find.text(strings.secrets.enterSecretValue), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'SSH_KEY');
      await tester.tap(find.text(strings.secrets.inputModeFile));
      await tester.pumpAndSettle();
      await _submit(tester, submit);
      expect(
        _formMessage(strings.secrets.enterValueOrUpload),
        findsOneWidget,
      );
      await tester.tap(find.text(strings.secrets.inputModeText));
      await tester.pumpAndSettle();
      expect(_formMessage(strings.secrets.enterValueOrUpload), findsNothing);

      final valueField = find.byType(TextFormField).last;
      await tester.enterText(valueField, 'test-value');
      secrets.failSave = true;
      await _submit(tester, submit);
      expect(_formMessage(strings.common.networkFailed), findsOneWidget);
      expect(
        tester.widget<TextFormField>(valueField).controller!.text,
        'test-value',
      );
      secrets.failSave = false;
      await _submit(tester, submit);
      expect(find.text('SSH_KEY'), findsOneWidget);
      expect(find.text(strings.secrets.addedSuccess), findsOneWidget);

      await tester.tap(find.byTooltip(strings.common.delete));
      await tester.pumpAndSettle();
      expect(find.text(strings.secrets.deleteConfirm), findsOneWidget);
      await tester.tap(
        find.widgetWithText(FilledButton, strings.common.delete),
      );
      await tester.pumpAndSettle();
      expect(find.text('SSH_KEY'), findsNothing);
      expect(find.text(strings.secrets.deletedSuccess), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('keeps edits in the form after an update failure and retries', (
    tester,
  ) async {
    const locale = AppLocale.en;
    final strings = locale.translations;
    final secrets = _Secrets();
    await _pumpPage(tester, locale, secrets);
    await secrets.addSecret('OLD_NAME', 'old-value');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(strings.secrets.editSecret));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'NEW_NAME');
    final valueField = find.byType(TextFormField).last;
    await tester.enterText(valueField, 'new-value');
    final save = find.widgetWithText(TextButton, strings.common.save);

    secrets.failSave = true;
    await _submit(tester, save);
    expect(_formMessage(strings.common.networkFailed), findsOneWidget);
    expect(
      tester.widget<TextFormField>(valueField).controller!.text,
      'new-value',
    );
    secrets.failSave = false;
    await _submit(tester, save);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('NEW_NAME'), findsOneWidget);
    expect(find.text(strings.secrets.updatedSuccess), findsOneWidget);
  });
}

Finder _formMessage(String message) =>
    find.descendant(of: find.byType(Form), matching: find.text(message));

Future<void> _submit(WidgetTester tester, Finder button) async {
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _pumpPage(
  WidgetTester tester,
  AppLocale locale,
  _Secrets secrets,
) async {
  LocaleSettings.setLocaleSync(locale);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [secretManagerProvider.overrideWith(() => secrets)],
      child: TranslationProvider(
        child: MaterialApp(
          locale: locale.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const SecretManagerPage(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _Secrets extends SecretManager {
  bool failSave = false;

  @override
  Stream<List<Secret>> build() => Stream.value(const []);

  @override
  Future<void> addSecret(String name, String value) async => _save(name);

  @override
  Future<void> updateSecret({
    required String documentId,
    required String name,
    String? value,
  }) async => _save(name);

  void _save(String name) {
    if (failSave) {
      throw FirebaseFunctionsException(code: 'unavailable', message: 'Offline');
    }
    state = AsyncData([
      Secret(
        id: name,
        name: name,
        teamId: 'team',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    ]);
  }

  @override
  Future<void> deleteSecret({required String documentId}) async {
    state = const AsyncData([]);
  }
}
