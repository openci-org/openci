import 'package:purchases_flutter/purchases_flutter.dart';

Future<void> initializeRevenueCat() async {
  const apiKey = String.fromEnvironment('REVENUE_CAT_API_KEY');
  if (apiKey.isEmpty) {
    throw StateError(
      'REVENUE_CAT_API_KEY is not set. '
      'Pass it via --dart-define=REVENUE_CAT_API_KEY=your_key',
    );
  }
  await Purchases.configure(PurchasesConfiguration(apiKey));
}
