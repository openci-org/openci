import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

final offeringsProvider = FutureProvider<Offerings>((ref) async {
  return await Purchases.getOfferings();
});

final customerInfoProvider = FutureProvider<CustomerInfo>((ref) async {
  return await Purchases.getCustomerInfo();
});
