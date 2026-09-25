import 'dart:async';
import 'dart:convert';

import 'package:dashboard/app_strings.dart';
import 'package:dashboard/auth/auth_page.dart';
import 'package:dashboard/connections/connection_profile.dart';
import 'package:dashboard/connections/connection_snapshot.dart';
import 'package:dashboard/connections/connection_store.dart';
import 'package:dashboard/connections/connection_store_provider.dart';
import 'package:dashboard/firebase/firebase_config_provider.dart';
import 'package:dashboard/utilities/shared_preferences_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final formT = t.auth.firebaseForm;
  const pickerChannel = MethodChannel('miguelruivo.flutter.plugins.filepicker');
  const platform = kIsWeb ? 'web' : 'macos';
  const config = SelfHostedConfig(
    apiKey: 'client-api-key',
    appId: kIsWeb ? '1:123:web:abcdef' : '1:123:ios:abcdef',
    messagingSenderId: '123',
    projectId: 'company-project',
  );
  const cloud = ConnectionProfile(
    id: 'cloud',
    name: 'Cloud',
    apiUrl: 'https://cloud.example.com',
    firebase: {},
  );
  const existing = ConnectionProfile(
    id: 'existing',
    name: 'Existing',
    apiUrl: 'https://existing.example.com',
    firebase: {platform: config},
  );
  late SharedPreferences prefs;
  late ConnectionStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    store = ConnectionStore(prefs, cloud);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pickerChannel, null);
  });

  Finder field(String label) => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label,
  );
  final saveButton = find.widgetWithText(FilledButton, formT.pickConfig);

  Future<void> pumpForm(WidgetTester tester) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(900, 1000);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          connectionStoreProvider.overrideWithValue(store),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const FirebaseFormSheet(),
                ),
                child: const Text('Open form'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open form'));
    await tester.pumpAndSettle();
  }

  Future<void> fillForm(
    WidgetTester tester, {
    String name = 'Company',
    String apiUrl = 'https://ci.example.com',
    String apiKey = 'client-api-key',
    String appId = kIsWeb ? '1:123:web:abcdef' : '1:123:ios:abcdef',
    String projectId = 'company-project',
  }) async {
    await tester.enterText(field(formT.profileName), name);
    await tester.enterText(field(formT.apiUrl), apiUrl);
    await tester.enterText(field(formT.apiKey), apiKey);
    await tester.enterText(field(formT.appId), appId);
    await tester.enterText(field(formT.projectId), projectId);
  }

  Future<void> importFile(
    WidgetTester tester,
    String name,
    String content,
  ) async {
    final bytes = Uint8List.fromList(utf8.encode(content));
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      pickerChannel,
      (_) async => [
        {'name': name, 'size': bytes.length, 'bytes': bytes},
      ],
    );
    await tester.ensureVisible(find.text(formT.importFile));
    await tester.tap(find.text(formT.importFile));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'saves and reloads a named API and Firebase profile',
    (
      tester,
    ) async {
      await pumpForm(tester);
      await fillForm(
        tester,
        name: ' Company ',
        apiUrl: ' https://ci.example.com ',
      );

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      final reloaded = ConnectionStore(prefs, cloud).load().profiles.last;
      expect(
        reloaded.copyWith(id: 'saved'),
        const ConnectionProfile(
          id: 'saved',
          name: 'Company',
          apiUrl: 'https://ci.example.com',
          firebase: {platform: config},
        ),
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'keeps the selected connection when saving another profile',
    (
      tester,
    ) async {
      await store.save(
        const ConnectionSnapshot(
          profiles: [cloud, existing],
          activeId: 'existing',
        ),
      );
      await pumpForm(tester);
      await fillForm(tester);

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(store.load().activeId, 'existing');
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'uses a new profile ID for changed Firebase settings',
    (
      tester,
    ) async {
      await store.save(
        const ConnectionSnapshot(
          profiles: [cloud, existing],
          activeId: 'cloud',
        ),
      );
      await pumpForm(tester);
      await fillForm(
        tester,
        appId: kIsWeb ? '1:123:web:fedcba' : '1:123:ios:fedcba',
      );

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(
        store.load().profiles.map((profile) => profile.id).toSet(),
        hasLength(3),
      );
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'rejects a blank connection name',
    (tester) async {
      await pumpForm(tester);
      await fillForm(tester, name: '   ');

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(store.load().profiles, [cloud]);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'rejects a missing API URL',
    (tester) async {
      await pumpForm(tester);
      await fillForm(tester, apiUrl: '');

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(store.load().profiles, [cloud]);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'rejects a URL without an HTTP or HTTPS scheme',
    (tester) async {
      await pumpForm(tester);
      await fillForm(tester, apiUrl: 'ci.example.com');

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(store.load().profiles, [cloud]);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'rejects incomplete Firebase settings',
    (tester) async {
      await pumpForm(tester);
      await fillForm(tester, apiKey: '   ');

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(store.load().profiles, [cloud]);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'rejects an App ID for a different platform',
    (tester) async {
      await pumpForm(tester);
      await fillForm(
        tester,
        appId: kIsWeb ? '1:123:ios:abcdef' : '1:123:web:abcdef',
      );

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(store.load().profiles, [cloud]);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'rejects a malformed App ID',
    (tester) async {
      await pumpForm(tester);
      await fillForm(tester, appId: 'invalid:ios:app');

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(store.load().profiles, [cloud]);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'preserves additional options imported from JSON',
    (
      tester,
    ) async {
      final imported = config.copyWith(
        authDomain: 'company-project.firebaseapp.com',
        storageBucket: 'company-project.firebasestorage.app',
        iosBundleId: 'org.example.dashboard',
        iosClientId: 'ios-client',
        androidClientId: 'android-client',
        databaseURL: 'https://company-project.firebaseio.com',
        measurementId: 'G-COMPANY',
      );
      await pumpForm(tester);
      await fillForm(tester);
      await importFile(tester, 'firebase.json', jsonEncode(imported.toJson()));

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(store.load().profiles.last.firebase[platform], imported);
    },
    skip: kIsWeb,
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'preserves additional options imported from plist',
    (
      tester,
    ) async {
      await pumpForm(tester);
      await fillForm(tester);
      await importFile(tester, 'GoogleService-Info.plist', '''
<plist><dict>
  <key>API_KEY</key><string>client-api-key</string>
  <key>GOOGLE_APP_ID</key><string>1:123:ios:abcdef</string>
  <key>GCM_SENDER_ID</key><string>123</string>
  <key>PROJECT_ID</key><string>company-project</string>
  <key>STORAGE_BUCKET</key><string>company-project.firebasestorage.app</string>
  <key>BUNDLE_ID</key><string>org.example.dashboard</string>
  <key>CLIENT_ID</key><string>ios-client</string>
  <key>ANDROID_CLIENT_ID</key><string>android-client</string>
  <key>DATABASE_URL</key><string>https://company-project.firebaseio.com</string>
</dict></plist>
''');

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(
        store.load().profiles.last.firebase[platform],
        config.copyWith(
          storageBucket: 'company-project.firebasestorage.app',
          iosBundleId: 'org.example.dashboard',
          iosClientId: 'ios-client',
          androidClientId: 'android-client',
          databaseURL: 'https://company-project.firebaseio.com',
        ),
      );
    },
    skip: kIsWeb,
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'saves iOS settings under the iOS platform key',
    (tester) async {
      await pumpForm(tester);
      await fillForm(tester);

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(store.load().profiles.last.firebase, {'ios': config});
    },
    skip: kIsWeb,
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets(
    'saves Android settings under the Android platform key',
    (
      tester,
    ) async {
      await pumpForm(tester);
      await fillForm(tester, appId: '1:123:android:abcdef');

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(
        store.load().profiles.last.firebase,
        {'android': config.copyWith(appId: '1:123:android:abcdef')},
      );
    },
    skip: kIsWeb,
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'shows a persistence error when saving fails',
    (tester) async {
      store = _FailingConnectionStore(prefs, cloud);
      await pumpForm(tester);
      await fillForm(tester);

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('Unable to save profile'), findsOneWidget);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'ignores duplicate save clicks while saving',
    (tester) async {
      final delayedStore = _DelayedConnectionStore(prefs, cloud);
      store = delayedStore;
      await pumpForm(tester);
      await fillForm(tester);

      await tester.tap(saveButton);
      await tester.tap(saveButton);
      await tester.pump();

      expect(delayedStore.saveCount, 1);
      delayedStore.release.complete();
      await tester.pumpAndSettle();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );
}

class _FailingConnectionStore extends ConnectionStore {
  _FailingConnectionStore(super.prefs, super.cloud);

  @override
  Future<void> save(ConnectionSnapshot snapshot) async {
    throw StateError('Unable to save profile');
  }
}

class _DelayedConnectionStore extends ConnectionStore {
  _DelayedConnectionStore(super.prefs, super.cloud);

  final release = Completer<void>();
  var saveCount = 0;

  @override
  Future<void> save(ConnectionSnapshot snapshot) async {
    saveCount++;
    await release.future;
    await super.save(snapshot);
  }
}
