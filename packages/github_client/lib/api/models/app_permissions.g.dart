// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_permissions.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppPermissions _$AppPermissionsFromJson(
  Map<String, dynamic> json,
) => _AppPermissions(
  repositoryCustomProperties: json['repository_custom_properties'] == null
      ? null
      : AppPermissionsRepositoryCustomProperties.fromJson(
          json['repository_custom_properties'] as String,
        ),
  administration: json['administration'] == null
      ? null
      : AppPermissionsAdministration.fromJson(json['administration'] as String),
  artifactMetadata: json['artifact_metadata'] == null
      ? null
      : AppPermissionsArtifactMetadata.fromJson(
          json['artifact_metadata'] as String,
        ),
  attestations: json['attestations'] == null
      ? null
      : AppPermissionsAttestations.fromJson(json['attestations'] as String),
  checks: json['checks'] == null
      ? null
      : AppPermissionsChecks.fromJson(json['checks'] as String),
  codespaces: json['codespaces'] == null
      ? null
      : AppPermissionsCodespaces.fromJson(json['codespaces'] as String),
  contents: json['contents'] == null
      ? null
      : AppPermissionsContents.fromJson(json['contents'] as String),
  dependabotSecrets: json['dependabot_secrets'] == null
      ? null
      : AppPermissionsDependabotSecrets.fromJson(
          json['dependabot_secrets'] as String,
        ),
  deployments: json['deployments'] == null
      ? null
      : AppPermissionsDeployments.fromJson(json['deployments'] as String),
  discussions: json['discussions'] == null
      ? null
      : AppPermissionsDiscussions.fromJson(json['discussions'] as String),
  environments: json['environments'] == null
      ? null
      : AppPermissionsEnvironments.fromJson(json['environments'] as String),
  issues: json['issues'] == null
      ? null
      : AppPermissionsIssues.fromJson(json['issues'] as String),
  mergeQueues: json['merge_queues'] == null
      ? null
      : AppPermissionsMergeQueues.fromJson(json['merge_queues'] as String),
  metadata: json['Metadata'] == null
      ? null
      : AppPermissionsMetadata.fromJson(json['Metadata'] as String),
  packages: json['packages'] == null
      ? null
      : AppPermissionsPackages.fromJson(json['packages'] as String),
  pages: json['pages'] == null
      ? null
      : AppPermissionsPages.fromJson(json['pages'] as String),
  pullRequests: json['pull_requests'] == null
      ? null
      : AppPermissionsPullRequests.fromJson(json['pull_requests'] as String),
  actions: json['actions'] == null
      ? null
      : AppPermissionsActions.fromJson(json['actions'] as String),
  repositoryHooks: json['repository_hooks'] == null
      ? null
      : AppPermissionsRepositoryHooks.fromJson(
          json['repository_hooks'] as String,
        ),
  repositoryProjects: json['repository_projects'] == null
      ? null
      : AppPermissionsRepositoryProjects.fromJson(
          json['repository_projects'] as String,
        ),
  secretScanningAlerts: json['secret_scanning_alerts'] == null
      ? null
      : AppPermissionsSecretScanningAlerts.fromJson(
          json['secret_scanning_alerts'] as String,
        ),
  secrets: json['secrets'] == null
      ? null
      : AppPermissionsSecrets.fromJson(json['secrets'] as String),
  securityEvents: json['security_events'] == null
      ? null
      : AppPermissionsSecurityEvents.fromJson(
          json['security_events'] as String,
        ),
  singleFile: json['single_file'] == null
      ? null
      : AppPermissionsSingleFile.fromJson(json['single_file'] as String),
  statuses: json['statuses'] == null
      ? null
      : AppPermissionsStatuses.fromJson(json['statuses'] as String),
  vulnerabilityAlerts: json['vulnerability_alerts'] == null
      ? null
      : AppPermissionsVulnerabilityAlerts.fromJson(
          json['vulnerability_alerts'] as String,
        ),
  workflows: json['workflows'] == null
      ? null
      : AppPermissionsWorkflows.fromJson(json['workflows'] as String),
  customPropertiesForOrganizations:
      json['custom_properties_for_organizations'] == null
      ? null
      : AppPermissionsCustomPropertiesForOrganizations.fromJson(
          json['custom_properties_for_organizations'] as String,
        ),
  members: json['members'] == null
      ? null
      : AppPermissionsMembers.fromJson(json['members'] as String),
  organizationAdministration: json['organization_administration'] == null
      ? null
      : AppPermissionsOrganizationAdministration.fromJson(
          json['organization_administration'] as String,
        ),
  organizationCustomRoles: json['organization_custom_roles'] == null
      ? null
      : AppPermissionsOrganizationCustomRoles.fromJson(
          json['organization_custom_roles'] as String,
        ),
  organizationCustomOrgRoles: json['organization_custom_org_roles'] == null
      ? null
      : AppPermissionsOrganizationCustomOrgRoles.fromJson(
          json['organization_custom_org_roles'] as String,
        ),
  organizationCustomProperties: json['organization_custom_properties'] == null
      ? null
      : AppPermissionsOrganizationCustomProperties.fromJson(
          json['organization_custom_properties'] as String,
        ),
  organizationCopilotSeatManagement:
      json['organization_copilot_seat_management'] == null
      ? null
      : AppPermissionsOrganizationCopilotSeatManagement.fromJson(
          json['organization_copilot_seat_management'] as String,
        ),
  organizationCopilotAgentSettings:
      json['organization_copilot_agent_settings'] == null
      ? null
      : AppPermissionsOrganizationCopilotAgentSettings.fromJson(
          json['organization_copilot_agent_settings'] as String,
        ),
  enterpriseCustomPropertiesForOrganizations:
      json['enterprise_custom_properties_for_organizations'] == null
      ? null
      : AppPermissionsEnterpriseCustomPropertiesForOrganizations.fromJson(
          json['enterprise_custom_properties_for_organizations'] as String,
        ),
  organizationEvents: json['organization_events'] == null
      ? null
      : AppPermissionsOrganizationEvents.fromJson(
          json['organization_events'] as String,
        ),
  organizationHooks: json['organization_hooks'] == null
      ? null
      : AppPermissionsOrganizationHooks.fromJson(
          json['organization_hooks'] as String,
        ),
  organizationPersonalAccessTokens:
      json['organization_personal_access_tokens'] == null
      ? null
      : AppPermissionsOrganizationPersonalAccessTokens.fromJson(
          json['organization_personal_access_tokens'] as String,
        ),
  organizationPersonalAccessTokenRequests:
      json['organization_personal_access_token_requests'] == null
      ? null
      : AppPermissionsOrganizationPersonalAccessTokenRequests.fromJson(
          json['organization_personal_access_token_requests'] as String,
        ),
  organizationPlan: json['organization_plan'] == null
      ? null
      : AppPermissionsOrganizationPlan.fromJson(
          json['organization_plan'] as String,
        ),
  organizationProjects: json['organization_projects'] == null
      ? null
      : AppPermissionsOrganizationProjects.fromJson(
          json['organization_projects'] as String,
        ),
  organizationPackages: json['organization_packages'] == null
      ? null
      : AppPermissionsOrganizationPackages.fromJson(
          json['organization_packages'] as String,
        ),
  organizationSecrets: json['organization_secrets'] == null
      ? null
      : AppPermissionsOrganizationSecrets.fromJson(
          json['organization_secrets'] as String,
        ),
  organizationSelfHostedRunners:
      json['organization_self_hosted_runners'] == null
      ? null
      : AppPermissionsOrganizationSelfHostedRunners.fromJson(
          json['organization_self_hosted_runners'] as String,
        ),
  organizationUserBlocking: json['organization_user_blocking'] == null
      ? null
      : AppPermissionsOrganizationUserBlocking.fromJson(
          json['organization_user_blocking'] as String,
        ),
  emailAddresses: json['email_addresses'] == null
      ? null
      : AppPermissionsEmailAddresses.fromJson(
          json['email_addresses'] as String,
        ),
  followers: json['followers'] == null
      ? null
      : AppPermissionsFollowers.fromJson(json['followers'] as String),
  gitSshKeys: json['git_ssh_keys'] == null
      ? null
      : AppPermissionsGitSshKeys.fromJson(json['git_ssh_keys'] as String),
  gpgKeys: json['gpg_keys'] == null
      ? null
      : AppPermissionsGpgKeys.fromJson(json['gpg_keys'] as String),
  interactionLimits: json['interaction_limits'] == null
      ? null
      : AppPermissionsInteractionLimits.fromJson(
          json['interaction_limits'] as String,
        ),
  profile: json['profile'] == null
      ? null
      : AppPermissionsProfile.fromJson(json['profile'] as String),
  starring: json['starring'] == null
      ? null
      : AppPermissionsStarring.fromJson(json['starring'] as String),
  organizationAnnouncementBanners:
      json['organization_announcement_banners'] == null
      ? null
      : AppPermissionsOrganizationAnnouncementBanners.fromJson(
          json['organization_announcement_banners'] as String,
        ),
);

