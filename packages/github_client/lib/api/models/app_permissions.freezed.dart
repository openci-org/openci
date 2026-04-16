// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_permissions.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppPermissions {

/// The level of permission to grant the access token to view and edit custom properties for a repository, when allowed by the property.
@JsonKey(name: 'repository_custom_properties') AppPermissionsRepositoryCustomProperties? get repositoryCustomProperties;/// The level of permission to grant the access token for Repository creation, deletion, settings, teams, and collaborators creation.
 AppPermissionsAdministration? get administration;/// The level of permission to grant the access token to create and retrieve build Artifact Metadata records.
@JsonKey(name: 'artifact_metadata') AppPermissionsArtifactMetadata? get artifactMetadata;/// The level of permission to create and retrieve the access token for Repository attestations.
 AppPermissionsAttestations? get attestations;/// The level of permission to grant the access token for checks on code.
 AppPermissionsChecks? get checks;/// The level of permission to grant the access token to create, edit, delete, and list Codespaces.
 AppPermissionsCodespaces? get codespaces;/// The level of permission to grant the access token for Repository contents, commits, branches, downloads, releases, and merges.
 AppPermissionsContents? get contents;/// The level of permission to grant the access token to manage Dependabot secrets.
@JsonKey(name: 'dependabot_secrets') AppPermissionsDependabotSecrets? get dependabotSecrets;/// The level of permission to grant the access token for deployments and Deployment statuses.
 AppPermissionsDeployments? get deployments;/// The level of permission to grant the access token for discussions and related comments and labels.
 AppPermissionsDiscussions? get discussions;/// The level of permission to grant the access token for managing Repository environments.
 AppPermissionsEnvironments? get environments;/// The level of permission to grant the access token for issues and related comments, assignees, labels, and milestones.
 AppPermissionsIssues? get issues;/// The level of permission to grant the access token to manage the merge queues for a repository.
@JsonKey(name: 'merge_queues') AppPermissionsMergeQueues? get mergeQueues;/// The level of permission to grant the access token to search repositories, list collaborators, and access Repository metadata.
@JsonKey(name: 'Metadata') AppPermissionsMetadata? get metadata;/// The level of permission to grant the access token for packages published to GitHub Packages.
 AppPermissionsPackages? get packages;/// The level of permission to grant the access token to retrieve Pages statuses, configuration, and builds, as well as create new builds.
 AppPermissionsPages? get pages;/// The level of permission to grant the access token for pull requests and related comments, assignees, labels, milestones, and merges.
@JsonKey(name: 'pull_requests') AppPermissionsPullRequests? get pullRequests;/// The level of permission to grant the access token for GitHub Actions workflows, Workflow runs, and artifacts.
 AppPermissionsActions? get actions;/// The level of permission to grant the access token to manage the post-receive hooks for a repository.
@JsonKey(name: 'repository_hooks') AppPermissionsRepositoryHooks? get repositoryHooks;/// The level of permission to grant the access token to manage Repository projects, columns, and cards.
@JsonKey(name: 'repository_projects') AppPermissionsRepositoryProjects? get repositoryProjects;/// The level of permission to grant the access token to view and manage secret scanning alerts.
@JsonKey(name: 'secret_scanning_alerts') AppPermissionsSecretScanningAlerts? get secretScanningAlerts;/// The level of permission to grant the access token to manage Repository secrets.
 AppPermissionsSecrets? get secrets;/// The level of permission to grant the access token to view and manage security events like code scanning alerts.
@JsonKey(name: 'security_events') AppPermissionsSecurityEvents? get securityEvents;/// The level of permission to grant the access token to manage just a single file.
@JsonKey(name: 'single_file') AppPermissionsSingleFile? get singleFile;/// The level of permission to grant the access token for Commit statuses.
 AppPermissionsStatuses? get statuses;/// The level of permission to grant the access token to manage Dependabot alerts.
@JsonKey(name: 'vulnerability_alerts') AppPermissionsVulnerabilityAlerts? get vulnerabilityAlerts;/// The level of permission to grant the access token to update GitHub Actions Workflow files.
 AppPermissionsWorkflows? get workflows;/// The level of permission to grant the access token to view and edit custom properties for an organization, when allowed by the property.
@JsonKey(name: 'custom_properties_for_organizations') AppPermissionsCustomPropertiesForOrganizations? get customPropertiesForOrganizations;/// The level of permission to grant the access token for organization teams and members.
 AppPermissionsMembers? get members;/// The level of permission to grant the access token to manage access to an organization.
@JsonKey(name: 'organization_administration') AppPermissionsOrganizationAdministration? get organizationAdministration;/// The level of permission to grant the access token for custom Repository roles management.
@JsonKey(name: 'organization_custom_roles') AppPermissionsOrganizationCustomRoles? get organizationCustomRoles;/// The level of permission to grant the access token for custom organization roles management.
@JsonKey(name: 'organization_custom_org_roles') AppPermissionsOrganizationCustomOrgRoles? get organizationCustomOrgRoles;/// The level of permission to grant the access token for Repository custom properties management at the organization level.
@JsonKey(name: 'organization_custom_properties') AppPermissionsOrganizationCustomProperties? get organizationCustomProperties;/// The level of permission to grant the access token for managing access to GitHub Copilot for members of an organization with a Copilot Business subscription. This property is in public preview and is subject to change.
@JsonKey(name: 'organization_copilot_seat_management') AppPermissionsOrganizationCopilotSeatManagement? get organizationCopilotSeatManagement;/// The level of permission to grant the access token to view and manage Copilot coding agent settings for an organization.
@JsonKey(name: 'organization_copilot_agent_settings') AppPermissionsOrganizationCopilotAgentSettings? get organizationCopilotAgentSettings;/// The level of permission to grant the access token for organization custom properties management at the Enterprise level.
@JsonKey(name: 'enterprise_custom_properties_for_organizations') AppPermissionsEnterpriseCustomPropertiesForOrganizations? get enterpriseCustomPropertiesForOrganizations;/// The level of permission to grant the access token to view events triggered by an Activity in an organization.
@JsonKey(name: 'organization_events') AppPermissionsOrganizationEvents? get organizationEvents;/// The level of permission to grant the access token to manage the post-receive hooks for an organization.
@JsonKey(name: 'organization_hooks') AppPermissionsOrganizationHooks? get organizationHooks;/// The level of permission to grant the access token for viewing and managing fine-grained personal access token requests to an organization.
@JsonKey(name: 'organization_personal_access_tokens') AppPermissionsOrganizationPersonalAccessTokens? get organizationPersonalAccessTokens;/// The level of permission to grant the access token for viewing and managing fine-grained personal access tokens that have been approved by an organization.
@JsonKey(name: 'organization_personal_access_token_requests') AppPermissionsOrganizationPersonalAccessTokenRequests? get organizationPersonalAccessTokenRequests;/// The level of permission to grant the access token for viewing an organization's plan.
@JsonKey(name: 'organization_plan') AppPermissionsOrganizationPlan? get organizationPlan;/// The level of permission to grant the access token to manage organization projects and projects public preview (where available).
@JsonKey(name: 'organization_projects') AppPermissionsOrganizationProjects? get organizationProjects;/// The level of permission to grant the access token for organization packages published to GitHub Packages.
@JsonKey(name: 'organization_packages') AppPermissionsOrganizationPackages? get organizationPackages;/// The level of permission to grant the access token to manage organization secrets.
@JsonKey(name: 'organization_secrets') AppPermissionsOrganizationSecrets? get organizationSecrets;/// The level of permission to grant the access token to view and manage GitHub Actions self-hosted runners available to an organization.
@JsonKey(name: 'organization_self_hosted_runners') AppPermissionsOrganizationSelfHostedRunners? get organizationSelfHostedRunners;/// The level of permission to grant the access token to view and manage users blocked by the organization.
@JsonKey(name: 'organization_user_blocking') AppPermissionsOrganizationUserBlocking? get organizationUserBlocking;/// The level of permission to grant the access token to manage the Email addresses belonging to a user.
@JsonKey(name: 'email_addresses') AppPermissionsEmailAddresses? get emailAddresses;/// The level of permission to grant the access token to manage the followers belonging to a user.
 AppPermissionsFollowers? get followers;/// The level of permission to grant the access token to manage git SSH keys.
@JsonKey(name: 'git_ssh_keys') AppPermissionsGitSshKeys? get gitSshKeys;/// The level of permission to grant the access token to view and manage GPG keys belonging to a user.
@JsonKey(name: 'gpg_keys') AppPermissionsGpgKeys? get gpgKeys;/// The level of permission to grant the access token to view and manage interaction limits on a repository.
@JsonKey(name: 'interaction_limits') AppPermissionsInteractionLimits? get interactionLimits;/// The level of permission to grant the access token to manage the profile settings belonging to a user.
 AppPermissionsProfile? get profile;/// The level of permission to grant the access token to list and manage repositories a user is starring.
 AppPermissionsStarring? get starring;/// The level of permission to grant the access token to view and manage announcement banners for an organization.
