import 'dart:io';
import 'package:dart_firebase_admin/dart_firebase_admin.dart';
import 'package:dart_firebase_admin/firestore.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run update_version.dart <service-account-path>');
    exit(1);
  }
  final admin = FirebaseAdminApp.initializeApp(
    'openci-prod-efada',
    Credential.fromServiceAccount(File(args[0])),
  );
  final firestore = Firestore(admin);
  await firestore.collection('config').doc('workerCli').update({
    'latestVersion': '0.8.3',
  });
  print('✅ Updated config/workerCli.latestVersion to 0.8.3');
  admin.close();
}
