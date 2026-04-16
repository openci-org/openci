import 'dart:io';
import 'package:openci_worker_cli/firebase.dart';

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart run update_version.dart <service-account-path>');
    exit(1);
  }
  final firestore = await initFirestore(
    projectId: 'openci-prod-efada',
    serviceAccountPath: args[0],
  );
  await firestore.collection('config').doc('workerCli').update({
    'latestVersion': '0.8.3',
  });
  print('✅ Updated config/workerCli.latestVersion to 0.8.3');
}
