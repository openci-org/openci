// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_permissions_actions.dart';
import 'app_permissions_administration.dart';
import 'app_permissions_artifact_metadata.dart';
import 'app_permissions_attestations.dart';
import 'app_permissions_checks.dart';
import 'app_permissions_codespaces.dart';
import 'app_permissions_contents.dart';
import 'app_permissions_custom_properties_for_organizations.dart';
import 'app_permissions_dependabot_secrets.dart';
import 'app_permissions_deployments.dart';
import 'app_permissions_discussions.dart';
import 'app_permissions_email_addresses.dart';
import 'app_permissions_enterprise_custom_properties_for_organizations.dart';
import 'app_permissions_environments.dart';
import 'app_permissions_followers.dart';
import 'app_permissions_git_ssh_keys.dart';
import 'app_permissions_gpg_keys.dart';
import 'app_permissions_interaction_limits.dart';
import 'app_permissions_issues.dart';
import 'app_permissions_members.dart';
import 'app_permissions_merge_queues.dart';
import 'app_permissions_metadata.dart';
import 'app_permissions_organization_administration.dart';
import 'app_permissions_organization_announcement_banners.dart';
import 'app_permissions_organization_copilot_agent_settings.dart';
import 'app_permissions_organization_copilot_seat_management.dart';
import 'app_permissions_organization_custom_org_roles.dart';
import 'app_permissions_organization_custom_properties.dart';
import 'app_permissions_organization_custom_roles.dart';
import 'app_permissions_organization_events.dart';
import 'app_permissions_organization_hooks.dart';
import 'app_permissions_organization_packages.dart';
import 'app_permissions_organization_personal_access_token_requests.dart';
import 'app_permissions_organization_personal_access_tokens.dart';
import 'app_permissions_organization_plan.dart';
import 'app_permissions_organization_projects.dart';
import 'app_permissions_organization_secrets.dart';
import 'app_permissions_organization_self_hosted_runners.dart';
import 'app_permissions_organization_user_blocking.dart';
import 'app_permissions_packages.dart';
import 'app_permissions_pages.dart';
import 'app_permissions_profile.dart';
import 'app_permissions_pull_requests.dart';
import 'app_permissions_repository_custom_properties.dart';
import 'app_permissions_repository_hooks.dart';
import 'app_permissions_repository_projects.dart';
import 'app_permissions_secret_scanning_alerts.dart';
import 'app_permissions_secrets.dart';
import 'app_permissions_security_events.dart';
import 'app_permissions_single_file.dart';
import 'app_permissions_starring.dart';
import 'app_permissions_statuses.dart';
import 'app_permissions_vulnerability_alerts.dart';
import 'app_permissions_workflows.dart';

part 'app_permissions.freezed.dart';
part 'app_permissions.g.dart';