Map<String, dynamic> _$AppPermissionsToJson(
  _AppPermissions instance,
) => <String, dynamic>{
  'repository_custom_properties':
      _$AppPermissionsRepositoryCustomPropertiesEnumMap[instance
          .repositoryCustomProperties],
  'administration':
      _$AppPermissionsAdministrationEnumMap[instance.administration],
  'artifact_metadata':
      _$AppPermissionsArtifactMetadataEnumMap[instance.artifactMetadata],
  'attestations': _$AppPermissionsAttestationsEnumMap[instance.attestations],
  'checks': _$AppPermissionsChecksEnumMap[instance.checks],
  'codespaces': _$AppPermissionsCodespacesEnumMap[instance.codespaces],
  'contents': _$AppPermissionsContentsEnumMap[instance.contents],
  'dependabot_secrets':
      _$AppPermissionsDependabotSecretsEnumMap[instance.dependabotSecrets],
  'deployments': _$AppPermissionsDeploymentsEnumMap[instance.deployments],
  'discussions': _$AppPermissionsDiscussionsEnumMap[instance.discussions],
  'environments': _$AppPermissionsEnvironmentsEnumMap[instance.environments],
  'issues': _$AppPermissionsIssuesEnumMap[instance.issues],
  'merge_queues': _$AppPermissionsMergeQueuesEnumMap[instance.mergeQueues],
  'Metadata': _$AppPermissionsMetadataEnumMap[instance.metadata],
  'packages': _$AppPermissionsPackagesEnumMap[instance.packages],
  'pages': _$AppPermissionsPagesEnumMap[instance.pages],
  'pull_requests': _$AppPermissionsPullRequestsEnumMap[instance.pullRequests],
  'actions': _$AppPermissionsActionsEnumMap[instance.actions],
  'repository_hooks':
      _$AppPermissionsRepositoryHooksEnumMap[instance.repositoryHooks],
  'repository_projects':
      _$AppPermissionsRepositoryProjectsEnumMap[instance.repositoryProjects],
  'secret_scanning_alerts':
      _$AppPermissionsSecretScanningAlertsEnumMap[instance
          .secretScanningAlerts],
  'secrets': _$AppPermissionsSecretsEnumMap[instance.secrets],
  'security_events':
      _$AppPermissionsSecurityEventsEnumMap[instance.securityEvents],
  'single_file': _$AppPermissionsSingleFileEnumMap[instance.singleFile],
  'statuses': _$AppPermissionsStatusesEnumMap[instance.statuses],
  'vulnerability_alerts':
      _$AppPermissionsVulnerabilityAlertsEnumMap[instance.vulnerabilityAlerts],
  'workflows': _$AppPermissionsWorkflowsEnumMap[instance.workflows],
  'custom_properties_for_organizations':
      _$AppPermissionsCustomPropertiesForOrganizationsEnumMap[instance
          .customPropertiesForOrganizations],
  'members': _$AppPermissionsMembersEnumMap[instance.members],
  'organization_administration':
      _$AppPermissionsOrganizationAdministrationEnumMap[instance
          .organizationAdministration],
  'organization_custom_roles':
      _$AppPermissionsOrganizationCustomRolesEnumMap[instance
          .organizationCustomRoles],
  'organization_custom_org_roles':
      _$AppPermissionsOrganizationCustomOrgRolesEnumMap[instance
          .organizationCustomOrgRoles],
  'organization_custom_properties':
      _$AppPermissionsOrganizationCustomPropertiesEnumMap[instance
          .organizationCustomProperties],
  'organization_copilot_seat_management':
      _$AppPermissionsOrganizationCopilotSeatManagementEnumMap[instance
          .organizationCopilotSeatManagement],
  'organization_copilot_agent_settings':
      _$AppPermissionsOrganizationCopilotAgentSettingsEnumMap[instance
          .organizationCopilotAgentSettings],
  'enterprise_custom_properties_for_organizations':
      _$AppPermissionsEnterpriseCustomPropertiesForOrganizationsEnumMap[instance
          .enterpriseCustomPropertiesForOrganizations],
  'organization_events':
      _$AppPermissionsOrganizationEventsEnumMap[instance.organizationEvents],
  'organization_hooks':
      _$AppPermissionsOrganizationHooksEnumMap[instance.organizationHooks],
  'organization_personal_access_tokens':
      _$AppPermissionsOrganizationPersonalAccessTokensEnumMap[instance
          .organizationPersonalAccessTokens],
  'organization_personal_access_token_requests':
      _$AppPermissionsOrganizationPersonalAccessTokenRequestsEnumMap[instance
          .organizationPersonalAccessTokenRequests],
  'organization_plan':
      _$AppPermissionsOrganizationPlanEnumMap[instance.organizationPlan],
  'organization_projects':
      _$AppPermissionsOrganizationProjectsEnumMap[instance
          .organizationProjects],
  'organization_packages':
      _$AppPermissionsOrganizationPackagesEnumMap[instance
          .organizationPackages],
  'organization_secrets':
      _$AppPermissionsOrganizationSecretsEnumMap[instance.organizationSecrets],
  'organization_self_hosted_runners':
      _$AppPermissionsOrganizationSelfHostedRunnersEnumMap[instance
          .organizationSelfHostedRunners],
  'organization_user_blocking':
      _$AppPermissionsOrganizationUserBlockingEnumMap[instance
          .organizationUserBlocking],
  'email_addresses':
      _$AppPermissionsEmailAddressesEnumMap[instance.emailAddresses],
  'followers': _$AppPermissionsFollowersEnumMap[instance.followers],
  'git_ssh_keys': _$AppPermissionsGitSshKeysEnumMap[instance.gitSshKeys],
  'gpg_keys': _$AppPermissionsGpgKeysEnumMap[instance.gpgKeys],
  'interaction_limits':
      _$AppPermissionsInteractionLimitsEnumMap[instance.interactionLimits],
  'profile': _$AppPermissionsProfileEnumMap[instance.profile],
  'starring': _$AppPermissionsStarringEnumMap[instance.starring],
  'organization_announcement_banners':
      _$AppPermissionsOrganizationAnnouncementBannersEnumMap[instance
          .organizationAnnouncementBanners],
};