@JsonKey(name: 'organization_announcement_banners') AppPermissionsOrganizationAnnouncementBanners? get organizationAnnouncementBanners;
/// Create a copy of AppPermissions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppPermissionsCopyWith<AppPermissions> get copyWith => _$AppPermissionsCopyWithImpl<AppPermissions>(this as AppPermissions, _$identity);

  /// Serializes this AppPermissions to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppPermissions&&(identical(other.repositoryCustomProperties, repositoryCustomProperties) || other.repositoryCustomProperties == repositoryCustomProperties)&&(identical(other.administration, administration) || other.administration == administration)&&(identical(other.artifactMetadata, artifactMetadata) || other.artifactMetadata == artifactMetadata)&&(identical(other.attestations, attestations) || other.attestations == attestations)&&(identical(other.checks, checks) || other.checks == checks)&&(identical(other.codespaces, codespaces) || other.codespaces == codespaces)&&(identical(other.contents, contents) || other.contents == contents)&&(identical(other.dependabotSecrets, dependabotSecrets) || other.dependabotSecrets == dependabotSecrets)&&(identical(other.deployments, deployments) || other.deployments == deployments)&&(identical(other.discussions, discussions) || other.discussions == discussions)&&(identical(other.environments, environments) || other.environments == environments)&&(identical(other.issues, issues) || other.issues == issues)&&(identical(other.mergeQueues, mergeQueues) || other.mergeQueues == mergeQueues)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&(identical(other.packages, packages) || other.packages == packages)&&(identical(other.pages, pages) || other.pages == pages)&&(identical(other.pullRequests, pullRequests) || other.pullRequests == pullRequests)&&(identical(other.actions, actions) || other.actions == actions)&&(identical(other.repositoryHooks, repositoryHooks) || other.repositoryHooks == repositoryHooks)&&(identical(other.repositoryProjects, repositoryProjects) || other.repositoryProjects == repositoryProjects)&&(identical(other.secretScanningAlerts, secretScanningAlerts) || other.secretScanningAlerts == secretScanningAlerts)&&(identical(other.secrets, secrets) || other.secrets == secrets)&&(identical(other.securityEvents, securityEvents) || other.securityEvents == securityEvents)&&(identical(other.singleFile, singleFile) || other.singleFile == singleFile)&&(identical(other.statuses, statuses) || other.statuses == statuses)&&(identical(other.vulnerabilityAlerts, vulnerabilityAlerts) || other.vulnerabilityAlerts == vulnerabilityAlerts)&&(identical(other.workflows, workflows) || other.workflows == workflows)&&(identical(other.customPropertiesForOrganizations, customPropertiesForOrganizations) || other.customPropertiesForOrganizations == customPropertiesForOrganizations)&&(identical(other.members, members) || other.members == members)&&(identical(other.organizationAdministration, organizationAdministration) || other.organizationAdministration == organizationAdministration)&&(identical(other.organizationCustomRoles, organizationCustomRoles) || other.organizationCustomRoles == organizationCustomRoles)&&(identical(other.organizationCustomOrgRoles, organizationCustomOrgRoles) || other.organizationCustomOrgRoles == organizationCustomOrgRoles)&&(identical(other.organizationCustomProperties, organizationCustomProperties) || other.organizationCustomProperties == organizationCustomProperties)&&(identical(other.organizationCopilotSeatManagement, organizationCopilotSeatManagement) || other.organizationCopilotSeatManagement == organizationCopilotSeatManagement)&&(identical(other.organizationCopilotAgentSettings, organizationCopilotAgentSettings) || other.organizationCopilotAgentSettings == organizationCopilotAgentSettings)&&(identical(other.enterpriseCustomPropertiesForOrganizations, enterpriseCustomPropertiesForOrganizations) || other.enterpriseCustomPropertiesForOrganizations == enterpriseCustomPropertiesForOrganizations)&&(identical(other.organizationEvents, organizationEvents) || other.organizationEvents == organizationEvents)&&(identical(other.organizationHooks, organizationHooks) || other.organizationHooks == organizationHooks)&&(identical(other.organizationPersonalAccessTokens, organizationPersonalAccessTokens) || other.organizationPersonalAccessTokens == organizationPersonalAccessTokens)&&(identical(other.organizationPersonalAccessTokenRequests, organizationPersonalAccessTokenRequests) || other.organizationPersonalAccessTokenRequests == organizationPersonalAccessTokenRequests)&&(identical(other.organizationPlan, organizationPlan) || other.organizationPlan == organizationPlan)&&(identical(other.organizationProjects, organizationProjects) || other.organizationProjects == organizationProjects)&&(identical(other.organizationPackages, organizationPackages) || other.organizationPackages == organizationPackages)&&(identical(other.organizationSecrets, organizationSecrets) || other.organizationSecrets == organizationSecrets)&&(identical(other.organizationSelfHostedRunners, organizationSelfHostedRunners) || other.organizationSelfHostedRunners == organizationSelfHostedRunners)&&(identical(other.organizationUserBlocking, organizationUserBlocking) || other.organizationUserBlocking == organizationUserBlocking)&&(identical(other.emailAddresses, emailAddresses) || other.emailAddresses == emailAddresses)&&(identical(other.followers, followers) || other.followers == followers)&&(identical(other.gitSshKeys, gitSshKeys) || other.gitSshKeys == gitSshKeys)&&(identical(other.gpgKeys, gpgKeys) || other.gpgKeys == gpgKeys)&&(identical(other.interactionLimits, interactionLimits) || other.interactionLimits == interactionLimits)&&(identical(other.profile, profile) || other.profile == profile)&&(identical(other.starring, starring) || other.starring == starring)&&(identical(other.organizationAnnouncementBanners, organizationAnnouncementBanners) || other.organizationAnnouncementBanners == organizationAnnouncementBanners));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,repositoryCustomProperties,administration,artifactMetadata,attestations,checks,codespaces,contents,dependabotSecrets,deployments,discussions,environments,issues,mergeQueues,metadata,packages,pages,pullRequests,actions,repositoryHooks,repositoryProjects,secretScanningAlerts,secrets,securityEvents,singleFile,statuses,vulnerabilityAlerts,workflows,customPropertiesForOrganizations,members,organizationAdministration,organizationCustomRoles,organizationCustomOrgRoles,organizationCustomProperties,organizationCopilotSeatManagement,organizationCopilotAgentSettings,enterpriseCustomPropertiesForOrganizations,organizationEvents,organizationHooks,organizationPersonalAccessTokens,organizationPersonalAccessTokenRequests,organizationPlan,organizationProjects,organizationPackages,organizationSecrets,organizationSelfHostedRunners,organizationUserBlocking,emailAddresses,followers,gitSshKeys,gpgKeys,interactionLimits,profile,starring,organizationAnnouncementBanners]);

@override
String toString() {
  return 'AppPermissions(repositoryCustomProperties: $repositoryCustomProperties, administration: $administration, artifactMetadata: $artifactMetadata, attestations: $attestations, checks: $checks, codespaces: $codespaces, contents: $contents, dependabotSecrets: $dependabotSecrets, deployments: $deployments, discussions: $discussions, environments: $environments, issues: $issues, mergeQueues: $mergeQueues, metadata: $metadata, packages: $packages, pages: $pages, pullRequests: $pullRequests, actions: $actions, repositoryHooks: $repositoryHooks, repositoryProjects: $repositoryProjects, secretScanningAlerts: $secretScanningAlerts, secrets: $secrets, securityEvents: $securityEvents, singleFile: $singleFile, statuses: $statuses, vulnerabilityAlerts: $vulnerabilityAlerts, workflows: $workflows, customPropertiesForOrganizations: $customPropertiesForOrganizations, members: $members, organizationAdministration: $organizationAdministration, organizationCustomRoles: $organizationCustomRoles, organizationCustomOrgRoles: $organizationCustomOrgRoles, organizationCustomProperties: $organizationCustomProperties, organizationCopilotSeatManagement: $organizationCopilotSeatManagement, organizationCopilotAgentSettings: $organizationCopilotAgentSettings, enterpriseCustomPropertiesForOrganizations: $enterpriseCustomPropertiesForOrganizations, organizationEvents: $organizationEvents, organizationHooks: $organizationHooks, organizationPersonalAccessTokens: $organizationPersonalAccessTokens, organizationPersonalAccessTokenRequests: $organizationPersonalAccessTokenRequests, organizationPlan: $organizationPlan, organizationProjects: $organizationProjects, organizationPackages: $organizationPackages, organizationSecrets: $organizationSecrets, organizationSelfHostedRunners: $organizationSelfHostedRunners, organizationUserBlocking: $organizationUserBlocking, emailAddresses: $emailAddresses, followers: $followers, gitSshKeys: $gitSshKeys, gpgKeys: $gpgKeys, interactionLimits: $interactionLimits, profile: $profile, starring: $starring, organizationAnnouncementBanners: $organizationAnnouncementBanners)';
}


}

