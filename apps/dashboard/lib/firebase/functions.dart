import 'package:cloud_functions/cloud_functions.dart';

const firebaseFunctionsRegion = 'asia-northeast1';

FirebaseFunctions get firebaseFunctions =>
    FirebaseFunctions.instanceFor(region: firebaseFunctionsRegion);
