import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firestore_provider.g.dart';

@riverpod
class Firestore extends _$Firestore {
  @override
  FirebaseFirestore build() {
    return getFirestore();
  }

  FirebaseFirestore getFirestore() {
    if (Firebase.apps.length == 1 && Firebase.apps.first.name == '[DEFAULT]') {
      return FirebaseFirestore.instance;
    }
    final nonDefaultFirebaseApps = Firebase.apps.where(
      (app) => app.name != '[DEFAULT]',
    );
    return FirebaseFirestore.instanceFor(app: nonDefaultFirebaseApps.first);
  }
}
