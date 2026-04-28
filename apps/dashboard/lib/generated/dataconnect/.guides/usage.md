# Basic Usage

```dart
DefaultConnector.instance.GetInvitationByToken(getInvitationByTokenVariables).execute();
DefaultConnector.instance.ListMyPendingInvitations().execute();
DefaultConnector.instance.GetCurrentUser().execute();
DefaultConnector.instance.ListMyTeams().execute();
DefaultConnector.instance.ListTeamPendingInvitations(listTeamPendingInvitationsVariables).execute();
DefaultConnector.instance.FindExistingPendingInvitation(findExistingPendingInvitationVariables).execute();
DefaultConnector.instance.GetTeamForMember(getTeamForMemberVariables).execute();
DefaultConnector.instance.ListTeamMembers(listTeamMembersVariables).execute();
DefaultConnector.instance.ListTeamNotificationUsers(listTeamNotificationUsersVariables).execute();
DefaultConnector.instance.GetTeamById(getTeamByIdVariables).execute();

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

