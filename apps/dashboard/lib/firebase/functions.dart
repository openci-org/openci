import 'package:cloud_functions/cloud_functions.dart';

const firebaseFunctionsRegion = 'asia-northeast1';

FirebaseFunctions get firebaseFunctions =>
    FirebaseFunctions.instanceFor(region: firebaseFunctionsRegion);

/// Cloud Functions 2nd Gen のURLを動的に生成する
String getFunctionUrl(String functionKebabName) {
  const projectNumber = String.fromEnvironment('FUNCTIONS_PROJECT_NUMBER');
  return 'https://$functionKebabName-$projectNumber.$firebaseFunctionsRegion.run.app';
}

HttpsCallable getCancelBuildJobCallable() {
  return FirebaseFunctions.instanceFor(
    region: firebaseFunctionsRegion,
  ).httpsCallableFromUrl(
    getFunctionUrl('cancel-build-job'),
  );
}
