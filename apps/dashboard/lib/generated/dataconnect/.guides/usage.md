# Basic Usage

```dart
DefaultConnector.instance.CreateInvitation(createInvitationVariables).execute();
DefaultConnector.instance.ReinviteInvitation(reinviteInvitationVariables).execute();
DefaultConnector.instance.AcceptInvitation(acceptInvitationVariables).execute();
DefaultConnector.instance.ExpireInvitation(expireInvitationVariables).execute();
DefaultConnector.instance.AddTeamMember(addTeamMemberVariables).execute();
DefaultConnector.instance.AcceptInvitationAndJoinTeam(acceptInvitationAndJoinTeamVariables).execute();
DefaultConnector.instance.GetInvitationByToken(getInvitationByTokenVariables).execute();
DefaultConnector.instance.ListMyPendingInvitations().execute();
DefaultConnector.instance.ListTeamPendingInvitations(listTeamPendingInvitationsVariables).execute();
DefaultConnector.instance.FindExistingPendingInvitation(findExistingPendingInvitationVariables).execute();

```