/// @nodoc
abstract mixin class $AppPermissionsCopyWith<$Res>  {
  factory $AppPermissionsCopyWith(AppPermissions value, $Res Function(AppPermissions) _then) = _$AppPermissionsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'repository_custom_properties') AppPermissionsRepositoryCustomProperties? repositoryCustomProperties, AppPermissionsAdministration? administration,@JsonKey(name: 'artifact_metadata') AppPermissionsArtifactMetadata? artifactMetadata, AppPermissionsAttestations? attestations, AppPermissionsChecks? checks, AppPermissionsCodespaces? codespaces, AppPermissionsContents? contents,@JsonKey(name: 'dependabot_secrets') AppPermissionsDependabotSecrets? dependabotSecrets, AppPermissionsDeployments? deployments, AppPermissionsDiscussions? discussions, AppPermissionsEnvironments? environments, AppPermissionsIssues? issues,@JsonKey(name: 'merge_queues') AppPermissionsMergeQueues? mergeQueues,@JsonKey(name: 'Metadata') AppPermissionsMetadata? metadata, AppPermissionsPackages? packages, AppPermissionsPages? pages,@JsonKey(name: 'pull_requests') AppPermissionsPullRequests? pullRequests, AppPermissionsActions? actions,@JsonKey(name: 'repository_hooks') AppPermissionsRepositoryHooks? repositoryHooks,@JsonKey(name: 'repository_projects') AppPermissionsRepositoryProjects? repositoryProjects,@JsonKey(name: 'secret_scanning_alerts') AppPermissionsSecretScanningAlerts? secretScanningAlerts, AppPermissionsSecrets? secrets,@JsonKey(name: 'security_events') AppPermissionsSecurityEvents? securityEvents,@JsonKey(name: 'single_file') AppPermissionsSingleFile? singleFile, AppPermissionsStatuses? statuses,@JsonKey(name: 'vulnerability_alerts') AppPermissionsVulnerabilityAlerts? vulnerabilityAlerts, AppPermissionsWorkflows? workflows,@JsonKey(name: 'custom_properties_for_organizations') AppPermissionsCustomPropertiesForOrganizations? customPropertiesForOrganizations, AppPermissionsMembers? members,@JsonKey(name: 'organization_administration') AppPermissionsOrganizationAdministration? organizationAdministration,@JsonKey(name: 'organization_custom_roles') AppPermissionsOrganizationCustomRoles? organizationCustomRoles,@JsonKey(name: 'organization_custom_org_roles') AppPermissionsOrganizationCustomOrgRoles? organizationCustomOrgRoles,@JsonKey(name: 'organization_custom_properties') AppPermissionsOrganizationCustomProperties? organizationCustomProperties,@JsonKey(name: 'organization_copilot_seat_management') AppPermissionsOrganizationCopilotSeatManagement? organizationCopilotSeatManagement,@JsonKey(name: 'organization_copilot_agent_settings') AppPermissionsOrganizationCopilotAgentSettings? organizationCopilotAgentSettings,@JsonKey(name: 'enterprise_custom_properties_for_organizations') AppPermissionsEnterpriseCustomPropertiesForOrganizations? enterpriseCustomPropertiesForOrganizations,@JsonKey(name: 'organization_events') AppPermissionsOrganizationEvents? organizationEvents,@JsonKey(name: 'organization_hooks') AppPermissionsOrganizationHooks? organizationHooks,@JsonKey(name: 'organization_personal_access_tokens') AppPermissionsOrganizationPersonalAccessTokens? organizationPersonalAccessTokens,@JsonKey(name: 'organization_personal_access_token_requests') AppPermissionsOrganizationPersonalAccessTokenRequests? organizationPersonalAccessTokenRequests,@JsonKey(name: 'organization_plan') AppPermissionsOrganizationPlan? organizationPlan,@JsonKey(name: 'organization_projects') AppPermissionsOrganizationProjects? organizationProjects,@JsonKey(name: 'organization_packages') AppPermissionsOrganizationPackages? organizationPackages,@JsonKey(name: 'organization_secrets') AppPermissionsOrganizationSecrets? organizationSecrets,@JsonKey(name: 'organization_self_hosted_runners') AppPermissionsOrganizationSelfHostedRunners? organizationSelfHostedRunners,@JsonKey(name: 'organization_user_blocking') AppPermissionsOrganizationUserBlocking? organizationUserBlocking,@JsonKey(name: 'email_addresses') AppPermissionsEmailAddresses? emailAddresses, AppPermissionsFollowers? followers,@JsonKey(name: 'git_ssh_keys') AppPermissionsGitSshKeys? gitSshKeys,@JsonKey(name: 'gpg_keys') AppPermissionsGpgKeys? gpgKeys,@JsonKey(name: 'interaction_limits') AppPermissionsInteractionLimits? interactionLimits, AppPermissionsProfile? profile, AppPermissionsStarring? starring,@JsonKey(name: 'organization_announcement_banners') AppPermissionsOrganizationAnnouncementBanners? organizationAnnouncementBanners
});




}
/// @nodoc
class _$AppPermissionsCopyWithImpl<$Res>
    implements $AppPermissionsCopyWith<$Res> {
  _$AppPermissionsCopyWithImpl(this._self, this._then);

  final AppPermissions _self;
  final $Res Function(AppPermissions) _then;

/// Create a copy of AppPermissions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? repositoryCustomProperties = freezed,Object? administration = freezed,Object? artifactMetadata = freezed,Object? attestations = freezed,Object? checks = freezed,Object? codespaces = freezed,Object? contents = freezed,Object? dependabotSecrets = freezed,Object? deployments = freezed,Object? discussions = freezed,Object? environments = freezed,Object? issues = freezed,Object? mergeQueues = freezed,Object? metadata = freezed,Object? packages = freezed,Object? pages = freezed,Object? pullRequests = freezed,Object? actions = freezed,Object? repositoryHooks = freezed,Object? repositoryProjects = freezed,Object? secretScanningAlerts = freezed,Object? secrets = freezed,Object? securityEvents = freezed,Object? singleFile = freezed,Object? statuses = freezed,Object? vulnerabilityAlerts = freezed,Object? workflows = freezed,Object? customPropertiesForOrganizations = freezed,Object? members = freezed,Object? organizationAdministration = freezed,Object? organizationCustomRoles = freezed,Object? organizationCustomOrgRoles = freezed,Object? organizationCustomProperties = freezed,Object? organizationCopilotSeatManagement = freezed,Object? organizationCopilotAgentSettings = freezed,Object? enterpriseCustomPropertiesForOrganizations = freezed,Object? organizationEvents = freezed,Object? organizationHooks = freezed,Object? organizationPersonalAccessTokens = freezed,Object? organizationPersonalAccessTokenRequests = freezed,Object? organizationPlan = freezed,Object? organizationProjects = freezed,Object? organizationPackages = freezed,Object? organizationSecrets = freezed,Object? organizationSelfHostedRunners = freezed,Object? organizationUserBlocking = freezed,Object? emailAddresses = freezed,Object? followers = freezed,Object? gitSshKeys = freezed,Object? gpgKeys = freezed,Object? interactionLimits = freezed,Object? profile = freezed,Object? starring = freezed,Object? organizationAnnouncementBanners = freezed,}) {
  return _then(_self.copyWith(
repositoryCustomProperties: freezed == repositoryCustomProperties ? _self.repositoryCustomProperties : repositoryCustomProperties // ignore: cast_nullable_to_non_nullable
as AppPermissionsRepositoryCustomProperties?,administration: freezed == administration ? _self.administration : administration // ignore: cast_nullable_to_non_nullable
as AppPermissionsAdministration?,artifactMetadata: freezed == artifactMetadata ? _self.artifactMetadata : artifactMetadata // ignore: cast_nullable_to_non_nullable
as AppPermissionsArtifactMetadata?,attestations: freezed == attestations ? _self.attestations : attestations // ignore: cast_nullable_to_non_nullable
as AppPermissionsAttestations?,checks: freezed == checks ? _self.checks : checks // ignore: cast_nullable_to_non_nullable
as AppPermissionsChecks?,codespaces: freezed == codespaces ? _self.codespaces : codespaces // ignore: cast_nullable_to_non_nullable
as AppPermissionsCodespaces?,contents: freezed == contents ? _self.contents : contents // ignore: cast_nullable_to_non_nullable
as AppPermissionsContents?,dependabotSecrets: freezed == dependabotSecrets ? _self.dependabotSecrets : dependabotSecrets // ignore: cast_nullable_to_non_nullable
as AppPermissionsDependabotSecrets?,deployments: freezed == deployments ? _self.deployments : deployments // ignore: cast_nullable_to_non_nullable
as AppPermissionsDeployments?,discussions: freezed == discussions ? _self.discussions : discussions // ignore: cast_nullable_to_non_nullable
as AppPermissionsDiscussions?,environments: freezed == environments ? _self.environments : environments // ignore: cast_nullable_to_non_nullable
as AppPermissionsEnvironments?,issues: freezed == issues ? _self.issues : issues // ignore: cast_nullable_to_non_nullable
as AppPermissionsIssues?,mergeQueues: freezed == mergeQueues ? _self.mergeQueues : mergeQueues // ignore: cast_nullable_to_non_nullable
as AppPermissionsMergeQueues?,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as AppPermissionsMetadata?,packages: freezed == packages ? _self.packages : packages // ignore: cast_nullable_to_non_nullable
as AppPermissionsPackages?,pages: freezed == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as AppPermissionsPages?,pullRequests: freezed == pullRequests ? _self.pullRequests : pullRequests // ignore: cast_nullable_to_non_nullable
as AppPermissionsPullRequests?,actions: freezed == actions ? _self.actions : actions // ignore: cast_nullable_to_non_nullable
as AppPermissionsActions?,repositoryHooks: freezed == repositoryHooks ? _self.repositoryHooks : repositoryHooks // ignore: cast_nullable_to_non_nullable
as AppPermissionsRepositoryHooks?,repositoryProjects: freezed == repositoryProjects ? _self.repositoryProjects : repositoryProjects // ignore: cast_nullable_to_non_nullable
as AppPermissionsRepositoryProjects?,secretScanningAlerts: freezed == secretScanningAlerts ? _self.secretScanningAlerts : secretScanningAlerts // ignore: cast_nullable_to_non_nullable
as AppPermissionsSecretScanningAlerts?,secrets: freezed == secrets ? _self.secrets : secrets // ignore: cast_nullable_to_non_nullable
as AppPermissionsSecrets?,securityEvents: freezed == securityEvents ? _self.securityEvents : securityEvents // ignore: cast_nullable_to_non_nullable
as AppPermissionsSecurityEvents?,singleFile: freezed == singleFile ? _self.singleFile : singleFile // ignore: cast_nullable_to_non_nullable
as AppPermissionsSingleFile?,statuses: freezed == statuses ? _self.statuses : statuses // ignore: cast_nullable_to_non_nullable
as AppPermissionsStatuses?,vulnerabilityAlerts: freezed == vulnerabilityAlerts ? _self.vulnerabilityAlerts : vulnerabilityAlerts // ignore: cast_nullable_to_non_nullable
as AppPermissionsVulnerabilityAlerts?,workflows: freezed == workflows ? _self.workflows : workflows // ignore: cast_nullable_to_non_nullable
as AppPermissionsWorkflows?,customPropertiesForOrganizations: freezed == customPropertiesForOrganizations ? _self.customPropertiesForOrganizations : customPropertiesForOrganizations // ignore: cast_nullable_to_non_nullable
as AppPermissionsCustomPropertiesForOrganizations?,members: freezed == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as AppPermissionsMembers?,organizationAdministration: freezed == organizationAdministration ? _self.organizationAdministration : organizationAdministration // ignore: cast_nullable_to_non_nullable
as AppPermissionsOrganizationAdministration?,organizationCustomRoles: freezed == organizationCustomRoles ? _self.organizationCustomRoles : organizationCustomRoles // ignore: cast_nullable_to_non_nullable
as AppPermissionsOrganizationCustomRoles?,organizationCustomOrgRoles: freezed == organizationCustomOrgRoles ? _self.organizationCustomOrgRoles : organizationCustomOrgRoles // ignore: cast_nullable_to_non_nullable
as AppPermissionsOrganizationCustomOrgRoles?,organizationCustomProperties: freezed == organizationCustomProperties ? _self.organizationCustomProperties : organizationCustomProperties // ignore: cast_nullable_to_non_nullable
as AppPermissionsOrganizationCustomProperties?,organizationCopilotSeatManagement: freezed == organizationCopilotSeatManagement ? _self.organizationCopilotSeatManagement : organizationCopilotSeatManagement // ignore: cast_nullable_to_non_nullable
as AppPermissionsOrganizationCopilotSeatManagement?,organizationCopilotAgentSettings: freezed == organizationCopilotAgentSettings ? _self.organizationCopilotAgentSettings : organizationCopilotAgentSettings // ignore: cast_nullable_to_non_nullable
as AppPermissionsOrganizationCopilotAgentSettings?,enterpriseCustomPropertiesForOrganizations: freezed == enterpriseCustomPropertiesForOrganizations ? _self.enterpriseCustomPropertiesForOrganizations : enterpriseCustomPropertiesForOrganizations // ignore: cast_nullable_to_non_nullable
as AppPermissionsEnterpriseCustomPropertiesForOrganizations?,organizationEvents: freezed == organizationEvents ? _self.organizationEvents : organizationEvents // ignore: cast_nullable_to_non_nullable
as AppPermissionsOrganizationEvents?,organizationHooks: freezed == organizationHooks ? _self.organizationHooks : organizationHooks // ignore: cast_nullable_to_non_nullable
as AppPermissionsOrganizationHooks?,organizationPersonalAccessTokens: freezed == organizationPersonalAccessTokens ? _self.organizationPersonalAccessTokens : organizationPersonalAccessTokens // ignore: cast_nullable_to_non_nullable
as AppPermissionsOrganizationPersonalAccessTokens?,organizationPersonalAccessTokenRequests: freezed == organizationPersonalAccessTokenRequests ? _self.organizationPersonalAccessTokenRequests : organizationPersonalAccessTokenRequests // ignore: cast_nullable_to_non_nullable
as AppPermissionsOrganizationPersonalAccessTokenRequests?,organizationPlan: freezed == organizationPlan ? _self.organizationPlan : organizationPlan // ignore: cast_nullable_to_non_nullable
as AppPermissionsOrganizationPlan?,organizationProjects: freezed == organizationProjects ? _self.organizationProjects : organizationProjects // ignore: cast_nullable_to_non_nullable
as AppPermissionsOrganizationProjects?,organizationPackages: freezed == organizationPackages ? _self.organizationPackages : organizationPackages // ignore: cast_nullable_to_non_nullable
as AppPermissionsOrganizationPackages?,organizationSecrets: freezed == organizationSecrets ? _self.organizationSecrets : organizationSecrets // ignore: cast_nullable_to_non_nullable
as AppPermissionsOrganizationSecrets?,organizationSelfHostedRunners: freezed == organizationSelfHostedRunners ? _self.organizationSelfHostedRunners : organizationSelfHostedRunners // ignore: cast_nullable_to_non_nullable
as AppPermissionsOrganizationSelfHostedRunners?,organizationUserBlocking: freezed == organizationUserBlocking ? _self.organizationUserBlocking : organizationUserBlocking // ignore: cast_nullable_to_non_nullable
as AppPermissionsOrganizationUserBlocking?,emailAddresses: freezed == emailAddresses ? _self.emailAddresses : emailAddresses // ignore: cast_nullable_to_non_nullable
as AppPermissionsEmailAddresses?,followers: freezed == followers ? _self.followers : followers // ignore: cast_nullable_to_non_nullable
as AppPermissionsFollowers?,gitSshKeys: freezed == gitSshKeys ? _self.gitSshKeys : gitSshKeys // ignore: cast_nullable_to_non_nullable
as AppPermissionsGitSshKeys?,gpgKeys: freezed == gpgKeys ? _self.gpgKeys : gpgKeys // ignore: cast_nullable_to_non_nullable
as AppPermissionsGpgKeys?,interactionLimits: freezed == interactionLimits ? _self.interactionLimits : interactionLimits // ignore: cast_nullable_to_non_nullable
as AppPermissionsInteractionLimits?,profile: freezed == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as AppPermissionsProfile?,starring: freezed == starring ? _self.starring : starring // ignore: cast_nullable_to_non_nullable
as AppPermissionsStarring?,organizationAnnouncementBanners: freezed == organizationAnnouncementBanners ? _self.organizationAnnouncementBanners : organizationAnnouncementBanners // ignore: cast_nullable_to_non_nullable
as AppPermissionsOrganizationAnnouncementBanners?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppPermissions].
extension AppPermissionsPatterns on AppPermissions {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppPermissions value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppPermissions() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppPermissions value)  $default,){
final _that = this;
switch (_that) {
case _AppPermissions():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppPermissions value)?  $default,){
final _that = this;
switch (_that) {
case _AppPermissions() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'repository_custom_properties')  AppPermissionsRepositoryCustomProperties? repositoryCustomProperties,  AppPermissionsAdministration? administration, @JsonKey(name: 'artifact_metadata')  AppPermissionsArtifactMetadata? artifactMetadata,  AppPermissionsAttestations? attestations,  AppPermissionsChecks? checks,  AppPermissionsCodespaces? codespaces,  AppPermissionsContents? contents, @JsonKey(name: 'dependabot_secrets')  AppPermissionsDependabotSecrets? dependabotSecrets,  AppPermissionsDeployments? deployments,  AppPermissionsDiscussions? discussions,  AppPermissionsEnvironments? environments,  AppPermissionsIssues? issues, @JsonKey(name: 'merge_queues')  AppPermissionsMergeQueues? mergeQueues, @JsonKey(name: 'Metadata')  AppPermissionsMetadata? metadata,  AppPermissionsPackages? packages,  AppPermissionsPages? pages, @JsonKey(name: 'pull_requests')  AppPermissionsPullRequests? pullRequests,  AppPermissionsActions? actions, @JsonKey(name: 'repository_hooks')  AppPermissionsRepositoryHooks? repositoryHooks, @JsonKey(name: 'repository_projects')  AppPermissionsRepositoryProjects? repositoryProjects, @JsonKey(name: 'secret_scanning_alerts')  AppPermissionsSecretScanningAlerts? secretScanningAlerts,  AppPermissionsSecrets? secrets, @JsonKey(name: 'security_events')  AppPermissionsSecurityEvents? securityEvents, @JsonKey(name: 'single_file')  AppPermissionsSingleFile? singleFile,  AppPermissionsStatuses? statuses, @JsonKey(name: 'vulnerability_alerts')  AppPermissionsVulnerabilityAlerts? vulnerabilityAlerts,  AppPermissionsWorkflows? workflows, @JsonKey(name: 'custom_properties_for_organizations')  AppPermissionsCustomPropertiesForOrganizations? customPropertiesForOrganizations,  AppPermissionsMembers? members, @JsonKey(name: 'organization_administration')  AppPermissionsOrganizationAdministration? organizationAdministration, @JsonKey(name: 'organization_custom_roles')  AppPermissionsOrganizationCustomRoles? organizationCustomRoles, @JsonKey(name: 'organization_custom_org_roles')  AppPermissionsOrganizationCustomOrgRoles? organizationCustomOrgRoles, @JsonKey(name: 'organization_custom_properties')  AppPermissionsOrganizationCustomProperties? organizationCustomProperties, @JsonKey(name: 'organization_copilot_seat_management')  AppPermissionsOrganizationCopilotSeatManagement? organizationCopilotSeatManagement, @JsonKey(name: 'organization_copilot_agent_settings')  AppPermissionsOrganizationCopilotAgentSettings? organizationCopilotAgentSettings, @JsonKey(name: 'enterprise_custom_properties_for_organizations')  AppPermissionsEnterpriseCustomPropertiesForOrganizations? enterpriseCustomPropertiesForOrganizations, @JsonKey(name: 'organization_events')  AppPermissionsOrganizationEvents? organizationEvents, @JsonKey(name: 'organization_hooks')  AppPermissionsOrganizationHooks? organizationHooks, @JsonKey(name: 'organization_personal_access_tokens')  AppPermissionsOrganizationPersonalAccessTokens? organizationPersonalAccessTokens, @JsonKey(name: 'organization_personal_access_token_requests')  AppPermissionsOrganizationPersonalAccessTokenRequests? organizationPersonalAccessTokenRequests, @JsonKey(name: 'organization_plan')  AppPermissionsOrganizationPlan? organizationPlan, @JsonKey(name: 'organization_projects')  AppPermissionsOrganizationProjects? organizationProjects, @JsonKey(name: 'organization_packages')  AppPermissionsOrganizationPackages? organizationPackages, @JsonKey(name: 'organization_secrets')  AppPermissionsOrganizationSecrets? organizationSecrets, @JsonKey(name: 'organization_self_hosted_runners')  AppPermissionsOrganizationSelfHostedRunners? organizationSelfHostedRunners, @JsonKey(name: 'organization_user_blocking')  AppPermissionsOrganizationUserBlocking? organizationUserBlocking, @JsonKey(name: 'email_addresses')  AppPermissionsEmailAddresses? emailAddresses,  AppPermissionsFollowers? followers, @JsonKey(name: 'git_ssh_keys')  AppPermissionsGitSshKeys? gitSshKeys, @JsonKey(name: 'gpg_keys')  AppPermissionsGpgKeys? gpgKeys, @JsonKey(name: 'interaction_limits')  AppPermissionsInteractionLimits? interactionLimits,  AppPermissionsProfile? profile,  AppPermissionsStarring? starring, @JsonKey(name: 'organization_announcement_banners')  AppPermissionsOrganizationAnnouncementBanners? organizationAnnouncementBanners)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppPermissions() when $default != null:
return $default(_that.repositoryCustomProperties,_that.administration,_that.artifactMetadata,_that.attestations,_that.checks,_that.codespaces,_that.contents,_that.dependabotSecrets,_that.deployments,_that.discussions,_that.environments,_that.issues,_that.mergeQueues,_that.metadata,_that.packages,_that.pages,_that.pullRequests,_that.actions,_that.repositoryHooks,_that.repositoryProjects,_that.secretScanningAlerts,_that.secrets,_that.securityEvents,_that.singleFile,_that.statuses,_that.vulnerabilityAlerts,_that.workflows,_that.customPropertiesForOrganizations,_that.members,_that.organizationAdministration,_that.organizationCustomRoles,_that.organizationCustomOrgRoles,_that.organizationCustomProperties,_that.organizationCopilotSeatManagement,_that.organizationCopilotAgentSettings,_that.enterpriseCustomPropertiesForOrganizations,_that.organizationEvents,_that.organizationHooks,_that.organizationPersonalAccessTokens,_that.organizationPersonalAccessTokenRequests,_that.organizationPlan,_that.organizationProjects,_that.organizationPackages,_that.organizationSecrets,_that.organizationSelfHostedRunners,_that.organizationUserBlocking,_that.emailAddresses,_that.followers,_that.gitSshKeys,_that.gpgKeys,_that.interactionLimits,_that.profile,_that.starring,_that.organizationAnnouncementBanners);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'repository_custom_properties')  AppPermissionsRepositoryCustomProperties? repositoryCustomProperties,  AppPermissionsAdministration? administration, @JsonKey(name: 'artifact_metadata')  AppPermissionsArtifactMetadata? artifactMetadata,  AppPermissionsAttestations? attestations,  AppPermissionsChecks? checks,  AppPermissionsCodespaces? codespaces,  AppPermissionsContents? contents, @JsonKey(name: 'dependabot_secrets')  AppPermissionsDependabotSecrets? dependabotSecrets,  AppPermissionsDeployments? deployments,  AppPermissionsDiscussions? discussions,  AppPermissionsEnvironments? environments,  AppPermissionsIssues? issues, @JsonKey(name: 'merge_queues')  AppPermissionsMergeQueues? mergeQueues, @JsonKey(name: 'Metadata')  AppPermissionsMetadata? metadata,  AppPermissionsPackages? packages,  AppPermissionsPages? pages, @JsonKey(name: 'pull_requests')  AppPermissionsPullRequests? pullRequests,  AppPermissionsActions? actions, @JsonKey(name: 'repository_hooks')  AppPermissionsRepositoryHooks? repositoryHooks, @JsonKey(name: 'repository_projects')  AppPermissionsRepositoryProjects? repositoryProjects, @JsonKey(name: 'secret_scanning_alerts')  AppPermissionsSecretScanningAlerts? secretScanningAlerts,  AppPermissionsSecrets? secrets, @JsonKey(name: 'security_events')  AppPermissionsSecurityEvents? securityEvents, @JsonKey(name: 'single_file')  AppPermissionsSingleFile? singleFile,  AppPermissionsStatuses? statuses, @JsonKey(name: 'vulnerability_alerts')  AppPermissionsVulnerabilityAlerts? vulnerabilityAlerts,  AppPermissionsWorkflows? workflows, @JsonKey(name: 'custom_properties_for_organizations')  AppPermissionsCustomPropertiesForOrganizations? customPropertiesForOrganizations,  AppPermissionsMembers? members, @JsonKey(name: 'organization_administration')  AppPermissionsOrganizationAdministration? organizationAdministration, @JsonKey(name: 'organization_custom_roles')  AppPermissionsOrganizationCustomRoles? organizationCustomRoles, @JsonKey(name: 'organization_custom_org_roles')  AppPermissionsOrganizationCustomOrgRoles? organizationCustomOrgRoles, @JsonKey(name: 'organization_custom_properties')  AppPermissionsOrganizationCustomProperties? organizationCustomProperties, @JsonKey(name: 'organization_copilot_seat_management')  AppPermissionsOrganizationCopilotSeatManagement? organizationCopilotSeatManagement, @JsonKey(name: 'organization_copilot_agent_settings')  AppPermissionsOrganizationCopilotAgentSettings? organizationCopilotAgentSettings, @JsonKey(name: 'enterprise_custom_properties_for_organizations')  AppPermissionsEnterpriseCustomPropertiesForOrganizations? enterpriseCustomPropertiesForOrganizations, @JsonKey(name: 'organization_events')  AppPermissionsOrganizationEvents? organizationEvents, @JsonKey(name: 'organization_hooks')  AppPermissionsOrganizationHooks? organizationHooks, @JsonKey(name: 'organization_personal_access_tokens')  AppPermissionsOrganizationPersonalAccessTokens? organizationPersonalAccessTokens, @JsonKey(name: 'organization_personal_access_token_requests')  AppPermissionsOrganizationPersonalAccessTokenRequests? organizationPersonalAccessTokenRequests, @JsonKey(name: 'organization_plan')  AppPermissionsOrganizationPlan? organizationPlan, @JsonKey(name: 'organization_projects')  AppPermissionsOrganizationProjects? organizationProjects, @JsonKey(name: 'organization_packages')  AppPermissionsOrganizationPackages? organizationPackages, @JsonKey(name: 'organization_secrets')  AppPermissionsOrganizationSecrets? organizationSecrets, @JsonKey(name: 'organization_self_hosted_runners')  AppPermissionsOrganizationSelfHostedRunners? organizationSelfHostedRunners, @JsonKey(name: 'organization_user_blocking')  AppPermissionsOrganizationUserBlocking? organizationUserBlocking, @JsonKey(name: 'email_addresses')  AppPermissionsEmailAddresses? emailAddresses,  AppPermissionsFollowers? followers, @JsonKey(name: 'git_ssh_keys')  AppPermissionsGitSshKeys? gitSshKeys, @JsonKey(name: 'gpg_keys')  AppPermissionsGpgKeys? gpgKeys, @JsonKey(name: 'interaction_limits')  AppPermissionsInteractionLimits? interactionLimits,  AppPermissionsProfile? profile,  AppPermissionsStarring? starring, @JsonKey(name: 'organization_announcement_banners')  AppPermissionsOrganizationAnnouncementBanners? organizationAnnouncementBanners)  $default,) {final _that = this;
switch (_that) {
case _AppPermissions():
return $default(_that.repositoryCustomProperties,_that.administration,_that.artifactMetadata,_that.attestations,_that.checks,_that.codespaces,_that.contents,_that.dependabotSecrets,_that.deployments,_that.discussions,_that.environments,_that.issues,_that.mergeQueues,_that.metadata,_that.packages,_that.pages,_that.pullRequests,_that.actions,_that.repositoryHooks,_that.repositoryProjects,_that.secretScanningAlerts,_that.secrets,_that.securityEvents,_that.singleFile,_that.statuses,_that.vulnerabilityAlerts,_that.workflows,_that.customPropertiesForOrganizations,_that.members,_that.organizationAdministration,_that.organizationCustomRoles,_that.organizationCustomOrgRoles,_that.organizationCustomProperties,_that.organizationCopilotSeatManagement,_that.organizationCopilotAgentSettings,_that.enterpriseCustomPropertiesForOrganizations,_that.organizationEvents,_that.organizationHooks,_that.organizationPersonalAccessTokens,_that.organizationPersonalAccessTokenRequests,_that.organizationPlan,_that.organizationProjects,_that.organizationPackages,_that.organizationSecrets,_that.organizationSelfHostedRunners,_that.organizationUserBlocking,_that.emailAddresses,_that.followers,_that.gitSshKeys,_that.gpgKeys,_that.interactionLimits,_that.profile,_that.starring,_that.organizationAnnouncementBanners);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'repository_custom_properties')  AppPermissionsRepositoryCustomProperties? repositoryCustomProperties,  AppPermissionsAdministration? administration, @JsonKey(name: 'artifact_metadata')  AppPermissionsArtifactMetadata? artifactMetadata,  AppPermissionsAttestations? attestations,  AppPermissionsChecks? checks,  AppPermissionsCodespaces? codespaces,  AppPermissionsContents? contents, @JsonKey(name: 'dependabot_secrets')  AppPermissionsDependabotSecrets? dependabotSecrets,  AppPermissionsDeployments? deployments,  AppPermissionsDiscussions? discussions,  AppPermissionsEnvironments? environments,  AppPermissionsIssues? issues, @JsonKey(name: 'merge_queues')  AppPermissionsMergeQueues? mergeQueues, @JsonKey(name: 'Metadata')  AppPermissionsMetadata? metadata,  AppPermissionsPackages? packages,  AppPermissionsPages? pages, @JsonKey(name: 'pull_requests')  AppPermissionsPullRequests? pullRequests,  AppPermissionsActions? actions, @JsonKey(name: 'repository_hooks')  AppPermissionsRepositoryHooks? repositoryHooks, @JsonKey(name: 'repository_projects')  AppPermissionsRepositoryProjects? repositoryProjects, @JsonKey(name: 'secret_scanning_alerts')  AppPermissionsSecretScanningAlerts? secretScanningAlerts,  AppPermissionsSecrets? secrets, @JsonKey(name: 'security_events')  AppPermissionsSecurityEvents? securityEvents, @JsonKey(name: 'single_file')  AppPermissionsSingleFile? singleFile,  AppPermissionsStatuses? statuses, @JsonKey(name: 'vulnerability_alerts')  AppPermissionsVulnerabilityAlerts? vulnerabilityAlerts,  AppPermissionsWorkflows? workflows, @JsonKey(name: 'custom_properties_for_organizations')  AppPermissionsCustomPropertiesForOrganizations? customPropertiesForOrganizations,  AppPermissionsMembers? members, @JsonKey(name: 'organization_administration')  AppPermissionsOrganizationAdministration? organizationAdministration, @JsonKey(name: 'organization_custom_roles')  AppPermissionsOrganizationCustomRoles? organizationCustomRoles, @JsonKey(name: 'organization_custom_org_roles')  AppPermissionsOrganizationCustomOrgRoles? organizationCustomOrgRoles, @JsonKey(name: 'organization_custom_properties')  AppPermissionsOrganizationCustomProperties? organizationCustomProperties, @JsonKey(name: 'organization_copilot_seat_management')  AppPermissionsOrganizationCopilotSeatManagement? organizationCopilotSeatManagement, @JsonKey(name: 'organization_copilot_agent_settings')  AppPermissionsOrganizationCopilotAgentSettings? organizationCopilotAgentSettings, @JsonKey(name: 'enterprise_custom_properties_for_organizations')  AppPermissionsEnterpriseCustomPropertiesForOrganizations? enterpriseCustomPropertiesForOrganizations, @JsonKey(name: 'organization_events')  AppPermissionsOrganizationEvents? organizationEvents, @JsonKey(name: 'organization_hooks')  AppPermissionsOrganizationHooks? organizationHooks, @JsonKey(name: 'organization_personal_access_tokens')  AppPermissionsOrganizationPersonalAccessTokens? organizationPersonalAccessTokens, @JsonKey(name: 'organization_personal_access_token_requests')  AppPermissionsOrganizationPersonalAccessTokenRequests? organizationPersonalAccessTokenRequests, @JsonKey(name: 'organization_plan')  AppPermissionsOrganizationPlan? organizationPlan, @JsonKey(name: 'organization_projects')  AppPermissionsOrganizationProjects? organizationProjects, @JsonKey(name: 'organization_packages')  AppPermissionsOrganizationPackages? organizationPackages, @JsonKey(name: 'organization_secrets')  AppPermissionsOrganizationSecrets? organizationSecrets, @JsonKey(name: 'organization_self_hosted_runners')  AppPermissionsOrganizationSelfHostedRunners? organizationSelfHostedRunners, @JsonKey(name: 'organization_user_blocking')  AppPermissionsOrganizationUserBlocking? organizationUserBlocking, @JsonKey(name: 'email_addresses')  AppPermissionsEmailAddresses? emailAddresses,  AppPermissionsFollowers? followers, @JsonKey(name: 'git_ssh_keys')  AppPermissionsGitSshKeys? gitSshKeys, @JsonKey(name: 'gpg_keys')  AppPermissionsGpgKeys? gpgKeys, @JsonKey(name: 'interaction_limits')  AppPermissionsInteractionLimits? interactionLimits,  AppPermissionsProfile? profile,  AppPermissionsStarring? starring, @JsonKey(name: 'organization_announcement_banners')  AppPermissionsOrganizationAnnouncementBanners? organizationAnnouncementBanners)?  $default,) {final _that = this;
switch (_that) {
case _AppPermissions() when $default != null:
return $default(_that.repositoryCustomProperties,_that.administration,_that.artifactMetadata,_that.attestations,_that.checks,_that.codespaces,_that.contents,_that.dependabotSecrets,_that.deployments,_that.discussions,_that.environments,_that.issues,_that.mergeQueues,_that.metadata,_that.packages,_that.pages,_that.pullRequests,_that.actions,_that.repositoryHooks,_that.repositoryProjects,_that.secretScanningAlerts,_that.secrets,_that.securityEvents,_that.singleFile,_that.statuses,_that.vulnerabilityAlerts,_that.workflows,_that.customPropertiesForOrganizations,_that.members,_that.organizationAdministration,_that.organizationCustomRoles,_that.organizationCustomOrgRoles,_that.organizationCustomProperties,_that.organizationCopilotSeatManagement,_that.organizationCopilotAgentSettings,_that.enterpriseCustomPropertiesForOrganizations,_that.organizationEvents,_that.organizationHooks,_that.organizationPersonalAccessTokens,_that.organizationPersonalAccessTokenRequests,_that.organizationPlan,_that.organizationProjects,_that.organizationPackages,_that.organizationSecrets,_that.organizationSelfHostedRunners,_that.organizationUserBlocking,_that.emailAddresses,_that.followers,_that.gitSshKeys,_that.gpgKeys,_that.interactionLimits,_that.profile,_that.starring,_that.organizationAnnouncementBanners);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppPermissions implements AppPermissions {
  const _AppPermissions({@JsonKey(name: 'repository_custom_properties') this.repositoryCustomProperties, this.administration, @JsonKey(name: 'artifact_metadata') this.artifactMetadata, this.attestations, this.checks, this.codespaces, this.contents, @JsonKey(name: 'dependabot_secrets') this.dependabotSecrets, this.deployments, this.discussions, this.environments, this.issues, @JsonKey(name: 'merge_queues') this.mergeQueues, @JsonKey(name: 'Metadata') this.metadata, this.packages, this.pages, @JsonKey(name: 'pull_requests') this.pullRequests, this.actions, @JsonKey(name: 'repository_hooks') this.repositoryHooks, @JsonKey(name: 'repository_projects') this.repositoryProjects, @JsonKey(name: 'secret_scanning_alerts') this.secretScanningAlerts, this.secrets, @JsonKey(name: 'security_events') this.securityEvents, @JsonKey(name: 'single_file') this.singleFile, this.statuses, @JsonKey(name: 'vulnerability_alerts') this.vulnerabilityAlerts, this.workflows, @JsonKey(name: 'custom_properties_for_organizations') this.customPropertiesForOrganizations, this.members, @JsonKey(name: 'organization_administration') this.organizationAdministration, @JsonKey(name: 'organization_custom_roles') this.organizationCustomRoles, @JsonKey(name: 'organization_custom_org_roles') this.organizationCustomOrgRoles, @JsonKey(name: 'organization_custom_properties') this.organizationCustomProperties, @JsonKey(name: 'organization_copilot_seat_management') this.organizationCopilotSeatManagement, @JsonKey(name: 'organization_copilot_agent_settings') this.organizationCopilotAgentSettings, @JsonKey(name: 'enterprise_custom_properties_for_organizations') this.enterpriseCustomPropertiesForOrganizations, @JsonKey(name: 'organization_events') this.organizationEvents, @JsonKey(name: 'organization_hooks') this.organizationHooks, @JsonKey(name: 'organization_personal_access_tokens') this.organizationPersonalAccessTokens, @JsonKey(name: 'organization_personal_access_token_requests') this.organizationPersonalAccessTokenRequests, @JsonKey(name: 'organization_plan') this.organizationPlan, @JsonKey(name: 'organization_projects') this.organizationProjects, @JsonKey(name: 'organization_packages') this.organizationPackages, @JsonKey(name: 'organization_secrets') this.organizationSecrets, @JsonKey(name: 'organization_self_hosted_runners') this.organizationSelfHostedRunners, @JsonKey(name: 'organization_user_blocking') this.organizationUserBlocking, @JsonKey(name: 'email_addresses') this.emailAddresses, this.followers, @JsonKey(name: 'git_ssh_keys') this.gitSshKeys, @JsonKey(name: 'gpg_keys') this.gpgKeys, @JsonKey(name: 'interaction_limits') this.interactionLimits, this.profile, this.starring, @JsonKey(name: 'organization_announcement_banners') this.organizationAnnouncementBanners});
  factory _AppPermissions.fromJson(Map<String, dynamic> json) => _$AppPermissionsFromJson(json);

/// The level of permission to grant the access token to view and edit custom properties for a repository, when allowed by the property.
@override@JsonKey(name: 'repository_custom_properties') final  AppPermissionsRepositoryCustomProperties? repositoryCustomProperties;
/// The level of permission to grant the access token for Repository creation, deletion, settings, teams, and collaborators creation.
@override final  AppPermissionsAdministration? administration;
/// The level of permission to grant the access token to create and retrieve build Artifact Metadata records.
@override@JsonKey(name: 'artifact_metadata') final  AppPermissionsArtifactMetadata? artifactMetadata;
/// The level of permission to create and retrieve the access token for Repository attestations.
@override final  AppPermissionsAttestations? attestations;
/// The level of permission to grant the access token for checks on code.
@override final  AppPermissionsChecks? checks;
/// The level of permission to grant the access token to create, edit, delete, and list Codespaces.
@override final  AppPermissionsCodespaces? codespaces;
/// The level of permission to grant the access token for Repository contents, commits, branches, downloads, releases, and merges.
@override final  AppPermissionsContents? contents;
/// The level of permission to grant the access token to manage Dependabot secrets.
@override@JsonKey(name: 'dependabot_secrets') final  AppPermissionsDependabotSecrets? dependabotSecrets;
/// The level of permission to grant the access token for deployments and Deployment statuses.
@override final  AppPermissionsDeployments? deployments;
/// The level of permission to grant the access token for discussions and related comments and labels.
@override final  AppPermissionsDiscussions? discussions;
/// The level of permission to grant the access token for managing Repository environments.
@override final  AppPermissionsEnvironments? environments;
/// The level of permission to grant the access token for issues and related comments, assignees, labels, and milestones.
@override final  AppPermissionsIssues? issues;
/// The level of permission to grant the access token to manage the merge queues for a repository.
@override@JsonKey(name: 'merge_queues') final  AppPermissionsMergeQueues? mergeQueues;
/// The level of permission to grant the access token to search repositories, list collaborators, and access Repository metadata.
@override@JsonKey(name: 'Metadata') final  AppPermissionsMetadata? metadata;
/// The level of permission to grant the access token for packages published to GitHub Packages.
@override final  AppPermissionsPackages? packages;
/// The level of permission to grant the access token to retrieve Pages statuses, configuration, and builds, as well as create new builds.
@override final  AppPermissionsPages? pages;
/// The level of permission to grant the access token for pull requests and related comments, assignees, labels, milestones, and merges.
@override@JsonKey(name: 'pull_requests') final  AppPermissionsPullRequests? pullRequests;
/// The level of permission to grant the access token for GitHub Actions workflows, Workflow runs, and artifacts.
@override final  AppPermissionsActions? actions;
/// The level of permission to grant the access token to manage the post-receive hooks for a repository.
@override@JsonKey(name: 'repository_hooks') final  AppPermissionsRepositoryHooks? repositoryHooks;
/// The level of permission to grant the access token to manage Repository projects, columns, and cards.
@override@JsonKey(name: 'repository_projects') final  AppPermissionsRepositoryProjects? repositoryProjects;
/// The level of permission to grant the access token to view and manage secret scanning alerts.
@override@JsonKey(name: 'secret_scanning_alerts') final  AppPermissionsSecretScanningAlerts? secretScanningAlerts;
/// The level of permission to grant the access token to manage Repository secrets.
@override final  AppPermissionsSecrets? secrets;
/// The level of permission to grant the access token to view and manage security events like code scanning alerts.
@override@JsonKey(name: 'security_events') final  AppPermissionsSecurityEvents? securityEvents;
/// The level of permission to grant the access token to manage just a single file.
@override@JsonKey(name: 'single_file') final  AppPermissionsSingleFile? singleFile;
/// The level of permission to grant the access token for Commit statuses.
@override final  AppPermissionsStatuses? statuses;
/// The level of permission to grant the access token to manage Dependabot alerts.
@override@JsonKey(name: 'vulnerability_alerts') final  AppPermissionsVulnerabilityAlerts? vulnerabilityAlerts;
/// The level of permission to grant the access token to update GitHub Actions Workflow files.
@override final  AppPermissionsWorkflows? workflows;
/// The level of permission to grant the access token to view and edit custom properties for an organization, when allowed by the property.
@override@JsonKey(name: 'custom_properties_for_organizations') final  AppPermissionsCustomPropertiesForOrganizations? customPropertiesForOrganizations;
/// The level of permission to grant the access token for organization teams and members.
@override final  AppPermissionsMembers? members;
/// The level of permission to grant the access token to manage access to an organization.
@override@JsonKey(name: 'organization_administration') final  AppPermissionsOrganizationAdministration? organizationAdministration;
/// The level of permission to grant the access token for custom Repository roles management.
@override@JsonKey(name: 'organization_custom_roles') final  AppPermissionsOrganizationCustomRoles? organizationCustomRoles;
/// The level of permission to grant the access token for custom organization roles management.
@override@JsonKey(name: 'organization_custom_org_roles') final  AppPermissionsOrganizationCustomOrgRoles? organizationCustomOrgRoles;
/// The level of permission to grant the access token for Repository custom properties management at the organization level.
@override@JsonKey(name: 'organization_custom_properties') final  AppPermissionsOrganizationCustomProperties? organizationCustomProperties;
/// The level of permission to grant the access token for managing access to GitHub Copilot for members of an organization with a Copilot Business subscription. This property is in public preview and is subject to change.
@override@JsonKey(name: 'organization_copilot_seat_management') final  AppPermissionsOrganizationCopilotSeatManagement? organizationCopilotSeatManagement;
/// The level of permission to grant the access token to view and manage Copilot coding agent settings for an organization.
@override@JsonKey(name: 'organization_copilot_agent_settings') final  AppPermissionsOrganizationCopilotAgentSettings? organizationCopilotAgentSettings;
/// The level of permission to grant the access token for organization custom properties management at the Enterprise level.
@override@JsonKey(name: 'enterprise_custom_properties_for_organizations') final  AppPermissionsEnterpriseCustomPropertiesForOrganizations? enterpriseCustomPropertiesForOrganizations;
/// The level of permission to grant the access token to view events triggered by an Activity in an organization.
@override@JsonKey(name: 'organization_events') final  AppPermissionsOrganizationEvents? organizationEvents;
/// The level of permission to grant the access token to manage the post-receive hooks for an organization.
@override@JsonKey(name: 'organization_hooks') final  AppPermissionsOrganizationHooks? organizationHooks;
/// The level of permission to grant the access token for viewing and managing fine-grained personal access token requests to an organization.
@override@JsonKey(name: 'organization_personal_access_tokens') final  AppPermissionsOrganizationPersonalAccessTokens? organizationPersonalAccessTokens;
/// The level of permission to grant the access token for viewing and managing fine-grained personal access tokens that have been approved by an organization.
@override@JsonKey(name: 'organization_personal_access_token_requests') final  AppPermissionsOrganizationPersonalAccessTokenRequests? organizationPersonalAccessTokenRequests;
/// The level of permission to grant the access token for viewing an organization's plan.
@override@JsonKey(name: 'organization_plan') final  AppPermissionsOrganizationPlan? organizationPlan;
/// The level of permission to grant the access token to manage organization projects and projects public preview (where available).
@override@JsonKey(name: 'organization_projects') final  AppPermissionsOrganizationProjects? organizationProjects;
/// The level of permission to grant the access token for organization packages published to GitHub Packages.
@override@JsonKey(name: 'organization_packages') final  AppPermissionsOrganizationPackages? organizationPackages;
/// The level of permission to grant the access token to manage organization secrets.
@override@JsonKey(name: 'organization_secrets') final  AppPermissionsOrganizationSecrets? organizationSecrets;
/// The level of permission to grant the access token to view and manage GitHub Actions self-hosted runners available to an organization.
@override@JsonKey(name: 'organization_self_hosted_runners') final  AppPermissionsOrganizationSelfHostedRunners? organizationSelfHostedRunners;
/// The level of permission to grant the access token to view and manage users blocked by the organization.
@override@JsonKey(name: 'organization_user_blocking') final  AppPermissionsOrganizationUserBlocking? organizationUserBlocking;
/// The level of permission to grant the access token to manage the Email addresses belonging to a user.
@override@JsonKey(name: 'email_addresses') final  AppPermissionsEmailAddresses? emailAddresses;
/// The level of permission to grant the access token to manage the followers belonging to a user.
@override final  AppPermissionsFollowers? followers;
/// The level of permission to grant the access token to manage git SSH keys.
@override@JsonKey(name: 'git_ssh_keys') final  AppPermissionsGitSshKeys? gitSshKeys;
/// The level of permission to grant the access token to view and manage GPG keys belonging to a user.
@override@JsonKey(name: 'gpg_keys') final  AppPermissionsGpgKeys? gpgKeys;
/// The level of permission to grant the access token to view and manage interaction limits on a repository.
@override@JsonKey(name: 'interaction_limits') final  AppPermissionsInteractionLimits? interactionLimits;
/// The level of permission to grant the access token to manage the profile settings belonging to a user.
@override final  AppPermissionsProfile? profile;
/// The level of permission to grant the access token to list and manage repositories a user is starring.
@override final  AppPermissionsStarring? starring;
/// The level of permission to grant the access token to view and manage announcement banners for an organization.
@override@JsonKey(name: 'organization_announcement_banners') final  AppPermissionsOrganizationAnnouncementBanners? organizationAnnouncementBanners;

/// Create a copy of AppPermissions
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppPermissionsCopyWith<_AppPermissions> get copyWith => __$AppPermissionsCopyWithImpl<_AppPermissions>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppPermissionsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppPermissions&&(identical(other.repositoryCustomProperties, repositoryCustomProperties) || other.repositoryCustomProperties == repositoryCustomProperties)&&(identical(other.administration, administration) || other.administration == administration)&&(identical(other.artifactMetadata, artifactMetadata) || other.artifactMetadata == artifactMetadata)&&(identical(other.attestations, attestations) || other.attestations == attestations)&&(identical(other.checks, checks) || other.checks == checks)&&(identical(other.codespaces, codespaces) || other.codespaces == codespaces)&&(identical(other.contents, contents) || other.contents == contents)&&(identical(other.dependabotSecrets, dependabotSecrets) || other.dependabotSecrets == dependabotSecrets)&&(identical(other.deployments, deployments) || other.deployments == deployments)&&(identical(other.discussions, discussions) || other.discussions == discussions)&&(identical(other.environments, environments) || other.environments == environments)&&(identical(other.issues, issues) || other.issues == issues)&&(identical(other.mergeQueues, mergeQueues) || other.mergeQueues == mergeQueues)&&(identical(other.metadata, metadata) || other.metadata == metadata)&&(identical(other.packages, packages) || other.packages == packages)&&(identical(other.pages, pages) || other.pages == pages)&&(identical(other.pullRequests, pullRequests) || other.pullRequests == pullRequests)&&(identical(other.actions, actions) || other.actions == actions)&&(identical(other.repositoryHooks, repositoryHooks) || other.repositoryHooks == repositoryHooks)&&(identical(other.repositoryProjects, repositoryProjects) || other.repositoryProjects == repositoryProjects)&&(identical(other.secretScanningAlerts, secretScanningAlerts) || other.secretScanningAlerts == secretScanningAlerts)&&(identical(other.secrets, secrets) || other.secrets == secrets)&&(identical(other.securityEvents, securityEvents) || other.securityEvents == securityEvents)&&(identical(other.singleFile, singleFile) || other.singleFile == singleFile)&&(identical(other.statuses, statuses) || other.statuses == statuses)&&(identical(other.vulnerabilityAlerts, vulnerabilityAlerts) || other.vulnerabilityAlerts == vulnerabilityAlerts)&&(identical(other.workflows, workflows) || other.workflows == workflows)&&(identical(other.customPropertiesForOrganizations, customPropertiesForOrganizations) || other.customPropertiesForOrganizations == customPropertiesForOrganizations)&&(identical(other.members, members) || other.members == members)&&(identical(other.organizationAdministration, organizationAdministration) || other.organizationAdministration == organizationAdministration)&&(identical(other.organizationCustomRoles, organizationCustomRoles) || other.organizationCustomRoles == organizationCustomRoles)&&(identical(other.organizationCustomOrgRoles, organizationCustomOrgRoles) || other.organizationCustomOrgRoles == organizationCustomOrgRoles)&&(identical(other.organizationCustomProperties, organizationCustomProperties) || other.organizationCustomProperties == organizationCustomProperties)&&(identical(other.organizationCopilotSeatManagement, organizationCopilotSeatManagement) || other.organizationCopilotSeatManagement == organizationCopilotSeatManagement)&&(identical(other.organizationCopilotAgentSettings, organizationCopilotAgentSettings) || other.organizationCopilotAgentSettings == organizationCopilotAgentSettings)&&(identical(other.enterpriseCustomPropertiesForOrganizations, enterpriseCustomPropertiesForOrganizations) || other.enterpriseCustomPropertiesForOrganizations == enterpriseCustomPropertiesForOrganizations)&&(identical(other.organizationEvents, organizationEvents) || other.organizationEvents == organizationEvents)&&(identical(other.organizationHooks, organizationHooks) || other.organizationHooks == organizationHooks)&&(identical(other.organizationPersonalAccessTokens, organizationPersonalAccessTokens) || other.organizationPersonalAccessTokens == organizationPersonalAccessTokens)&&(identical(other.organizationPersonalAccessTokenRequests, organizationPersonalAccessTokenRequests) || other.organizationPersonalAccessTokenRequests == organizationPersonalAccessTokenRequests)&&(identical(other.organizationPlan, organizationPlan) || other.organizationPlan == organizationPlan)&&(identical(other.organizationProjects, organizationProjects) || other.organizationProjects == organizationProjects)&&(identical(other.organizationPackages, organizationPackages) || other.organizationPackages == organizationPackages)&&(identical(other.organizationSecrets, organizationSecrets) || other.organizationSecrets == organizationSecrets)&&(identical(other.organizationSelfHostedRunners, organizationSelfHostedRunners) || other.organizationSelfHostedRunners == organizationSelfHostedRunners)&&(identical(other.organizationUserBlocking, organizationUserBlocking) || other.organizationUserBlocking == organizationUserBlocking)&&(identical(other.emailAddresses, emailAddresses) || other.emailAddresses == emailAddresses)&&(identical(other.followers, followers) || other.followers == followers)&&(identical(other.gitSshKeys, gitSshKeys) || other.gitSshKeys == gitSshKeys)&&(identical(other.gpgKeys, gpgKeys) || other.gpgKeys == gpgKeys)&&(identical(other.interactionLimits, interactionLimits) || other.interactionLimits == interactionLimits)&&(identical(other.profile, profile) || other.profile == profile)&&(identical(other.starring, starring) || other.starring == starring)&&(identical(other.organizationAnnouncementBanners, organizationAnnouncementBanners) || other.organizationAnnouncementBanners == organizationAnnouncementBanners));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,repositoryCustomProperties,administration,artifactMetadata,attestations,checks,codespaces,contents,dependabotSecrets,deployments,discussions,environments,issues,mergeQueues,metadata,packages,pages,pullRequests,actions,repositoryHooks,repositoryProjects,secretScanningAlerts,secrets,securityEvents,singleFile,statuses,vulnerabilityAlerts,workflows,customPropertiesForOrganizations,members,organizationAdministration,organizationCustomRoles,organizationCustomOrgRoles,organizationCustomProperties,organizationCopilotSeatManagement,organizationCopilotAgentSettings,enterpriseCustomPropertiesForOrganizations,organizationEvents,organizationHooks,organizationPersonalAccessTokens,organizationPersonalAccessTokenRequests,organizationPlan,organizationProjects,organizationPackages,organizationSecrets,organizationSelfHostedRunners,organizationUserBlocking,emailAddresses,followers,gitSshKeys,gpgKeys,interactionLimits,profile,starring,organizationAnnouncementBanners]);

