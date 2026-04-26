import 'package:cloud_functions/cloud_functions.dart';

FirebaseFunctions get firebaseFunctions =>
    FirebaseFunctions.instanceFor(region: 'asia-northeast1');
