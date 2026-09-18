import 'dart:async';
import 'dart:convert';

import 'package:dashboard/app_strings.dart';
import 'package:dashboard/auth/self_hosted_setup_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final formT = t.auth.firebaseForm;
  const pickerChannel = MethodChannel('miguelruivo.flutter.plugins.filepicker');
  const privateKey = 'synthetic-private-key-must-not-appear';

  Map<String, String> account([String projectId = 'example-project']) => {
    'type': 'service_account',
    'project_id': projectId,
    'client_email': 'setup@$projectId.iam.gserviceaccount.com',
    'private_key': privateKey,
  };

  Finder field(String label) => find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label,
  );
  final reviewButton = find.widgetWithText(FilledButton, formT.reviewSetup);

  Future<void> pumpForm(
    WidgetTester tester, {
    Size size = const Size(900, 900),
    double textScale = 1,
  }) async {
    SharedPreferences.setMockInitialValues({});
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final action = await showSelfHostedSetup(context);
                if (context.mounted && action != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(action.name)),
                  );
                }
              },
              child: const Text('Open setup'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open setup'));
    await tester.pumpAndSettle();
  }

  void mockFile(WidgetTester tester, String contents) {
    final bytes = Uint8List.fromList(utf8.encode(contents));
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      pickerChannel,
      (_) async => [
        {'name': 'service-account.json', 'size': bytes.length, 'bytes': bytes},
      ],
    );
  }

  Future<void> selectFile(WidgetTester tester) async {
    final button = find.byIcon(Icons.upload_file_outlined);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('reviews metadata without connecting or saving credentials', (
    tester,
  ) async {
    await pumpForm(tester);
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text(formT.setupPreview), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    mockFile(tester, jsonEncode(account()));
    await selectFile(tester);
    expect(
      tester
          .widget<TextField>(field(formT.optionalProfileName))
          .controller!
          .text,
      'example-project',
    );
    await tester.enterText(field(formT.apiUrl), ' https://api.example.com ');
    await tester.enterText(field(formT.optionalProfileName), ' Company ');
    await tester.tap(reviewButton);
    await tester.pumpAndSettle();

    expect(find.text(formT.reviewTitle), findsOneWidget);
    expect(find.text('Company'), findsOneWidget);
    expect(find.text('https://api.example.com'), findsOneWidget);
    expect(find.text('example-project'), findsOneWidget);
    expect(find.textContaining(privateKey), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, formT.startSetup),
          )
          .onPressed,
      isNull,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), isEmpty);

    await tester.tap(find.text(formT.editSetup));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(field(formT.optionalProfileName))
          .controller!
          .text,
      ' Company ',
    );
    expect(find.text('service-account.json'), findsOneWidget);
    await tester.tap(find.byTooltip(t.common.close));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open setup'));
    await tester.pumpAndSettle();
    expect(find.text('service-account.json'), findsNothing);
    expect(tester.widget<TextField>(field(formT.apiUrl)).controller!.text, '');
    expect(prefs.getKeys(), isEmpty);
  });

  testWidgets('requires a valid API URL and service account before review', (
    tester,
  ) async {
    await pumpForm(tester);
    await tester.tap(reviewButton);
    await tester.pumpAndSettle();
    expect(find.text(formT.invalidApiUrl), findsOneWidget);
    expect(find.text(formT.serviceAccountRequired), findsOneWidget);
    mockFile(tester, jsonEncode(account()));
    await selectFile(tester);
    for (final url in [
      'api.example.com',
      'ftp://api.example.com',
      'https://',
      'https://api.example.com/has space',
    ]) {
      await tester.enterText(field(formT.apiUrl), url);
      await tester.tap(reviewButton);
      await tester.pumpAndSettle();
      expect(find.text(formT.invalidApiUrl), findsOneWidget);
      expect(find.text(formT.reviewTitle), findsNothing);
    }
    await tester.enterText(field(formT.apiUrl), 'http://localhost:8080');
    await tester.enterText(field(formT.optionalProfileName), '');
    await tester.tap(reviewButton);
    await tester.pumpAndSettle();
    expect(find.text(formT.reviewTitle), findsOneWidget);
    expect(find.text('example-project'), findsNWidgets(2));
  });

  testWidgets(
    'rejects malformed or client config JSON without exposing its contents',
    (
      tester,
    ) async {
      await pumpForm(tester);
      for (final contents in [
        '{"private_key":"$privateKey", invalid',
        jsonEncode({
          'project_info': {'project_id': 'example-project'},
        }),
        jsonEncode({...account(), 'private_key': ''}),
      ]) {
        mockFile(tester, contents);
        await selectFile(tester);
        expect(find.text(formT.invalidServiceAccount), findsOneWidget);
        expect(find.text('service-account.json'), findsNothing);
        expect(find.textContaining(privateKey), findsNothing);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'updates suggested names, preserves edits, and clears invalid replacements',
    (
      tester,
    ) async {
      await pumpForm(tester);
      mockFile(tester, jsonEncode(account()));
      await selectFile(tester);
      mockFile(tester, jsonEncode(account('second-project')));
      await selectFile(tester);
      expect(
        tester
            .widget<TextField>(field(formT.optionalProfileName))
            .controller!
            .text,
        'second-project',
      );
      await tester.enterText(field(formT.optionalProfileName), 'Company');
      mockFile(tester, jsonEncode(account('third-project')));
      await selectFile(tester);
      expect(
        tester
            .widget<TextField>(field(formT.optionalProfileName))
            .controller!
            .text,
        'Company',
      );
      mockFile(tester, '{}');
      await selectFile(tester);
      expect(find.text('service-account.json'), findsNothing);
      expect(
        tester
            .widget<TextField>(field(formT.optionalProfileName))
            .controller!
            .text,
        'Company',
      );
      mockFile(tester, jsonEncode(account()));
      await selectFile(tester);
      await tester.tap(find.byTooltip(formT.removeServiceAccount));
      await tester.pumpAndSettle();
      expect(find.text('service-account.json'), findsNothing);
    },
  );

  testWidgets('cancelling file selection preserves the previous selection', (
    tester,
  ) async {
    await pumpForm(tester);
    mockFile(tester, jsonEncode(account()));
    await selectFile(tester);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      pickerChannel,
      (_) async => null,
    );
    await selectFile(tester);
    expect(find.text('service-account.json'), findsOneWidget);
    expect(find.text(formT.invalidServiceAccount), findsNothing);
  });

  testWidgets(
    'disables repeated selection and ignores completion after closing',
    (
      tester,
    ) async {
      final pending = Completer<Object?>();
      var calls = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        pickerChannel,
        (_) {
          calls++;
          return pending.future;
        },
      );
      await pumpForm(tester);
      await tester.tap(find.byIcon(Icons.upload_file_outlined));
      await tester.pump();
      expect(tester.widget<FilledButton>(reviewButton).onPressed, isNull);
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNull,
      );
      expect(calls, 1);
      await tester.tap(find.byTooltip(t.common.close));
      await tester.pumpAndSettle();
      pending.complete(null);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'opens the review at the top after scrolling the input form',
    (tester) async {
      await pumpForm(tester, size: const Size(390, 600));
      mockFile(tester, jsonEncode(account()));
      await tester.enterText(field(formT.apiUrl), 'https://api.example.com');
      await selectFile(tester);
      await tester.ensureVisible(field(formT.optionalProfileName));
      await tester.enterText(field(formT.optionalProfileName), 'Company');
      await tester.tap(reviewButton);
      await tester.pumpAndSettle();

      final contentTop = tester
          .getTopLeft(find.byType(SingleChildScrollView))
          .dy;
      expect(
        tester.getTopLeft(find.text('Company')).dy,
        greaterThanOrEqualTo(contentTop),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'supports a narrow screen, larger text, keyboard, and manual fallback',
    (
      tester,
    ) async {
      await pumpForm(tester, size: const Size(390, 700), textScale: 1.3);
      expect(find.byType(BottomSheet), findsOneWidget);
      tester.view.viewInsets = const FakeViewPadding(bottom: 250);
      addTearDown(tester.view.resetViewInsets);
      await tester.enterText(field(formT.apiUrl), 'https://api.example.com');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(field(formT.optionalProfileName));
      await tester.enterText(field(formT.optionalProfileName), 'Company');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text(formT.manualSetup));
      await tester.pumpAndSettle();
      expect(find.byType(SelfHostedSetupForm), findsNothing);
      expect(find.text('manual'), findsOneWidget);
    },
  );
}
