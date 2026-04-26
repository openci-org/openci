# Basic Usage

```dart
DefaultConnector.instance.CreateInvitation(createInvitationVariables).execute();
DefaultConnector.instance.ReinviteInvitation(reinviteInvitationVariables).execute();
DefaultConnector.instance.AcceptInvitation(acceptInvitationVariables).execute();
DefaultConnector.instance.ExpireInvitation(expireInvitationVariables).execute();
DefaultConnector.instance.AcceptInvitationAndJoinTeam(acceptInvitationAndJoinTeamVariables).execute();
DefaultConnector.instance.LinkGitHubInstallation(linkGitHubInstallationVariables).execute();
DefaultConnector.instance.UpsertUserProfile(upsertUserProfileVariables).execute();
DefaultConnector.instance.UpdateCurrentUserSelectedTeam(updateCurrentUserSelectedTeamVariables).execute();
DefaultConnector.instance.UpdateCurrentUserNotificationPreference(updateCurrentUserNotificationPreferenceVariables).execute();
DefaultConnector.instance.UpdateCurrentUserFcmTokens(updateCurrentUserFcmTokensVariables).execute();

```

## Optional Fields

Some operations may have optional fields. In these cases, the Flutter SDK exposes a builder method, and will have to be set separately.

Optional fields can be discovered based on classes that have `Optional` object types.

This is an example of a mutation with an optional field:

```dart
await DefaultConnector.instance.UpdateBuildJobFailureSummary({ ... })
.failureSummary(...)
.execute();
```

Note: the above example is a mutation, but the same logic applies to query operations as well. Additionally, `createMovie` is an example, and may not be available to the user.

