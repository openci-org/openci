import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:purchases_flutter/purchases_flutter.dart';

Future<void> initializeRevenueCat() async {
  final apiKey =
      kIsWeb
          ? const String.fromEnvironment('REVENUE_CAT_WEB_API_KEY')
          : const String.fromEnvironment('REVENUE_CAT_API_KEY');
  if (apiKey.isEmpty) {
    throw StateError(
      'RevenueCat API key is not set. '
      'Pass REVENUE_CAT_API_KEY (Apple) or REVENUE_CAT_WEB_API_KEY (Web) '
      'via --dart-define-from-file',
    );
  }
  await Purchases.configure(PurchasesConfiguration(apiKey));
}
