import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/app_strings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

class DashboardException extends StateError {
  DashboardException(this.code, {this.name = '', this.platform = ''})
    : super(_dashboardMessage(code, t, name, platform));

  final String code;
  final String name;
  final String platform;
}

String _dashboardMessage(
  String code,
  Translations strings,
  String name,
  String platform,
) => switch (code) {
  'team_access_denied' => strings.team.accessDenied,
  'member_already_added' => strings.team.memberAlreadyAdded,
  'member_not_registered' => strings.team.memberNotRegistered,
  'invalid_email' => strings.team.enterValidEmail,
  'member_email_not_verified' => strings.team.memberEmailNotVerified,
  'member_unavailable' => strings.team.memberUnavailable,
  'team_operation_failed' => strings.team.operationFailed,
  'connection_save_failed' => strings.connection.saveFailed,
  'connection_config_mismatch' => strings.connection.configMismatch,
  'connection_platform_missing' => strings.connection.platformConfigMissing(
    name: name,
    platform: platform,
  ),
  'secrets_authentication_required' => strings.secrets.signInRequired,
  'secrets_context_changed' => strings.secrets.contextChanged,
  _ => strings.common.errorOccurred,
};

String dashboardErrorMessage(Object error, Translations strings) {
  if (error is DashboardException) {
    return _dashboardMessage(error.code, strings, error.name, error.platform);
  }
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-email' => strings.team.enterValidEmail,
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => strings.auth.invalidCredentials,
      'email-already-in-use' => strings.auth.emailInUse,
      'weak-password' => strings.auth.weakPassword,
      'too-many-requests' => strings.settings.emailVerificationRateLimited,
      'network-request-failed' => strings.common.networkFailed,
      'user-disabled' => strings.auth.accountDisabled,
      _ => strings.auth.operationFailed,
    };
  }
  if (error is FirebaseFunctionsException) {
    return switch (error.code) {
      'unauthenticated' => strings.secrets.signInRequired,
      'permission-denied' => strings.team.accessDenied,
      'invalid-argument' => strings.secrets.invalidInput,
      'not-found' => strings.secrets.notFound,
      'unavailable' || 'deadline-exceeded' => strings.common.networkFailed,
      _ => strings.common.operationFailed,
    };
  }
  return error.toString();
}

extension DashboardErrors on BuildContext {
  String errorText(Object error) => dashboardErrorMessage(error, this.t);
}
