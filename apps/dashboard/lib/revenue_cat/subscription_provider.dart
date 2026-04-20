import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/revenue_cat/revenue_cat.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

final revenueCatAuthProvider = FutureProvider<void>((ref) async {
  final user = ref.read(authProvider.notifier).getFirebaseAuth().currentUser;
  if (user != null) {
    await loginRevenueCat(user.uid);
  }
});

final offeringsProvider = FutureProvider<Offerings>((ref) async {
  await ref.watch(revenueCatAuthProvider.future);
  return await Purchases.getOfferings();
});

final customerInfoProvider = FutureProvider<CustomerInfo>((ref) async {
  await ref.watch(revenueCatAuthProvider.future);
  return await Purchases.getCustomerInfo();
});