const _$AppPermissionsRepositoryCustomPropertiesEnumMap = {
  AppPermissionsRepositoryCustomProperties.read: 'read',
  AppPermissionsRepositoryCustomProperties.write: 'write',
  AppPermissionsRepositoryCustomProperties.$unknown: r'$unknown',
};

const _$AppPermissionsAdministrationEnumMap = {
  AppPermissionsAdministration.read: 'read',
  AppPermissionsAdministration.write: 'write',
  AppPermissionsAdministration.$unknown: r'$unknown',
};

const _$AppPermissionsArtifactMetadataEnumMap = {
  AppPermissionsArtifactMetadata.read: 'read',
  AppPermissionsArtifactMetadata.write: 'write',
  AppPermissionsArtifactMetadata.$unknown: r'$unknown',
};

const _$AppPermissionsAttestationsEnumMap = {
  AppPermissionsAttestations.read: 'read',
  AppPermissionsAttestations.write: 'write',
  AppPermissionsAttestations.$unknown: r'$unknown',
};

const _$AppPermissionsChecksEnumMap = {
  AppPermissionsChecks.read: 'read',
  AppPermissionsChecks.write: 'write',
  AppPermissionsChecks.$unknown: r'$unknown',
};

const _$AppPermissionsCodespacesEnumMap = {
  AppPermissionsCodespaces.read: 'read',
  AppPermissionsCodespaces.write: 'write',
  AppPermissionsCodespaces.$unknown: r'$unknown',
};

