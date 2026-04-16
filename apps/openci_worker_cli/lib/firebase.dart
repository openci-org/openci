import 'dart:io';

import 'package:google_cloud_firestore/google_cloud_firestore.dart';

Future<Firestore> initFirestore({
  required String projectId,
  required String serviceAccountPath,
}) async {
  return Firestore(
    settings: Settings(
      projectId: projectId,
      credential: Credential.fromServiceAccount(File(serviceAccountPath)),
    ),
  );
}
