import 'dart:io';

import 'package:dart_firebase_admin/dart_firebase_admin.dart';
import 'package:dart_firebase_admin/firestore.dart';

Firestore initFirestore({
  required String projectId,
  required String serviceAccountPath,
}) {
  final admin = FirebaseAdminApp.initializeApp(
    projectId,
    Credential.fromServiceAccount(File(serviceAccountPath)),
  );
  return Firestore(admin);
}
