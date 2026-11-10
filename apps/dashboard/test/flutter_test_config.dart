import 'dart:async';

import 'package:dashboard/app_strings.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  LocaleSettings.setLocaleSync(AppLocale.ja);
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.ja));
  await testMain();
}