const _$AppPermissionsContentsEnumMap = {
  AppPermissionsContents.read: 'read',
  AppPermissionsContents.write: 'write',
  AppPermissionsContents.$unknown: r'$unknown',
};

const _$AppPermissionsDependabotSecretsEnumMap = {
  AppPermissionsDependabotSecrets.read: 'read',
  AppPermissionsDependabotSecrets.write: 'write',
  AppPermissionsDependabotSecrets.$unknown: r'$unknown',
};

const _$AppPermissionsDeploymentsEnumMap = {
  AppPermissionsDeployments.read: 'read',
  AppPermissionsDeployments.write: 'write',
  AppPermissionsDeployments.$unknown: r'$unknown',
};

const _$AppPermissionsDiscussionsEnumMap = {
  AppPermissionsDiscussions.read: 'read',
  AppPermissionsDiscussions.write: 'write',
  AppPermissionsDiscussions.$unknown: r'$unknown',
};

const _$AppPermissionsEnvironmentsEnumMap = {
  AppPermissionsEnvironments.read: 'read',
  AppPermissionsEnvironments.write: 'write',
  AppPermissionsEnvironments.$unknown: r'$unknown',
};

const _$AppPermissionsIssuesEnumMap = {
  AppPermissionsIssues.read: 'read',
  AppPermissionsIssues.write: 'write',
  AppPermissionsIssues.$unknown: r'$unknown',
};

