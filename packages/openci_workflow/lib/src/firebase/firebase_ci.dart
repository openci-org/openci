import 'firebase_functions_ci.dart';

/// Firebase deployment helpers.
class FirebaseCI {
  FirebaseCI(String Function(String? dir) resolveDirectory)
    : functions = FirebaseFunctionsCI(resolveDirectory);

  final FirebaseFunctionsCI functions;
}
