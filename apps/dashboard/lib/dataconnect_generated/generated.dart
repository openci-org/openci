library dataconnect_generated;
import 'package:firebase_data_connect/firebase_data_connect.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

part 'get_my_user.dart';

part 'get_my_teams.dart';

part 'create_user_with_default_team.dart';

part 'create_team.dart';

part 'update_team_name.dart';

part 'update_notification_preference.dart';

part 'add_fcm_token.dart';



  enum NotificationPreference {
    
      ALL,
    
      SUCCESS_ONLY,
    
      FAILURE_ONLY,
    
      NONE,
    
  }
  
  String notificationPreferenceSerializer(EnumValue<NotificationPreference> e) {
    return e.stringValue;
  }
  EnumValue<NotificationPreference> notificationPreferenceDeserializer(dynamic data) {
    switch (data) {
      
      case 'ALL':
        return const Known(NotificationPreference.ALL);
      
      case 'SUCCESS_ONLY':
        return const Known(NotificationPreference.SUCCESS_ONLY);
      
      case 'FAILURE_ONLY':
        return const Known(NotificationPreference.FAILURE_ONLY);
      
      case 'NONE':
        return const Known(NotificationPreference.NONE);
      
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

class DashboardConnector {
  
  
  GetMyUserVariablesBuilder getMyUser () {
    return GetMyUserVariablesBuilder(dataConnect, );
  }
  
  
  GetMyTeamsVariablesBuilder getMyTeams ({required String uid, }) {
    return GetMyTeamsVariablesBuilder(dataConnect, uid: uid,);
  }
  
  
  CreateUserWithDefaultTeamVariablesBuilder createUserWithDefaultTeam ({required String uid, }) {
    return CreateUserWithDefaultTeamVariablesBuilder(dataConnect, uid: uid,);
  }
  
  
  CreateTeamVariablesBuilder createTeam ({required String teamName, required String uid, }) {
    return CreateTeamVariablesBuilder(dataConnect, teamName: teamName,uid: uid,);
  }
  
  
  UpdateTeamNameVariablesBuilder updateTeamName ({required String teamId, required String newName, }) {
    return UpdateTeamNameVariablesBuilder(dataConnect, teamId: teamId,newName: newName,);
  }
  
  
  UpdateNotificationPreferenceVariablesBuilder updateNotificationPreference ({required NotificationPreference preference, }) {
    return UpdateNotificationPreferenceVariablesBuilder(dataConnect, preference: preference,);
  }
  
  
  AddFcmTokenVariablesBuilder addFcmToken ({required String token, }) {
    return AddFcmTokenVariablesBuilder(dataConnect, token: token,);
  }
  

  static ConnectorConfig connectorConfig = ConnectorConfig(
    'asia-northeast1',
    'dashboard',
    'openci-b1b91-service',
  );

  DashboardConnector({required this.dataConnect});
  static DashboardConnector get instance {
    return DashboardConnector(
        dataConnect: FirebaseDataConnect.instanceFor(
            connectorConfig: connectorConfig,
            sdkType: CallerSDKType.generated));
  }

  FirebaseDataConnect dataConnect;
}