const _$AppPermissionsMergeQueuesEnumMap = {
  AppPermissionsMergeQueues.read: 'read',
  AppPermissionsMergeQueues.write: 'write',
  AppPermissionsMergeQueues.$unknown: r'$unknown',
};

const _$AppPermissionsMetadataEnumMap = {
  AppPermissionsMetadata.read: 'read',
  AppPermissionsMetadata.write: 'write',
  AppPermissionsMetadata.$unknown: r'$unknown',
};

const _$AppPermissionsPackagesEnumMap = {
  AppPermissionsPackages.read: 'read',
  AppPermissionsPackages.write: 'write',
  AppPermissionsPackages.$unknown: r'$unknown',
};

const _$AppPermissionsPagesEnumMap = {
  AppPermissionsPages.read: 'read',
  AppPermissionsPages.write: 'write',
  AppPermissionsPages.$unknown: r'$unknown',
};

const _$AppPermissionsPullRequestsEnumMap = {
  AppPermissionsPullRequests.read: 'read',
  AppPermissionsPullRequests.write: 'write',
  AppPermissionsPullRequests.$unknown: r'$unknown',
};

const _$AppPermissionsActionsEnumMap = {
  AppPermissionsActions.read: 'read',
  AppPermissionsActions.write: 'write',
  AppPermissionsActions.$unknown: r'$unknown',
};

const _$AppPermissionsRepositoryHooksEnumMap = {
  AppPermissionsRepositoryHooks.read: 'read',
  AppPermissionsRepositoryHooks.write: 'write',
  AppPermissionsRepositoryHooks.$unknown: r'$unknown',
};

const _$AppPermissionsRepositoryProjectsEnumMap = {
  AppPermissionsRepositoryProjects.read: 'read',
  AppPermissionsRepositoryProjects.write: 'write',
  AppPermissionsRepositoryProjects.admin: 'admin',
  AppPermissionsRepositoryProjects.$unknown: r'$unknown',
};

const _$AppPermissionsSecretScanningAlertsEnumMap = {
  AppPermissionsSecretScanningAlerts.read: 'read',
  AppPermissionsSecretScanningAlerts.write: 'write',
  AppPermissionsSecretScanningAlerts.$unknown: r'$unknown',
};

const _$AppPermissionsSecretsEnumMap = {
  AppPermissionsSecrets.read: 'read',
  AppPermissionsSecrets.write: 'write',
  AppPermissionsSecrets.$unknown: r'$unknown',
};

const _$AppPermissionsSecurityEventsEnumMap = {
  AppPermissionsSecurityEvents.read: 'read',
  AppPermissionsSecurityEvents.write: 'write',
  AppPermissionsSecurityEvents.$unknown: r'$unknown',
};

const _$AppPermissionsSingleFileEnumMap = {
  AppPermissionsSingleFile.read: 'read',
  AppPermissionsSingleFile.write: 'write',
  AppPermissionsSingleFile.$unknown: r'$unknown',
};

