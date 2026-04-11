// ignore_for_file: non_const_argument_for_const_parameter

import 'package:dart_functions/secret_manager.dart';
import 'package:firebase_functions/firebase_functions.dart';

void main(List<String> args) {
  fireUp(args, (firebase) {
    firebase.https.onRequest(
      name: 'helloWorld',
      options: const HttpsOptions(
        cors: Cors(['*']),
        maxInstances: Instances(10),
        region: DeployOption(SupportedRegion.asiaNortheast1),
      ),
      (request) async => Response(200, body: 'Hello from Dart Functions!'),
    );

    firebase.https.onRequest(
      name: 'healthCheck',
      options: HttpsOptions(
        cors: Cors(['*']),
      ),
      (request) async {
        try {
          final secret = await accessSecret('ANTHROPIC_API_KEY');
          return Response(200, body: 'Secret found. Length: ${secret.length}');
        } catch (e) {
          return Response(500, body: 'Error: $e');
        }
      },
    );
  });
}
