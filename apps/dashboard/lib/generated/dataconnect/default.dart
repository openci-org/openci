library openci_dataconnect;
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

part 'create_invitation.dart';

part 'reinvite_invitation.dart';

part 'accept_invitation.dart';

part 'expire_invitation.dart';

part 'add_team_member.dart';

part 'accept_invitation_and_join_team.dart';

part 'get_invitation_by_token.dart';

part 'list_my_pending_invitations.dart';

part 'list_team_pending_invitations.dart';

part 'find_existing_pending_invitation.dart';



  enum InvitationStatus {
    
      PENDING,
    
      ACCEPTED,
    
      EXPIRED,
    
  }
  
  String invitationStatusSerializer(EnumValue<InvitationStatus> e) {
    return e.stringValue;
  }
  EnumValue<InvitationStatus> invitationStatusDeserializer(dynamic data) {
    switch (data) {
      
      case 'PENDING':
        return const Known(InvitationStatus.PENDING);
      
      case 'ACCEPTED':
        return const Known(InvitationStatus.ACCEPTED);
      
      case 'EXPIRED':
        return const Known(InvitationStatus.EXPIRED);
      
      default:
        return Unknown(data);
    }
  }
  



String enumSerializer(Enum e) {
  return e.name;
}



/// A sealed class representing either a known enum value or an unknown string value.
@immutable
sealed class EnumValue<T extends Enum> {
  const EnumValue();

  

  /// The string representation of the value.
  String get stringValue;
  @override
  String toString() {
    return "EnumValue($stringValue)";
  }
}

/// Represents a known, valid enum value.
class Known<T extends Enum> extends EnumValue<T> {
  /// The actual enum value.
  final T value;

  const Known(this.value);

  @override
  String get stringValue => value.name;

  @override
  String toString() {
    return "Known($stringValue)";
  }
}
/// Represents an unknown or unrecognized enum value.
class Unknown extends EnumValue<Never> {
  /// The raw string value that couldn't be mapped to a known enum.
  @override
  final String stringValue;

  const Unknown(this.stringValue);
  @override
  String toString() {
    return "Unknown($stringValue)";
  }
}

class DefaultConnector {
  
  
  CreateInvitationVariablesBuilder createInvitation ({required String email, required String teamId, required String teamNameSnapshot, required String token, required Timestamp expiresAt, }) {
    return CreateInvitationVariablesBuilder(dataConnect, email: email,teamId: teamId,teamNameSnapshot: teamNameSnapshot,token: token,expiresAt: expiresAt,);
  }
  
  
  ReinviteInvitationVariablesBuilder reinviteInvitation ({required String id, required String token, required Timestamp expiresAt, }) {
    return ReinviteInvitationVariablesBuilder(dataConnect, id: id,token: token,expiresAt: expiresAt,);
  }
  
  
  AcceptInvitationVariablesBuilder acceptInvitation ({required String id, }) {
    return AcceptInvitationVariablesBuilder(dataConnect, id: id,);
  }
  
  
  ExpireInvitationVariablesBuilder expireInvitation ({required String id, }) {
    return ExpireInvitationVariablesBuilder(dataConnect, id: id,);
  }
  
  
  AddTeamMemberVariablesBuilder addTeamMember ({required String teamId, }) {
    return AddTeamMemberVariablesBuilder(dataConnect, teamId: teamId,);
  }
  
  
  AcceptInvitationAndJoinTeamVariablesBuilder acceptInvitationAndJoinTeam ({required String id, required String teamId, }) {
    return AcceptInvitationAndJoinTeamVariablesBuilder(dataConnect, id: id,teamId: teamId,);
  }
  
  
  GetInvitationByTokenVariablesBuilder getInvitationByToken ({required String token, }) {
    return GetInvitationByTokenVariablesBuilder(dataConnect, token: token,);
  }
  
  
  ListMyPendingInvitationsVariablesBuilder listMyPendingInvitations () {
    return ListMyPendingInvitationsVariablesBuilder(dataConnect, );
  }
  
  
  ListTeamPendingInvitationsVariablesBuilder listTeamPendingInvitations ({required String teamId, }) {
    return ListTeamPendingInvitationsVariablesBuilder(dataConnect, teamId: teamId,);
  }
  
  
  FindExistingPendingInvitationVariablesBuilder findExistingPendingInvitation ({required String email, required String teamId, }) {
    return FindExistingPendingInvitationVariablesBuilder(dataConnect, email: email,teamId: teamId,);
  }
  

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'asia-northeast1',
    'default',
    'openci-b1b91-2-service',
  );

  DefaultConnector({required this.dataConnect});
  static DefaultConnector get instance {
    
    return DefaultConnector(
        dataConnect: FirebaseDataConnect.instanceFor(
            connectorConfig: connectorConfig,
            
            sdkType: CallerSDKType.generated));
  }

  FirebaseDataConnect dataConnect;
}
