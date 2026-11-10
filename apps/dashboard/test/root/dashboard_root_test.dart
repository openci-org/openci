import 'package:checks/checks.dart';
import 'package:dashboard/app_strings.dart';
import 'package:dashboard/cicd_log/cicd_log_providers.dart';
import 'package:dashboard/root/dashboard_root.dart';
import 'package:dashboard/secret_manager/secret_manager_provider.dart';
import 'package:dashboard/settings/language_selector.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:dashboard/utilities/shared_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../finder_checks.dart';

class _EmptyCommitGroups extends CicdCommitGroups {
  @override
  Stream<List<CicdCommitGroup>> build() => Stream.value(const []);
}

class _EmptySecrets extends SecretManager {
  @override
  Stream<List<Secret>> build() => Stream.value(const []);
}

void main() {
  for (final width in [390.0, 900.0]) {
    testWidgets('switches between remaining tabs at width $width', (
      tester,
    ) async {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = Size(width, 900);
      addTearDown(tester.view.reset);
      PackageInfo.setMockInitialValues(
        appName: 'OpenCI',
        packageName: 'org.openci.dashboard',
        version: '2.0.0',
        buildNumber: '1',
        buildSignature: '',
      );
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        TranslationProvider(
          child: ProviderScope(
            overrides: [
              sharedPreferencesProvider.overrideWithValue(prefs),
              cicdCommitGroupsProvider.overrideWith(_EmptyCommitGroups.new),
              secretManagerProvider.overrideWith(_EmptySecrets.new),
              selectedTeamProvider.overrideWith(
                (ref) async => Team(
                  id: 'team-123',
                  name: 'Test team',
                  members: const ['user-123'],
                  createdAt: DateTime.utc(2026),
                  updatedAt: DateTime.utc(2026),
                ),
              ),
            ],
            child: const MaterialApp(home: DashboardRoot()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      check(find.text('ストアリリース')).findsNothing();
      check(find.text('アクティブなCI/CDログはありません')).findsOneWidget();

      final navigation = find.byType(NavigationBar);
      check(
        tester.widget<NavigationBar>(navigation).destinations.length,
      ).equals(3);

      await tester.tap(
        find.descendant(of: navigation, matching: find.text('シークレット')),
      );
      await tester.pumpAndSettle();
      check(find.text(t.secrets.noSecrets)).findsOneWidget();
      check(find.text(t.secrets.codeSigningTitle)).findsOneWidget();

      await tester.tap(
        find.descendant(of: navigation, matching: find.text('設定')),
      );
      await tester.pumpAndSettle();
      check(find.text('Test team')).findsOneWidget();
      check(find.text(t.settings.logout)).findsOneWidget();

      await tester.ensureVisible(find.byType(LanguageSelector));
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English').last);
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsWidgets);
      check(find.text('Sign out')).findsOneWidget();
      check(prefs.getString('dashboard_language')).equals('en');

      await tester.tap(
        find.descendant(of: navigation, matching: find.text('CI/CD logs')),
      );
      await tester.pumpAndSettle();
      check(find.text('No active CI/CD logs')).findsOneWidget();
      check(tester.takeException()).isNull();
    });
  }
}
