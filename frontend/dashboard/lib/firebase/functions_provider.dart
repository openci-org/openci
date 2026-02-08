import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'functions_provider.g.dart';

@riverpod
class Functions extends _$Functions {
  @override
  FirebaseFunctions build() {
    return getFirebaseFunctions();
  }

  FirebaseFunctions getFirebaseFunctions() {
    if (Firebase.apps.length == 1 && Firebase.apps.first.name == '[DEFAULT]') {
      return FirebaseFunctions.instanceFor(region: 'asia-northeast1');
    }
    final nonDefaultFirebaseApps = Firebase.apps.where(
      (app) => app.name != '[DEFAULT]',
    );
    return FirebaseFunctions.instanceFor(
      app: nonDefaultFirebaseApps.first,
      region: 'asia-northeast1',
    );
  }
}
