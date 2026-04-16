import 'package:dio/dio.dart';
import 'package:firebase_functions/firebase_functions.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart';
import 'package:openci_shared/firestore_paths.dart';
import 'package:uuid/uuid.dart';

import '../firebase.dart';
import '../secret_manager.dart' show accessSecret;
import '../util/logger.dart';
import '../util/team_auth.dart';

// ---------------------------------------------------------------------------
// Request models
// ---------------------------------------------------------------------------

class GetTeamMembersRequest {
  const GetTeamMembersRequest({required this.teamId});

  factory GetTeamMembersRequest.fromJson(Map<String, dynamic> json) {
    final teamId = json['teamId'] as String?;
    if (teamId == null || teamId.isEmpty) {
      throw InvalidArgumentError('Missing teamId');
    }
    return GetTeamMembersRequest(teamId: teamId);
  }

  final String teamId;
}

class InviteTeamMemberRequest {
  const InviteTeamMemberRequest({required this.email, required this.teamId});

  factory InviteTeamMemberRequest.fromJson(Map<String, dynamic> json) {
    final email = json['email'] as String?;
    final teamId = json['teamId'] as String?;
    if (email == null || email.isEmpty || teamId == null || teamId.isEmpty) {
      throw InvalidArgumentError('Missing email or teamId');
    }
    return InviteTeamMemberRequest(email: email, teamId: teamId);
  }

  final String email;
  final String teamId;
}

class AcceptInvitationRequest {
  const AcceptInvitationRequest({required this.token});

  factory AcceptInvitationRequest.fromJson(Map<String, dynamic> json) {
    final token = json['token'] as String?;
    if (token == null || token.isEmpty) {
      throw InvalidArgumentError('Missing token');
    }
    return AcceptInvitationRequest(token: token);
  }

  final String token;
}

// ---------------------------------------------------------------------------
// Firebase Auth Identity Toolkit helper
// ---------------------------------------------------------------------------

