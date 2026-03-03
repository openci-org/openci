# Basic Usage

```dart
DashboardConnector.instance.GetMyUser().execute();
DashboardConnector.instance.GetMyTeams(getMyTeamsVariables).execute();
DashboardConnector.instance.CreateUserWithDefaultTeam(createUserWithDefaultTeamVariables).execute();
DashboardConnector.instance.CreateTeam(createTeamVariables).execute();
DashboardConnector.instance.UpdateTeamName(updateTeamNameVariables).execute();
DashboardConnector.instance.UpdateNotificationPreference(updateNotificationPreferenceVariables).execute();
DashboardConnector.instance.AddFcmToken(addFcmTokenVariables).execute();

```

## Optional Fields

Some operations may have optional fields. In these cases, the Flutter SDK exposes a builder method, and will have to be set separately.

Optional fields can be discovered based on classes that have `Optional` object types.

This is an example of a mutation with an optional field:

```dart
await DashboardConnector.instance.CreateUserWithDefaultTeam({ ... })
.teamName(...)
.execute();
```

Note: the above example is a mutation, but the same logic applies to query operations as well. Additionally, `createMovie` is an example, and may not be available to the user.

