import 'dart:convert';

import '../credential_store/credential_config.dart';

String firebaseProjectId(AuthProfile profile) {
  Object? project = profile.firebaseProjectId;
  if (project == '') {
    final parts = profile.token.split('.');
    if (parts.length != 3) {
      throw const FormatException('Firebase login is required');
    }
    final claims = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    project = claims is Map ? claims['aud'] : null;
  }
  if (project is! String ||
      !RegExp(r'^[a-z][a-z0-9-]{4,62}$').hasMatch(project)) {
    throw const FormatException('Invalid Firebase project ID');
  }
  return project;
}
