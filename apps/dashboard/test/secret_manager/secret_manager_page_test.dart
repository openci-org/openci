import 'package:dashboard/app_strings.dart';
import 'package:dashboard/secret_manager/secret_manager_page.dart';
import 'package:dashboard/secret_manager/secret_manager_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final locale in AppLocale.values) {
    testWidgets('adds and deletes a secret in ${locale.languageCode}', (
      tester,
    ) async {
      LocaleSettings.setLocaleSync(locale);
      final strings = locale.translations;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [secretManagerProvider.overrideWith(_Secrets.new)],
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
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      final submit = find.widgetWithText(
        FilledButton,
        strings.secrets.addSecret,
      );
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.text(strings.secrets.enterSecretName), findsOneWidget);
      expect(find.text(strings.secrets.enterSecretValue), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'SSH_KEY');
      await tester.enterText(find.byType(TextFormField).at(1), 'test-value');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
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
}

class _Secrets extends SecretManager {
  @override
  Stream<List<Secret>> build() => Stream.value(const []);

  @override
  Future<void> addSecret(String name, String value) async {
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