/// Look up a Firebase Auth user by UID using Google Identity Toolkit API.
Future<Map<String, dynamic>?> _getUserByUid(
  String uid,
  String accessToken,
  String projectId,
) async {
  final dio = Dio();
  try {
    final response = await dio.post<Map<String, dynamic>>(
      'https://identitytoolkit.googleapis.com/v1/projects/$projectId/accounts:lookup',
      data: {
        'localId': [uid],
      },
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    final users = response.data?['users'] as List<dynamic>?;
    if (users != null && users.isNotEmpty) {
      return users.first as Map<String, dynamic>;
    }
    return null;
  } finally {
    dio.close();
  }
}

/// Look up a Firebase Auth user by email.
Future<Map<String, dynamic>?> _getUserByEmail(
  String email,
  String accessToken,
  String projectId,
) async {
  final dio = Dio();
  try {
    final response = await dio.post<Map<String, dynamic>>(
      'https://identitytoolkit.googleapis.com/v1/projects/$projectId/accounts:lookup',
      data: {
        'email': [email],
      },
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    final users = response.data?['users'] as List<dynamic>?;
    if (users != null && users.isNotEmpty) {
      return users.first as Map<String, dynamic>;
    }
    return null;
  } finally {
    dio.close();
  }
}

/// Get access token via metadata server (for Google API calls).
Future<String> _getAccessToken() async {
  final dio = Dio();
  try {
    final response = await dio.get<Map<String, dynamic>>(
      'http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token',
      options: Options(headers: {'Metadata-Flavor': 'Google'}),
    );
    return response.data!['access_token'] as String;
  } finally {
    dio.close();
  }
}

/// Get project ID from metadata server.
Future<String> _getProjectId() async {
  final dio = Dio();
  try {
    final response = await dio.get<String>(
      'http://metadata.google.internal/computeMetadata/v1/project/project-id',
      options: Options(
        headers: {'Metadata-Flavor': 'Google'},
        responseType: ResponseType.plain,
      ),
    );
    return response.data!;
  } finally {
    dio.close();
  }
}

// ---------------------------------------------------------------------------
// Resend email helper
// ---------------------------------------------------------------------------

Future<void> _sendEmail({
  required String to,
  required String subject,
  required String html,
}) async {
  final resendApiKey = await accessSecret('RESEND_API_KEY');
  final dio = Dio();
  try {
    await dio.post<void>(
      'https://api.resend.com/emails',
      data: {
        'from': 'OpenCI <noreply@openci.org>',
        'to': to,
        'subject': subject,
        'html': html,
      },
      options: Options(headers: {'Authorization': 'Bearer $resendApiKey'}),
    );
  } finally {
    dio.close();
  }
}

Future<void> _sendInvitationEmail({
  required String to,
  required String token,
  required String teamName,
  required String inviterEmail,
}) async {
  final inviteUrl = 'https://dashboard.openci.org/invite/$token';
  await _sendEmail(
    to: to,
    subject: '[OpenCI] You\'ve been invited to join "$teamName"',
    html:
        '''
      <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 560px; margin: 0 auto; padding: 40px 20px;">
        <h1 style="font-size: 24px; font-weight: 600; color: #1a1a1a; margin-bottom: 8px;">
          Welcome to OpenCI 🚀
        </h1>
        <p style="font-size: 16px; color: #4a4a4a; line-height: 1.6;">
          <strong>$inviterEmail</strong> has invited you to join the
          <strong>"$teamName"</strong> team on OpenCI.
        </p>
        <div style="margin: 32px 0;">
          <a href="$inviteUrl"
             style="display: inline-block; background-color: #6366f1; color: #ffffff; text-decoration: none; padding: 12px 32px; border-radius: 8px; font-size: 16px; font-weight: 500;">
            Accept Invitation
          </a>
        </div>
        <p style="font-size: 14px; color: #888888;">
          This invitation expires in 7 days.<br/>
          If you didn't expect this email, you can safely ignore it.
        </p>
        <hr style="border: none; border-top: 1px solid #e5e5e5; margin: 32px 0;" />
        <p style="font-size: 12px; color: #aaaaaa;">
          OpenCI — CI/CD for everyone
        </p>
      </div>
    ''',
  );
}

Future<void> _sendTeamAddedEmail({
  required String to,
  required String teamName,
  required String inviterEmail,
}) async {
  try {
    await _sendEmail(
      to: to,
      subject: '[OpenCI] You\'ve been added to "$teamName"',
      html:
          '''
        <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; max-width: 560px; margin: 0 auto; padding: 40px 20px;">
          <h1 style="font-size: 24px; font-weight: 600; color: #1a1a1a; margin-bottom: 8px;">
            You're now a member of "$teamName" 🎉
          </h1>
          <p style="font-size: 16px; color: #4a4a4a; line-height: 1.6;">
            <strong>$inviterEmail</strong> has added you to the
            <strong>"$teamName"</strong> team on OpenCI.
          </p>
          <div style="margin: 32px 0;">
            <a href="https://dashboard.openci.org"
               style="display: inline-block; background-color: #6366f1; color: #ffffff; text-decoration: none; padding: 12px 32px; border-radius: 8px; font-size: 16px; font-weight: 500;">
              Open Dashboard
            </a>
          </div>
          <hr style="border: none; border-top: 1px solid #e5e5e5; margin: 32px 0;" />
          <p style="font-size: 12px; color: #aaaaaa;">
            OpenCI — CI/CD for everyone
          </p>
        </div>
      ''',
    );
  } catch (e) {
    logWarning('Failed to send team added email', {'to': to}, e);
  }
}

// ---------------------------------------------------------------------------
// Handlers
// ---------------------------------------------------------------------------

Future<Map<String, dynamic>> handleGetTeamMembers(
  CallableRequest<GetTeamMembersRequest> request,
  CallableResponse<Map<String, dynamic>> response,
) async {
  final teamData = await verifyTeamMembership(
    auth: request.auth,
    teamId: request.data.teamId,
  );

  final memberUids =
      (teamData['members'] as List<dynamic>?)?.cast<String>() ?? [];

  final accessToken = await _getAccessToken();
  final projectId = await _getProjectId();

  final members = <Map<String, dynamic>>[];
  for (final uid in memberUids) {
    try {
      final user = await _getUserByUid(uid, accessToken, projectId);
      members.add({
        'uid': uid,
        'email': user?['email'],
        'displayName': user?['displayName'],
        'photoURL': user?['photoUrl'],
      });
    } catch (_) {
      members.add({
        'uid': uid,
        'email': null,
        'displayName': null,
        'photoURL': null,
      });
    }
  }

  return <String, dynamic>{'members': members};
}

Future<Map<String, dynamic>> handleInviteTeamMember(
  CallableRequest<InviteTeamMemberRequest> request,
  CallableResponse<Map<String, dynamic>> response,
) async {
  final auth = request.auth;
  if (auth == null) {
    throw UnauthenticatedError('Unauthenticated');
  }

  final teamData = await verifyTeamMembership(
    auth: auth,
    teamId: request.data.teamId,
  );

  final callerUid = auth.uid;
  final email = request.data.email;
  final teamId = request.data.teamId;
  final members = (teamData['members'] as List<dynamic>?)?.cast<String>() ?? [];

  final accessToken = await _getAccessToken();
  final projectId = await _getProjectId();

  // Get caller's email
  final callerUser = await _getUserByUid(callerUid, accessToken, projectId);
  final inviterEmail = (callerUser?['email'] as String?) ?? 'A team member';

  // Check if user already has an OpenCI account
  final existingUser = await _getUserByEmail(email, accessToken, projectId);
  if (existingUser != null) {
    final inviteeUid = existingUser['localId'] as String;

    if (members.contains(inviteeUid)) {
      throw AlreadyExistsError('User is already a member of this team');
    }

    // Add directly to team
    final teamRef = firestore.collection(teamsCollection).doc(teamId);
    final now = DateTime.now().toUtc().toIso8601String();

    // Read current members and append
    final currentMembers = List<String>.from(members);
    currentMembers.add(inviteeUid);
    await teamRef.update({'members': currentMembers, 'updatedAt': now});

    logInfo('User $inviteeUid added to team $teamId by $callerUid');

    await _sendTeamAddedEmail(
      to: email,
      teamName: teamData['name'] as String? ?? '',
      inviterEmail: inviterEmail,
    );

    return <String, dynamic>{'status': 'added', 'inviteeUid': inviteeUid};
  }

  // User does NOT have an account — create a pending invitation
  final token = const Uuid().v4();
  final expiresAt = DateTime.now()
      .add(const Duration(days: 7))
      .toUtc()
      .toIso8601String();

  // Check for existing pending invitation
  final existingInvitations = await firestore
      .collection(invitationsCollection)
      .where('email', WhereFilter.equal, email)
      .where('teamId', WhereFilter.equal, teamId)
      .where('status', WhereFilter.equal, 'pending')
      .get();

  final now = DateTime.now().toUtc().toIso8601String();

  if (existingInvitations.docs.isNotEmpty) {
    final existingDoc = existingInvitations.docs.first;
    await existingDoc.ref.update({
      'token': token,
      'invitedBy': callerUid,
      'expiresAt': expiresAt,
      'updatedAt': now,
    });
    logInfo('Re-invited $email to team $teamId (updated existing invitation)');
  } else {
    final invitationRef = firestore.collection(invitationsCollection).doc();
    await invitationRef.set({
      'id': invitationRef.id,
      'email': email,
      'teamId': teamId,
      'teamName': teamData['name'],
      'invitedBy': callerUid,
      'token': token,
      'status': 'pending',
      'createdAt': now,
      'expiresAt': expiresAt,
    });
    logInfo('Created invitation for $email to team $teamId');
  }

  await _sendInvitationEmail(
    to: email,
    token: token,
    teamName: teamData['name'] as String? ?? '',
    inviterEmail: inviterEmail,
  );

  return <String, dynamic>{'status': 'invited'};
}

Future<Map<String, dynamic>> handleAcceptInvitation(
  CallableRequest<AcceptInvitationRequest> request,
  CallableResponse<Map<String, dynamic>> response,
) async {
  final auth = request.auth;
  if (auth == null) {
    throw UnauthenticatedError('Unauthenticated');
  }

  final uid = auth.uid;
  final userEmail = auth.token?['email'] as String?;
  final token = request.data.token;

  // Find invitation by token
  final invitationQuery = await firestore
      .collection(invitationsCollection)
      .where('token', WhereFilter.equal, token)
      .where('status', WhereFilter.equal, 'pending')
      .limit(1)
      .get();

  if (invitationQuery.docs.isEmpty) {
    throw NotFoundError('Invitation not found or already used');
  }

  final invitationDoc = invitationQuery.docs.first;
  final invitation = invitationDoc.data();

  // Verify email matches
  if (invitation['email'] != userEmail) {
    throw PermissionDeniedError(
      'This invitation was sent to a different email address',
    );
  }

  // Check expiration
  final expiresAtStr = invitation['expiresAt'] as String?;
  if (expiresAtStr != null) {
    final expiresAt = DateTime.parse(expiresAtStr);
    if (expiresAt.isBefore(DateTime.now().toUtc())) {
      await invitationDoc.ref.update({'status': 'expired'});
      throw DeadlineExceededError('This invitation has expired');
    }
  }

  // Check team exists
  final teamId = invitation['teamId'] as String;
  final teamRef = firestore.collection(teamsCollection).doc(teamId);
  final teamDoc = await teamRef.get();
  if (!teamDoc.exists) {
    throw NotFoundError('Team not found');
  }

  final teamData = teamDoc.data()!;
  final members = (teamData['members'] as List<dynamic>?)?.cast<String>() ?? [];

  final now = DateTime.now().toUtc().toIso8601String();

  if (members.contains(uid)) {
    await invitationDoc.ref.update({
      'status': 'accepted',
      'acceptedAt': now,
      'acceptedBy': uid,
    });
    return <String, dynamic>{
      'status': 'already_member',
      'teamId': teamId,
      'teamName': invitation['teamName'],
    };
  }

  // Add user to team
  final currentMembers = List<String>.from(members);
  currentMembers.add(uid);
  await teamRef.update({'members': currentMembers, 'updatedAt': now});

  // Mark invitation as accepted
  await invitationDoc.ref.update({
    'status': 'accepted',
    'acceptedAt': now,
    'acceptedBy': uid,
  });

  // Update user's selectedTeamId
  await firestore.collection(usersCollection).doc(uid).update({
    'selectedTeamId': teamId,
    'updatedAt': now,
  });

  logInfo('User $uid accepted invitation to team $teamId');

  return <String, dynamic>{
    'status': 'accepted',
    'teamId': teamId,
    'teamName': invitation['teamName'],
  };
}
