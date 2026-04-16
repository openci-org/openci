import 'package:google_cloud_firestore/google_cloud_firestore.dart';

/// Global Firestore instance.
///
/// In Firebase Functions, ADC is automatically configured,
/// so we can use a simple singleton.
final firestore = Firestore();