@override
String toString() {
  return 'AppPermissions(repositoryCustomProperties: $repositoryCustomProperties, administration: $administration, artifactMetadata: $artifactMetadata, attestations: $attestations, checks: $checks, codespaces: $codespaces, contents: $contents, dependabotSecrets: $dependabotSecrets, deployments: $deployments, discussions: $discussions, environments: $environments, issues: $issues, mergeQueues: $mergeQueues, metadata: $metadata, packages: $packages, pages: $pages, pullRequests: $pullRequests, actions: $actions, repositoryHooks: $repositoryHooks, repositoryProjects: $repositoryProjects, secretScanningAlerts: $secretScanningAlerts, secrets: $secrets, securityEvents: $securityEvents, singleFile: $singleFile, statuses: $statuses, vulnerabilityAlerts: $vulnerabilityAlerts, workflows: $workflows, customPropertiesForOrganizations: $customPropertiesForOrganizations, members: $members, organizationAdministration: $organizationAdministration, organizationCustomRoles: $organizationCustomRoles, organizationCustomOrgRoles: $organizationCustomOrgRoles, organizationCustomProperties: $organizationCustomProperties, organizationCopilotSeatManagement: $organizationCopilotSeatManagement, organizationCopilotAgentSettings: $organizationCopilotAgentSettings, enterpriseCustomPropertiesForOrganizations: $enterpriseCustomPropertiesForOrganizations, organizationEvents: $organizationEvents, organizationHooks: $organizationHooks, organizationPersonalAccessTokens: $organizationPersonalAccessTokens, organizationPersonalAccessTokenRequests: $organizationPersonalAccessTokenRequests, organizationPlan: $organizationPlan, organizationProjects: $organizationProjects, organizationPackages: $organizationPackages, organizationSecrets: $organizationSecrets, organizationSelfHostedRunners: $organizationSelfHostedRunners, organizationUserBlocking: $organizationUserBlocking, emailAddresses: $emailAddresses, followers: $followers, gitSshKeys: $gitSshKeys, gpgKeys: $gpgKeys, interactionLimits: $interactionLimits, profile: $profile, starring: $starring, organizationAnnouncementBanners: $organizationAnnouncementBanners)';
}


}

