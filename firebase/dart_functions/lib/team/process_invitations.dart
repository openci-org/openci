import 'package:firebase_functions/firebase_functions.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart';
import 'package:openci_shared/firestore_paths.dart';

import '../firebase.dart';
import '../util/logger.dart';

Future<CallableResult<Map<String, dynamic>>> handleProcessInvitationsOnSignUp(
  CallableRequest<Object?> request,
  CallableResponse<Object> response,
) async {
  final auth = request.auth;
  if (auth == null) {
    throw UnauthenticatedError('Unauthenticated');
  }

  final uid = auth.uid;
  final email = (auth.token?['email'] as String?)?.trim().toLowerCase();

  if (email == null || email.isEmpty) {
    return CallableResult(<String, dynamic>{
      'joinedTeams': <Map<String, dynamic>>[],
      'message': 'No email found',
    });
  }

  final pendingInvitations = await firestore
      .collection(invitationsCollection)
      .where('email', WhereFilter.equal, email)
      .where('status', WhereFilter.equal, 'pending')
      .get();

  if (pendingInvitations.docs.isEmpty) {
    logInfo('No pending invitations found for $email');
    return CallableResult(<String, dynamic>{
      'joinedTeams': <Map<String, dynamic>>[],
      'message': 'No pending invitations',
    });
  }

  final now = DateTime.now().toUtc();
  final nowIso = now.toIso8601String();
  final joinedTeams = <Map<String, dynamic>>[];

  for (final doc in pendingInvitations.docs) {
    final invitation = doc.data();

    final expiresAtStr = invitation['expiresAt'] as String?;
    if (expiresAtStr != null) {
      final expiresAt = DateTime.parse(expiresAtStr);
      if (expiresAt.isBefore(now)) {
        await doc.ref.update({'status': 'expired'});
        logInfo('Invitation ${doc.id} expired for $email');
        continue;
      }
    }

    final teamId = invitation['teamId'] as String;
    final teamRef = firestore.collection(teamsCollection).doc(teamId);
    final teamDoc = await teamRef.get();
    if (!teamDoc.exists) {
      logWarning('Team $teamId not found, skipping invitation ${doc.id}');
      await doc.ref.update({'status': 'expired'});
      continue;
    }

    final teamData = teamDoc.data()!;
    final members =
        (teamData['members'] as List<dynamic>?)?.cast<String>() ?? [];

    if (!members.contains(uid)) {
      final updatedMembers = List<String>.from(members)..add(uid);
      await teamRef.update({'members': updatedMembers, 'updatedAt': nowIso});
    }

    await doc.ref.update({
      'status': 'accepted',
      'acceptedAt': nowIso,
      'acceptedBy': uid,
    });

    final teamName = invitation['teamName'] as String? ?? '';
    joinedTeams.add({'teamId': teamId, 'teamName': teamName});

    logInfo(
      'User $uid ($email) auto-joined team $teamId via invitation ${doc.id}',
    );
  }

  return CallableResult(<String, dynamic>{
    'joinedTeams': joinedTeams,
    'message': joinedTeams.isEmpty
        ? 'No valid invitations'
        : 'Joined ${joinedTeams.length} team(s)',
  });
}