/// The permissions granted to the user access token.
@Freezed()
abstract class AppPermissions with _$AppPermissions {
  const factory AppPermissions({
    /// The level of permission to grant the access token to view and edit custom properties for a repository, when allowed by the property.
    @JsonKey(name: 'repository_custom_properties')
    AppPermissionsRepositoryCustomProperties? repositoryCustomProperties,

    /// The level of permission to grant the access token for Repository creation, deletion, settings, teams, and collaborators creation.
    AppPermissionsAdministration? administration,

    /// The level of permission to grant the access token to create and retrieve build Artifact Metadata records.
    @JsonKey(name: 'artifact_metadata')
    AppPermissionsArtifactMetadata? artifactMetadata,

    /// The level of permission to create and retrieve the access token for Repository attestations.
    AppPermissionsAttestations? attestations,

    /// The level of permission to grant the access token for checks on code.
    AppPermissionsChecks? checks,

    /// The level of permission to grant the access token to create, edit, delete, and list Codespaces.
    AppPermissionsCodespaces? codespaces,

    /// The level of permission to grant the access token for Repository contents, commits, branches, downloads, releases, and merges.
    AppPermissionsContents? contents,

    /// The level of permission to grant the access token to manage Dependabot secrets.
    @JsonKey(name: 'dependabot_secrets')
    AppPermissionsDependabotSecrets? dependabotSecrets,

    /// The level of permission to grant the access token for deployments and Deployment statuses.
    AppPermissionsDeployments? deployments,

    /// The level of permission to grant the access token for discussions and related comments and labels.
    AppPermissionsDiscussions? discussions,

    /// The level of permission to grant the access token for managing Repository environments.
    AppPermissionsEnvironments? environments,

    /// The level of permission to grant the access token for issues and related comments, assignees, labels, and milestones.
    AppPermissionsIssues? issues,

    /// The level of permission to grant the access token to manage the merge queues for a repository.
    @JsonKey(name: 'merge_queues') AppPermissionsMergeQueues? mergeQueues,

    /// The level of permission to grant the access token to search repositories, list collaborators, and access Repository metadata.
    @JsonKey(name: 'Metadata') AppPermissionsMetadata? metadata,

    /// The level of permission to grant the access token for packages published to GitHub Packages.
    AppPermissionsPackages? packages,

    /// The level of permission to grant the access token to retrieve Pages statuses, configuration, and builds, as well as create new builds.
    AppPermissionsPages? pages,

    /// The level of permission to grant the access token for pull requests and related comments, assignees, labels, milestones, and merges.
    @JsonKey(name: 'pull_requests') AppPermissionsPullRequests? pullRequests,

    /// The level of permission to grant the access token for GitHub Actions workflows, Workflow runs, and artifacts.
    AppPermissionsActions? actions,

    /// The level of permission to grant the access token to manage the post-receive hooks for a repository.
    @JsonKey(name: 'repository_hooks')
    AppPermissionsRepositoryHooks? repositoryHooks,

    /// The level of permission to grant the access token to manage Repository projects, columns, and cards.
    @JsonKey(name: 'repository_projects')
    AppPermissionsRepositoryProjects? repositoryProjects,

    /// The level of permission to grant the access token to view and manage secret scanning alerts.
    @JsonKey(name: 'secret_scanning_alerts')
    AppPermissionsSecretScanningAlerts? secretScanningAlerts,

    /// The level of permission to grant the access token to manage Repository secrets.
    AppPermissionsSecrets? secrets,

    /// The level of permission to grant the access token to view and manage security events like code scanning alerts.
    @JsonKey(name: 'security_events')
    AppPermissionsSecurityEvents? securityEvents,

    /// The level of permission to grant the access token to manage just a single file.
    @JsonKey(name: 'single_file') AppPermissionsSingleFile? singleFile,

    /// The level of permission to grant the access token for Commit statuses.
    AppPermissionsStatuses? statuses,

    /// The level of permission to grant the access token to manage Dependabot alerts.
    @JsonKey(name: 'vulnerability_alerts')
    AppPermissionsVulnerabilityAlerts? vulnerabilityAlerts,

    /// The level of permission to grant the access token to update GitHub Actions Workflow files.
    AppPermissionsWorkflows? workflows,

    /// The level of permission to grant the access token to view and edit custom properties for an organization, when allowed by the property.
    @JsonKey(name: 'custom_properties_for_organizations')
    AppPermissionsCustomPropertiesForOrganizations?
    customPropertiesForOrganizations,

    /// The level of permission to grant the access token for organization teams and members.
    AppPermissionsMembers? members,

    /// The level of permission to grant the access token to manage access to an organization.
    @JsonKey(name: 'organization_administration')
    AppPermissionsOrganizationAdministration? organizationAdministration,

    /// The level of permission to grant the access token for custom Repository roles management.
    @JsonKey(name: 'organization_custom_roles')
    AppPermissionsOrganizationCustomRoles? organizationCustomRoles,

    /// The level of permission to grant the access token for custom organization roles management.
    @JsonKey(name: 'organization_custom_org_roles')
    AppPermissionsOrganizationCustomOrgRoles? organizationCustomOrgRoles,

    /// The level of permission to grant the access token for Repository custom properties management at the organization level.
    @JsonKey(name: 'organization_custom_properties')
    AppPermissionsOrganizationCustomProperties? organizationCustomProperties,

    /// The level of permission to grant the access token for managing access to GitHub Copilot for members of an organization with a Copilot Business subscription. This property is in public preview and is subject to change.
    @JsonKey(name: 'organization_copilot_seat_management')
    AppPermissionsOrganizationCopilotSeatManagement?
    organizationCopilotSeatManagement,

    /// The level of permission to grant the access token to view and manage Copilot coding agent settings for an organization.
    @JsonKey(name: 'organization_copilot_agent_settings')
    AppPermissionsOrganizationCopilotAgentSettings?
    organizationCopilotAgentSettings,

    /// The level of permission to grant the access token for organization custom properties management at the Enterprise level.
    @JsonKey(name: 'enterprise_custom_properties_for_organizations')
    AppPermissionsEnterpriseCustomPropertiesForOrganizations?
    enterpriseCustomPropertiesForOrganizations,

    /// The level of permission to grant the access token to view events triggered by an Activity in an organization.
    @JsonKey(name: 'organization_events')
    AppPermissionsOrganizationEvents? organizationEvents,

    /// The level of permission to grant the access token to manage the post-receive hooks for an organization.
    @JsonKey(name: 'organization_hooks')
    AppPermissionsOrganizationHooks? organizationHooks,

    /// The level of permission to grant the access token for viewing and managing fine-grained personal access token requests to an organization.
    @JsonKey(name: 'organization_personal_access_tokens')
    AppPermissionsOrganizationPersonalAccessTokens?
    organizationPersonalAccessTokens,

    /// The level of permission to grant the access token for viewing and managing fine-grained personal access tokens that have been approved by an organization.
    @JsonKey(name: 'organization_personal_access_token_requests')
    AppPermissionsOrganizationPersonalAccessTokenRequests?
    organizationPersonalAccessTokenRequests,

    /// The level of permission to grant the access token for viewing an organization's plan.
    @JsonKey(name: 'organization_plan')
    AppPermissionsOrganizationPlan? organizationPlan,

    /// The level of permission to grant the access token to manage organization projects and projects public preview (where available).
    @JsonKey(name: 'organization_projects')
    AppPermissionsOrganizationProjects? organizationProjects,

    /// The level of permission to grant the access token for organization packages published to GitHub Packages.
    @JsonKey(name: 'organization_packages')
    AppPermissionsOrganizationPackages? organizationPackages,

    /// The level of permission to grant the access token to manage organization secrets.
    @JsonKey(name: 'organization_secrets')
    AppPermissionsOrganizationSecrets? organizationSecrets,

    /// The level of permission to grant the access token to view and manage GitHub Actions self-hosted runners available to an organization.
    @JsonKey(name: 'organization_self_hosted_runners')
    AppPermissionsOrganizationSelfHostedRunners? organizationSelfHostedRunners,

    /// The level of permission to grant the access token to view and manage users blocked by the organization.
    @JsonKey(name: 'organization_user_blocking')
    AppPermissionsOrganizationUserBlocking? organizationUserBlocking,

    /// The level of permission to grant the access token to manage the Email addresses belonging to a user.
    @JsonKey(name: 'email_addresses')
    AppPermissionsEmailAddresses? emailAddresses,

    /// The level of permission to grant the access token to manage the followers belonging to a user.
    AppPermissionsFollowers? followers,

    /// The level of permission to grant the access token to manage git SSH keys.
    @JsonKey(name: 'git_ssh_keys') AppPermissionsGitSshKeys? gitSshKeys,

    /// The level of permission to grant the access token to view and manage GPG keys belonging to a user.
    @JsonKey(name: 'gpg_keys') AppPermissionsGpgKeys? gpgKeys,

    /// The level of permission to grant the access token to view and manage interaction limits on a repository.
    @JsonKey(name: 'interaction_limits')
    AppPermissionsInteractionLimits? interactionLimits,

    /// The level of permission to grant the access token to manage the profile settings belonging to a user.
    AppPermissionsProfile? profile,

    /// The level of permission to grant the access token to list and manage repositories a user is starring.
    AppPermissionsStarring? starring,

    /// The level of permission to grant the access token to view and manage announcement banners for an organization.
    @JsonKey(name: 'organization_announcement_banners')
    AppPermissionsOrganizationAnnouncementBanners?
    organizationAnnouncementBanners,
  }) = _AppPermissions;

  factory AppPermissions.fromJson(Map<String, Object?> json) =>
      _$AppPermissionsFromJson(json);
}