/// @nodoc
abstract mixin class _$AppPermissionsCopyWith<$Res> implements $AppPermissionsCopyWith<$Res> {
  factory _$AppPermissionsCopyWith(_AppPermissions value, $Res Function(_AppPermissions) _then) = __$AppPermissionsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'repository_custom_properties') AppPermissionsRepositoryCustomProperties? repositoryCustomProperties, AppPermissionsAdministration? administration,@JsonKey(name: 'artifact_metadata') AppPermissionsArtifactMetadata? artifactMetadata, AppPermissionsAttestations? attestations, AppPermissionsChecks? checks, AppPermissionsCodespaces? codespaces, AppPermissionsContents? contents,@JsonKey(name: 'dependabot_secrets') AppPermissionsDependabotSecrets? dependabotSecrets, AppPermissionsDeployments? deployments, AppPermissionsDiscussions? discussions, AppPermissionsEnvironments? environments, AppPermissionsIssues? issues,@JsonKey(name: 'merge_queues') AppPermissionsMergeQueues? mergeQueues,@JsonKey(name: 'Metadata') AppPermissionsMetadata? metadata, AppPermissionsPackages? packages, AppPermissionsPages? pages,@JsonKey(name: 'pull_requests') AppPermissionsPullRequests? pullRequests, AppPermissionsActions? actions,@JsonKey(name: 'repository_hooks') AppPermissionsRepositoryHooks? repositoryHooks,@JsonKey(name: 'repository_projects') AppPermissionsRepositoryProjects? repositoryProjects,@JsonKey(name: 'secret_scanning_alerts') AppPermissionsSecretScanningAlerts? secretScanningAlerts, AppPermissionsSecrets? secrets,@JsonKey(name: 'security_events') AppPermissionsSecurityEvents? securityEvents,@JsonKey(name: 'single_file') AppPermissionsSingleFile? singleFile, AppPermissionsStatuses? statuses,@JsonKey(name: 'vulnerability_alerts') AppPermissionsVulnerabilityAlerts? vulnerabilityAlerts, AppPermissionsWorkflows? workflows,@JsonKey(name: 'custom_properties_for_organizations') AppPermissionsCustomPropertiesForOrganizations? customPropertiesForOrganizations, AppPermissionsMembers? members,@JsonKey(name: 'organization_administration') AppPermissionsOrganizationAdministration? organizationAdministration,@JsonKey(name: 'organization_custom_roles') AppPermissionsOrganizationCustomRoles? organizationCustomRoles,@JsonKey(name: 'organization_custom_org_roles') AppPermissionsOrganizationCustomOrgRoles? organizationCustomOrgRoles,@JsonKey(name: 'organization_custom_properties') AppPermissionsOrganizationCustomProperties? organizationCustomProperties,@JsonKey(name: 'organization_copilot_seat_management') AppPermissionsOrganizationCopilotSeatManagement? organizationCopilotSeatManagement,@JsonKey(name: 'organization_copilot_agent_settings') AppPermissionsOrganizationCopilotAgentSettings? organizationCopilotAgentSettings,@JsonKey(name: 'enterprise_custom_properties_for_organizations') AppPermissionsEnterpriseCustomPropertiesForOrganizations? enterpriseCustomPropertiesForOrganizations,@JsonKey(name: 'organization_events') AppPermissionsOrganizationEvents? organizationEvents,@JsonKey(name: 'organization_hooks') AppPermissionsOrganizationHooks? organizationHooks,@JsonKey(name: 'organization_personal_access_tokens') AppPermissionsOrganizationPersonalAccessTokens? organizationPersonalAccessTokens,@JsonKey(name: 'organization_personal_access_token_requests') AppPermissionsOrganizationPersonalAccessTokenRequests? organizationPersonalAccessTokenRequests,@JsonKey(name: 'organization_plan') AppPermissionsOrganizationPlan? organizationPlan,@JsonKey(name: 'organization_projects') AppPermissionsOrganizationProjects? organizationProjects,@JsonKey(name: 'organization_packages') AppPermissionsOrganizationPackages? organizationPackages,@JsonKey(name: 'organization_secrets') AppPermissionsOrganizationSecrets? organizationSecrets,@JsonKey(name: 'organization_self_hosted_runners') AppPermissionsOrganizationSelfHostedRunners? organizationSelfHostedRunners,@JsonKey(name: 'organization_user_blocking') AppPermissionsOrganizationUserBlocking? organizationUserBlocking,@JsonKey(name: 'email_addresses') AppPermissionsEmailAddresses? emailAddresses, AppPermissionsFollowers? followers,@JsonKey(name: 'git_ssh_keys') AppPermissionsGitSshKeys? gitSshKeys,@JsonKey(name: 'gpg_keys') AppPermissionsGpgKeys? gpgKeys,@JsonKey(name: 'interaction_limits') AppPermissionsInteractionLimits? interactionLimits, AppPermissionsProfile? profile, AppPermissionsStarring? starring,@JsonKey(name: 'organization_announcement_banners') AppPermissionsOrganizationAnnouncementBanners? organizationAnnouncementBanners
});




}
/// @nodoc
class __$AppPermissionsCopyWithImpl<$Res>
    implements _$AppPermissionsCopyWith<$Res> {
  __$AppPermissionsCopyWithImpl(this._self, this._then);

  final _AppPermissions _self;
  final $Res Function(_AppPermissions) _then;

/// Create a copy of AppPermissions
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? repositoryCustomProperties = freezed,Object? administration = freezed,Object? artifactMetadata = freezed,Object? attestations = freezed,Object? checks = freezed,Object? codespaces = freezed,Object? contents = freezed,Object? dependabotSecrets = freezed,Object? deployments = freezed,Object? discussions = freezed,Object? environments = freezed,Object? issues = freezed,Object? mergeQueues = freezed,Object? metadata = freezed,Object? packages = freezed,Object? pages = freezed,Object? pullRequests = freezed,Object? actions = freezed,Object? repositoryHooks = freezed,Object? repositoryProjects = freezed,Object? secretScanningAlerts = freezed,Object? secrets = freezed,Object? securityEvents = freezed,Object? singleFile = freezed,Object? statuses = freezed,Object? vulnerabilityAlerts = freezed,Object? workflows = freezed,Object? customPropertiesForOrganizations = freezed,Object? members = freezed,Object? organizationAdministration = freezed,Object? organizationCustomRoles = freezed,Object? organizationCustomOrgRoles = freezed,Object? organizationCustomProperties = freezed,Object? organizationCopilotSeatManagement = freezed,Object? organizationCopilotAgentSettings = freezed,Object? enterpriseCustomPropertiesForOrganizations = freezed,Object? organizationEvents = freezed,Object? organizationHooks = freezed,Object? organizationPersonalAccessTokens = freezed,Object? organizationPersonalAccessTokenRequests = freezed,Object? organizationPlan = freezed,Object? organizationProjects = freezed,Object? organizationPackages = freezed,Object? organizationSecrets = freezed,Object? organizationSelfHostedRunners = freezed,Object? organizationUserBlocking = freezed,Object? emailAddresses = freezed,Object? followers = freezed,Object? gitSshKeys = freezed,Object? gpgKeys = freezed,Object? interactionLimits = freezed,Object? profile = freezed,Object? starring = freezed,Object? organizationAnnouncementBanners = freezed,}) {
  return _then(_AppPermissions(
repositoryCustomProperties: freezed == repositoryCustomProperties ? _self.repositoryCustomProperties : repositoryCustomProperties // ignore: cast_nullable_to_non_nullable
as AppPermissionsRepositoryCustomProperties?,administration: freezed == administration ? _self.administration : administration // ignore: cast_nullable_to_non_nullable
as AppPermissionsAdministration?,artifactMetadata: freezed == artifactMetadata ? _self.artifactMetadata : artifactMetadata // ignore: cast_nullable_to_non_nullable
as AppPermissionsArtifactMetadata?,attestations: freezed == attestations ? _self.attestations : attestations // ignore: cast_nullable_to_non_nullable
as AppPermissionsAttestations?,checks: freezed == checks ? _self.checks : checks // ignore: cast_nullable_to_non_nullable
as AppPermissionsChecks?,codespaces: freezed == codespaces ? _self.codespaces : codespaces // ignore: cast_nullable_to_non_nullable
as AppPermissionsCodespaces?,contents: freezed == contents ? _self.contents : contents // ignore: cast_nullable_to_non_nullable
as AppPermissionsContents?,dependabotSecrets: freezed == dependabotSecrets ? _self.dependabotSecrets : dependabotSecrets // ignore: cast_nullable_to_non_nullable
as AppPermissionsDependabotSecrets?,deployments: freezed == deployments ? _self.deployments : deployments // ignore: cast_nullable_to_non_nullable
as AppPermissionsDeployments?,discussions: freezed == discussions ? _self.discussions : discussions // ignore: cast_nullable_to_non_nullable
as AppPermissionsDiscussions?,environments: freezed == environments ? _self.environments : environments // ignore: cast_nullable_to_non_nullable
as AppPermissionsEnvironments?,issues: freezed == issues ? _self.issues : issues // ignore: cast_nullable_to_non_nullable
as AppPermissionsIssues?,mergeQueues: freezed == mergeQueues ? _self.mergeQueues : mergeQueues // ignore: cast_nullable_to_non_nullable
as AppPermissionsMergeQueues?,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as AppPermissionsMetadata?,packages: freezed == packages ? _self.packages : packages // ignore: cast_nullable_to_non_nullable
as AppPermissionsPackages?,pages: freezed == pages ? _self.pages : pages // ignore: cast_nullable_to_non_nullable
as AppPermissionsPages?,pullRequests: freezed == pullRequests ? _self.pullRequests : pullRequests // ignore: cast_nullable_to_non_nullable
as AppPermissionsPullRequests?,actions: freezed == actions ? _self.actions : actions // ignore: cast_nullable_to_non_nullable
as AppPermissionsActions?,repositoryHooks: freezed == repositoryHooks ? _self.repositoryHooks : repositoryHooks // ignore: cast_nullable_to_non_nullable
as AppPermissionsRepositoryHooks?,repositoryProjects: freezed == repositoryProjects ? _self.repositoryProjects : repositoryProjects // ignore: cast_nullable_to_non_nullable
as AppPermissionsRepositoryProjects?,secretScanningAlerts: freezed == secretScanningAlerts ? _self.secretScanningAlerts : secretScanningAlerts // ignore: cast_nullable_to_non_nullable
as AppPermissionsSecretScanningAlerts?,secrets: freezed == secrets ? _self.secrets : secrets // ignore: cast_nullable_to_non_nullable
as AppPermissionsSecrets?,securityEvents: freezed == securityEvents ? _self.securityEvents : securityEvents // ignore: cast_nullable_to_non_nullable
as AppPermissionsSecurityEvents?,singleFile: freezed == singleFile ? _self.singleFile : singleFile // ignore: cast_nullable_to_non_nullable
as AppPermissionsSingleFile?,statuses: freezed == statuses ? _self.statuses : statuses // ignore: cast_nullable_to_non_nullable
as AppPermissionsStatuses?,vulnerabilityAlerts: freezed == vulnerabilityAlerts ? _self.vulnerabilityAlerts : vulnerabilityAlerts // ignore: cast_nullable_to_non_nullable
as AppPermissionsVulnerabilityAlerts?,workflows: freezed == workflows ? _self.workflows : workflows // ignore: cast_nullable_to_non_nullable
as AppPermissionsWorkflows?,customPropertiesForOrganizations: freezed == customPropertiesForOrganizations ? _self.customPropertiesForOrganizations : customPropertiesForOrganizations // ignore: cast_nullable_to_non_nullable
as AppPermissionsCustomPropertiesForOrganizations?,members: freezed == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as AppPermissionsMembers?,organizationAdministration: freezed == organizationAdministration ? _self.organizationAdministration : organizationAdministration // ignore: cast_nullable_to_non_nullable
as AppPermissionsOrganizationAdministration?,organizationCustomRoles: freezed == organizationCustomRoles ? _self.organizationCustomRoles : organizationCustomRoles // ignore: cast_nullable_to_non_nullable
as AppPermissionsOrganizationCustomRoles?,organizationCustomOrgRoles: freezed == organizationCustomOrgRoles ? _self.organizationCustomOrgRoles : organizationCustomOrgRoles // ignore: cast_nullable_to_non_nullable
as AppPermissionsOrganizationCustomOrgRoles?,organizationCustomProperties: freezed == organizationCustomProperties ? _self.organizationCustomProperties : organizationCustomProperties // ignore: cast_nullable_to_non_nullable
as AppPermissionsOrganizationCustomProperties?,organizationCopilotSeatManagement: freezed == organizationCopilotSeatManagement ? _self.organizationCopilotSeatManagement : organizationCopilotSeatManagement // ignore: cast_nullable_to_non_nullable
as AppPermissionsOrganizationCopilotSeatManagement?,organizationCopilotAgentSettings: freezed == organizationCopilotAgentSettings ? _self.organizationCopilotAgentSettings : organizationCopilotAgentSettings // ignore: cast_nullable_to_non_nullable
as AppPermissionsOrganizationCopilotAgentSettings?,enterpriseCustomPropertiesForOrganizations: freezed == enterpriseCustomPropertiesForOrganizations ? _self.enterpriseCustomPropertiesForOrganizations : enterpriseCustomPropertiesForOrganizations // ignore: cast_nullable_to_non_nullable
as AppPermissionsEnterpriseCustomPropertiesForOrganizations?,organizationEvents: freezed == organizationEvents ? _self.organizationEvents : organizationEvents // ignore: cast_nullable_to_non_nullable
as AppPermissionsOrganizationEvents?,organizationHooks: freezed == organizationHooks ? _self.organizationHooks : organizationHooks // ignore: cast_nullable_to_non_nullable
as AppPermissionsOrganizationHooks?,organizationPersonalAccessTokens: freezed == organizationPersonalAccessTokens ? _self.organizationPersonalAccessTokens : organizationPersonalAccessTokens // ignore: cast_nullable_to_non_nullable
as AppPermissionsOrganizationPersonalAccessTokens?,organizationPersonalAccessTokenRequests: freezed == organizationPersonalAccessTokenRequests ? _self.organizationPersonalAccessTokenRequests : organizationPersonalAccessTokenRequests // ignore: cast_nullable_to_non_nullable
as AppPermissionsOrganizationPersonalAccessTokenRequests?,organizationPlan: freezed == organizationPlan ? _self.organizationPlan : organizationPlan // ignore: cast_nullable_to_non_nullable
as AppPermissionsOrganizationPlan?,organizationProjects: freezed == organizationProjects ? _self.organizationProjects : organizationProjects // ignore: cast_nullable_to_non_nullable
as AppPermissionsOrganizationProjects?,organizationPackages: freezed == organizationPackages ? _self.organizationPackages : organizationPackages // ignore: cast_nullable_to_non_nullable
as AppPermissionsOrganizationPackages?,organizationSecrets: freezed == organizationSecrets ? _self.organizationSecrets : organizationSecrets // ignore: cast_nullable_to_non_nullable
as AppPermissionsOrganizationSecrets?,organizationSelfHostedRunners: freezed == organizationSelfHostedRunners ? _self.organizationSelfHostedRunners : organizationSelfHostedRunners // ignore: cast_nullable_to_non_nullable
as AppPermissionsOrganizationSelfHostedRunners?,organizationUserBlocking: freezed == organizationUserBlocking ? _self.organizationUserBlocking : organizationUserBlocking // ignore: cast_nullable_to_non_nullable
as AppPermissionsOrganizationUserBlocking?,emailAddresses: freezed == emailAddresses ? _self.emailAddresses : emailAddresses // ignore: cast_nullable_to_non_nullable
as AppPermissionsEmailAddresses?,followers: freezed == followers ? _self.followers : followers // ignore: cast_nullable_to_non_nullable
as AppPermissionsFollowers?,gitSshKeys: freezed == gitSshKeys ? _self.gitSshKeys : gitSshKeys // ignore: cast_nullable_to_non_nullable
as AppPermissionsGitSshKeys?,gpgKeys: freezed == gpgKeys ? _self.gpgKeys : gpgKeys // ignore: cast_nullable_to_non_nullable
as AppPermissionsGpgKeys?,interactionLimits: freezed == interactionLimits ? _self.interactionLimits : interactionLimits // ignore: cast_nullable_to_non_nullable
as AppPermissionsInteractionLimits?,profile: freezed == profile ? _self.profile : profile // ignore: cast_nullable_to_non_nullable
as AppPermissionsProfile?,starring: freezed == starring ? _self.starring : starring // ignore: cast_nullable_to_non_nullable
as AppPermissionsStarring?,organizationAnnouncementBanners: freezed == organizationAnnouncementBanners ? _self.organizationAnnouncementBanners : organizationAnnouncementBanners // ignore: cast_nullable_to_non_nullable
as AppPermissionsOrganizationAnnouncementBanners?,
  ));
}


}

// dart format on