const _$AppPermissionsStatusesEnumMap = {
  AppPermissionsStatuses.read: 'read',
  AppPermissionsStatuses.write: 'write',
  AppPermissionsStatuses.$unknown: r'$unknown',
};

const _$AppPermissionsVulnerabilityAlertsEnumMap = {
  AppPermissionsVulnerabilityAlerts.read: 'read',
  AppPermissionsVulnerabilityAlerts.write: 'write',
  AppPermissionsVulnerabilityAlerts.$unknown: r'$unknown',
};

const _$AppPermissionsWorkflowsEnumMap = {
  AppPermissionsWorkflows.write: 'write',
  AppPermissionsWorkflows.$unknown: r'$unknown',
};

const _$AppPermissionsCustomPropertiesForOrganizationsEnumMap = {
  AppPermissionsCustomPropertiesForOrganizations.read: 'read',
  AppPermissionsCustomPropertiesForOrganizations.write: 'write',
  AppPermissionsCustomPropertiesForOrganizations.$unknown: r'$unknown',
};

const _$AppPermissionsMembersEnumMap = {
  AppPermissionsMembers.read: 'read',
  AppPermissionsMembers.write: 'write',
  AppPermissionsMembers.$unknown: r'$unknown',
};

const _$AppPermissionsOrganizationAdministrationEnumMap = {
  AppPermissionsOrganizationAdministration.read: 'read',
  AppPermissionsOrganizationAdministration.write: 'write',
  AppPermissionsOrganizationAdministration.$unknown: r'$unknown',
};

const _$AppPermissionsOrganizationCustomRolesEnumMap = {
  AppPermissionsOrganizationCustomRoles.read: 'read',
  AppPermissionsOrganizationCustomRoles.write: 'write',
  AppPermissionsOrganizationCustomRoles.$unknown: r'$unknown',
};

const _$AppPermissionsOrganizationCustomOrgRolesEnumMap = {
  AppPermissionsOrganizationCustomOrgRoles.read: 'read',
  AppPermissionsOrganizationCustomOrgRoles.write: 'write',
  AppPermissionsOrganizationCustomOrgRoles.$unknown: r'$unknown',
};

const _$AppPermissionsOrganizationCustomPropertiesEnumMap = {
  AppPermissionsOrganizationCustomProperties.read: 'read',
  AppPermissionsOrganizationCustomProperties.write: 'write',
  AppPermissionsOrganizationCustomProperties.admin: 'admin',
  AppPermissionsOrganizationCustomProperties.$unknown: r'$unknown',
};

const _$AppPermissionsOrganizationCopilotSeatManagementEnumMap = {
  AppPermissionsOrganizationCopilotSeatManagement.write: 'write',
  AppPermissionsOrganizationCopilotSeatManagement.$unknown: r'$unknown',
};

const _$AppPermissionsOrganizationCopilotAgentSettingsEnumMap = {
  AppPermissionsOrganizationCopilotAgentSettings.read: 'read',
  AppPermissionsOrganizationCopilotAgentSettings.write: 'write',
  AppPermissionsOrganizationCopilotAgentSettings.$unknown: r'$unknown',
};

const _$AppPermissionsEnterpriseCustomPropertiesForOrganizationsEnumMap = {
  AppPermissionsEnterpriseCustomPropertiesForOrganizations.read: 'read',
  AppPermissionsEnterpriseCustomPropertiesForOrganizations.write: 'write',
  AppPermissionsEnterpriseCustomPropertiesForOrganizations.admin: 'admin',
  AppPermissionsEnterpriseCustomPropertiesForOrganizations.$unknown:
      r'$unknown',
};

const _$AppPermissionsOrganizationEventsEnumMap = {
  AppPermissionsOrganizationEvents.read: 'read',
  AppPermissionsOrganizationEvents.$unknown: r'$unknown',
};

const _$AppPermissionsOrganizationHooksEnumMap = {
  AppPermissionsOrganizationHooks.read: 'read',
  AppPermissionsOrganizationHooks.write: 'write',
  AppPermissionsOrganizationHooks.$unknown: r'$unknown',
};

