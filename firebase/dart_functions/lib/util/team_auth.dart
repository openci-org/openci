import 'package:firebase_functions/firebase_functions.dart';
import 'package:openci_shared/firestore_paths.dart';

import '../firebase.dart';

Future<Map<String, dynamic>> verifyTeamMembership({
  required AuthData? auth,
  required String teamId,
}) async {
  if (auth == null) {
    throw UnauthenticatedError('Unauthenticated');
  }

  final teamDoc = await firestore.collection(teamsCollection).doc(teamId).get();
  if (!teamDoc.exists) {
    throw NotFoundError('Team not found');
  }

  final teamData = teamDoc.data()!;
  final members = (teamData['members'] as List<dynamic>?)?.cast<String>() ?? [];

  if (!members.contains(auth.uid)) {
    throw PermissionDeniedError('You are not a member of this team');
  }

  return teamData;
}
