import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Database ID for the Firestore Enterprise Edition instance.
const firestoreDatabaseId = 'openci-enterprise';

/// Returns the [FirebaseFirestore] instance pointing to the Enterprise database.
///
/// Use this instead of `FirebaseFirestore.instance` so that all Firestore
/// operations target the `openci-enterprise` named database.
FirebaseFirestore get firestore => FirebaseFirestore.instanceFor(
  app: Firebase.app(),
  databaseId: firestoreDatabaseId,
);