const _$AppPermissionsOrganizationPersonalAccessTokensEnumMap = {
  AppPermissionsOrganizationPersonalAccessTokens.read: 'read',
  AppPermissionsOrganizationPersonalAccessTokens.write: 'write',
  AppPermissionsOrganizationPersonalAccessTokens.$unknown: r'$unknown',
};

const _$AppPermissionsOrganizationPersonalAccessTokenRequestsEnumMap = {
  AppPermissionsOrganizationPersonalAccessTokenRequests.read: 'read',
  AppPermissionsOrganizationPersonalAccessTokenRequests.write: 'write',
  AppPermissionsOrganizationPersonalAccessTokenRequests.$unknown: r'$unknown',
};

const _$AppPermissionsOrganizationPlanEnumMap = {
  AppPermissionsOrganizationPlan.read: 'read',
  AppPermissionsOrganizationPlan.$unknown: r'$unknown',
};

const _$AppPermissionsOrganizationProjectsEnumMap = {
  AppPermissionsOrganizationProjects.read: 'read',
  AppPermissionsOrganizationProjects.write: 'write',
  AppPermissionsOrganizationProjects.admin: 'admin',
  AppPermissionsOrganizationProjects.$unknown: r'$unknown',
};

const _$AppPermissionsOrganizationPackagesEnumMap = {
  AppPermissionsOrganizationPackages.read: 'read',
  AppPermissionsOrganizationPackages.write: 'write',
  AppPermissionsOrganizationPackages.$unknown: r'$unknown',
};

const _$AppPermissionsOrganizationSecretsEnumMap = {
  AppPermissionsOrganizationSecrets.read: 'read',
  AppPermissionsOrganizationSecrets.write: 'write',
  AppPermissionsOrganizationSecrets.$unknown: r'$unknown',
};

const _$AppPermissionsOrganizationSelfHostedRunnersEnumMap = {
  AppPermissionsOrganizationSelfHostedRunners.read: 'read',
  AppPermissionsOrganizationSelfHostedRunners.write: 'write',
  AppPermissionsOrganizationSelfHostedRunners.$unknown: r'$unknown',
};

const _$AppPermissionsOrganizationUserBlockingEnumMap = {
  AppPermissionsOrganizationUserBlocking.read: 'read',
  AppPermissionsOrganizationUserBlocking.write: 'write',
  AppPermissionsOrganizationUserBlocking.$unknown: r'$unknown',
};

const _$AppPermissionsEmailAddressesEnumMap = {
  AppPermissionsEmailAddresses.read: 'read',
  AppPermissionsEmailAddresses.write: 'write',
  AppPermissionsEmailAddresses.$unknown: r'$unknown',
};

const _$AppPermissionsFollowersEnumMap = {
  AppPermissionsFollowers.read: 'read',
  AppPermissionsFollowers.write: 'write',
  AppPermissionsFollowers.$unknown: r'$unknown',
};

const _$AppPermissionsGitSshKeysEnumMap = {
  AppPermissionsGitSshKeys.read: 'read',
  AppPermissionsGitSshKeys.write: 'write',
  AppPermissionsGitSshKeys.$unknown: r'$unknown',
};

const _$AppPermissionsGpgKeysEnumMap = {
  AppPermissionsGpgKeys.read: 'read',
  AppPermissionsGpgKeys.write: 'write',
  AppPermissionsGpgKeys.$unknown: r'$unknown',
};

const _$AppPermissionsInteractionLimitsEnumMap = {
  AppPermissionsInteractionLimits.read: 'read',
  AppPermissionsInteractionLimits.write: 'write',
  AppPermissionsInteractionLimits.$unknown: r'$unknown',
};

const _$AppPermissionsProfileEnumMap = {
  AppPermissionsProfile.write: 'write',
  AppPermissionsProfile.$unknown: r'$unknown',
};

const _$AppPermissionsStarringEnumMap = {
  AppPermissionsStarring.read: 'read',
  AppPermissionsStarring.write: 'write',
  AppPermissionsStarring.$unknown: r'$unknown',
};

const _$AppPermissionsOrganizationAnnouncementBannersEnumMap = {
  AppPermissionsOrganizationAnnouncementBanners.read: 'read',
  AppPermissionsOrganizationAnnouncementBanners.write: 'write',
  AppPermissionsOrganizationAnnouncementBanners.$unknown: r'$unknown',
};
