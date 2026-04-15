// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'full_repository.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FullRepository _$FullRepositoryFromJson(
  Map<String, dynamic> json,
) => _FullRepository(
  milestonesUrl: json['milestones_url'] as String,
  nodeId: json['node_id'] as String,
  name: json['name'] as String,
  fullName: json['full_name'] as String,
  owner: SimpleUser.fromJson(json['owner'] as Map<String, dynamic>),
  private: json['private'] as bool,
  htmlUrl: json['html_url'] as String,
  description: json['description'] as String?,
  fork: json['fork'] as bool,
  url: json['url'] as String,
  archiveUrl: json['archive_url'] as String,
  assigneesUrl: json['assignees_url'] as String,
  blobsUrl: json['blobs_url'] as String,
  branchesUrl: json['branches_url'] as String,
  collaboratorsUrl: json['collaborators_url'] as String,
  commentsUrl: json['comments_url'] as String,
  commitsUrl: json['commits_url'] as String,
  compareUrl: json['compare_url'] as String,
  contentsUrl: json['contents_url'] as String,
  contributorsUrl: json['contributors_url'] as String,
  deploymentsUrl: json['deployments_url'] as String,
  downloadsUrl: json['downloads_url'] as String,
  eventsUrl: json['events_url'] as String,
  forksUrl: json['forks_url'] as String,
  gitCommitsUrl: json['git_commits_url'] as String,
  gitRefsUrl: json['git_refs_url'] as String,
  gitTagsUrl: json['git_tags_url'] as String,
  gitUrl: json['git_url'] as String,
  issueCommentUrl: json['issue_comment_url'] as String,
  issueEventsUrl: json['issue_events_url'] as String,
  issuesUrl: json['issues_url'] as String,
  keysUrl: json['keys_url'] as String,
  labelsUrl: json['labels_url'] as String,
  languagesUrl: json['languages_url'] as String,
  mergesUrl: json['merges_url'] as String,
  id: (json['id'] as num).toInt(),
  notificationsUrl: json['notifications_url'] as String,
  pullsUrl: json['pulls_url'] as String,
  releasesUrl: json['releases_url'] as String,
  sshUrl: json['ssh_url'] as String,
  stargazersUrl: json['stargazers_url'] as String,
  statusesUrl: json['statuses_url'] as String,
  subscribersUrl: json['subscribers_url'] as String,
  subscriptionUrl: json['subscription_url'] as String,
  tagsUrl: json['tags_url'] as String,
  teamsUrl: json['teams_url'] as String,
  treesUrl: json['trees_url'] as String,
  cloneUrl: json['clone_url'] as String,
  mirrorUrl: json['mirror_url'] as String?,
  hooksUrl: json['hooks_url'] as String,
  svnUrl: json['svn_url'] as String,
  homepage: json['homepage'] as String?,
  language: json['Language'] as String?,
  forksCount: (json['forks_count'] as num).toInt(),
  stargazersCount: (json['stargazers_count'] as num).toInt(),
  watchersCount: (json['watchers_count'] as num).toInt(),
  size: (json['size'] as num).toInt(),
  defaultBranch: json['default_branch'] as String,
  openIssuesCount: (json['open_issues_count'] as num).toInt(),
  watchers: (json['watchers'] as num).toInt(),
  openIssues: (json['open_issues'] as num).toInt(),
  hasIssues: json['has_issues'] as bool,
  hasProjects: json['has_projects'] as bool,
  hasWiki: json['has_wiki'] as bool,
  hasPages: json['has_pages'] as bool,
  forks: (json['forks'] as num).toInt(),
  hasDiscussions: json['has_discussions'] as bool,
  license: json['License'] == null
      ? null
      : NullableLicenseSimple.fromJson(json['License'] as Map<String, dynamic>),
  networkCount: (json['network_count'] as num).toInt(),
  subscribersCount: (json['subscribers_count'] as num).toInt(),
  disabled: json['disabled'] as bool,
  updatedAt: DateTime.parse(json['updated_at'] as String),
  pushedAt: DateTime.parse(json['pushed_at'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
  archived: json['archived'] as bool,
  anonymousAccessEnabled: json['anonymous_access_enabled'] as bool? ?? true,
  permissions: json['permissions'] == null
      ? null
      : Permissions11.fromJson(json['permissions'] as Map<String, dynamic>),
  allowRebaseMerge: json['allow_rebase_merge'] as bool?,
  templateRepository: json['template_repository'] == null
      ? null
      : NullableRepository.fromJson(
          json['template_repository'] as Map<String, dynamic>,
        ),
  tempCloneToken: json['temp_clone_token'] as String?,
  allowSquashMerge: json['allow_squash_merge'] as bool?,
  allowAutoMerge: json['allow_auto_merge'] as bool?,
  deleteBranchOnMerge: json['delete_branch_on_merge'] as bool?,
  allowMergeCommit: json['allow_merge_commit'] as bool?,
  allowUpdateBranch: json['allow_update_branch'] as bool?,
  useSquashPrTitleAsDefault: json['use_squash_pr_title_as_default'] as bool?,
  squashMergeCommitTitle: json['squash_merge_commit_title'] == null
      ? null
      : FullRepositorySquashMergeCommitTitle.fromJson(
          json['squash_merge_commit_title'] as String,
        ),
  squashMergeCommitMessage: json['squash_merge_commit_message'] == null
      ? null
      : FullRepositorySquashMergeCommitMessage.fromJson(
          json['squash_merge_commit_message'] as String,
        ),
  mergeCommitTitle: json['merge_commit_title'] == null
      ? null
      : FullRepositoryMergeCommitTitle.fromJson(
          json['merge_commit_title'] as String,
        ),
  mergeCommitMessage: json['merge_commit_message'] == null
      ? null
      : FullRepositoryMergeCommitMessage.fromJson(
          json['merge_commit_message'] as String,
        ),
  allowForking: json['allow_forking'] as bool?,
  webCommitSignoffRequired: json['web_commit_signoff_required'] as bool?,
  customProperties: json['custom_properties'],
  pullRequestCreationPolicy: json['pull_request_creation_policy'] == null
      ? null
      : FullRepositoryPullRequestCreationPolicy.fromJson(
          json['pull_request_creation_policy'] as String,
        ),
  hasPullRequests: json['has_pull_requests'] as bool?,
  organization: json['organization'] == null
      ? null
      : NullableSimpleUser.fromJson(
          json['organization'] as Map<String, dynamic>,
        ),
  parent: json['parent'] == null
      ? null
      : Repository.fromJson(json['parent'] as Map<String, dynamic>),
  source: json['source'] == null
      ? null
      : Repository.fromJson(json['source'] as Map<String, dynamic>),
  hasDownloads: json['has_downloads'] as bool?,
  masterBranch: json['master_branch'] as String?,
  topics: (json['topics'] as List<dynamic>?)?.map((e) => e as String).toList(),
  isTemplate: json['is_template'] as bool?,
  codeOfConduct: json['code_of_conduct'] == null
      ? null
      : CodeOfConductSimple.fromJson(
          json['code_of_conduct'] as Map<String, dynamic>,
        ),
  securityAndAnalysis: json['security_and_analysis'] == null
      ? null
      : SecurityAndAnalysis.fromJson(
          json['security_and_analysis'] as Map<String, dynamic>,
        ),
  visibility: json['visibility'] as String?,
);

Map<String, dynamic> _$FullRepositoryToJson(
  _FullRepository instance,
) => <String, dynamic>{
  'milestones_url': instance.milestonesUrl,
  'node_id': instance.nodeId,
  'name': instance.name,
  'full_name': instance.fullName,
  'owner': instance.owner,
  'private': instance.private,
  'html_url': instance.htmlUrl,
  'description': instance.description,
  'fork': instance.fork,
  'url': instance.url,
  'archive_url': instance.archiveUrl,
  'assignees_url': instance.assigneesUrl,
  'blobs_url': instance.blobsUrl,
  'branches_url': instance.branchesUrl,
  'collaborators_url': instance.collaboratorsUrl,
  'comments_url': instance.commentsUrl,
  'commits_url': instance.commitsUrl,
  'compare_url': instance.compareUrl,
  'contents_url': instance.contentsUrl,
  'contributors_url': instance.contributorsUrl,
  'deployments_url': instance.deploymentsUrl,
  'downloads_url': instance.downloadsUrl,
  'events_url': instance.eventsUrl,
  'forks_url': instance.forksUrl,
  'git_commits_url': instance.gitCommitsUrl,
  'git_refs_url': instance.gitRefsUrl,
  'git_tags_url': instance.gitTagsUrl,
  'git_url': instance.gitUrl,
  'issue_comment_url': instance.issueCommentUrl,
  'issue_events_url': instance.issueEventsUrl,
  'issues_url': instance.issuesUrl,
  'keys_url': instance.keysUrl,
  'labels_url': instance.labelsUrl,
  'languages_url': instance.languagesUrl,
  'merges_url': instance.mergesUrl,
  'id': instance.id,
  'notifications_url': instance.notificationsUrl,
  'pulls_url': instance.pullsUrl,
  'releases_url': instance.releasesUrl,
  'ssh_url': instance.sshUrl,
  'stargazers_url': instance.stargazersUrl,
  'statuses_url': instance.statusesUrl,
  'subscribers_url': instance.subscribersUrl,
  'subscription_url': instance.subscriptionUrl,
  'tags_url': instance.tagsUrl,
  'teams_url': instance.teamsUrl,
  'trees_url': instance.treesUrl,
  'clone_url': instance.cloneUrl,
  'mirror_url': instance.mirrorUrl,
  'hooks_url': instance.hooksUrl,
  'svn_url': instance.svnUrl,
  'homepage': instance.homepage,
  'Language': instance.language,
  'forks_count': instance.forksCount,
  'stargazers_count': instance.stargazersCount,
  'watchers_count': instance.watchersCount,
  'size': instance.size,
  'default_branch': instance.defaultBranch,
  'open_issues_count': instance.openIssuesCount,
  'watchers': instance.watchers,
  'open_issues': instance.openIssues,
  'has_issues': instance.hasIssues,
  'has_projects': instance.hasProjects,
  'has_wiki': instance.hasWiki,
  'has_pages': instance.hasPages,
  'forks': instance.forks,
  'has_discussions': instance.hasDiscussions,
  'License': instance.license,
  'network_count': instance.networkCount,
  'subscribers_count': instance.subscribersCount,
  'disabled': instance.disabled,
  'updated_at': instance.updatedAt.toIso8601String(),
  'pushed_at': instance.pushedAt.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
  'archived': instance.archived,
  'anonymous_access_enabled': instance.anonymousAccessEnabled,
  'permissions': instance.permissions,
  'allow_rebase_merge': instance.allowRebaseMerge,
  'template_repository': instance.templateRepository,
  'temp_clone_token': instance.tempCloneToken,
  'allow_squash_merge': instance.allowSquashMerge,
  'allow_auto_merge': instance.allowAutoMerge,
  'delete_branch_on_merge': instance.deleteBranchOnMerge,
  'allow_merge_commit': instance.allowMergeCommit,
  'allow_update_branch': instance.allowUpdateBranch,
  'use_squash_pr_title_as_default': instance.useSquashPrTitleAsDefault,
  'squash_merge_commit_title':
      _$FullRepositorySquashMergeCommitTitleEnumMap[instance
          .squashMergeCommitTitle],
  'squash_merge_commit_message':
      _$FullRepositorySquashMergeCommitMessageEnumMap[instance
          .squashMergeCommitMessage],
  'merge_commit_title':
      _$FullRepositoryMergeCommitTitleEnumMap[instance.mergeCommitTitle],
  'merge_commit_message':
      _$FullRepositoryMergeCommitMessageEnumMap[instance.mergeCommitMessage],
  'allow_forking': instance.allowForking,
  'web_commit_signoff_required': instance.webCommitSignoffRequired,
  'custom_properties': instance.customProperties,
  'pull_request_creation_policy':
      _$FullRepositoryPullRequestCreationPolicyEnumMap[instance
          .pullRequestCreationPolicy],
  'has_pull_requests': instance.hasPullRequests,
  'organization': instance.organization,
  'parent': instance.parent,
  'source': instance.source,
  'has_downloads': instance.hasDownloads,
  'master_branch': instance.masterBranch,
  'topics': instance.topics,
  'is_template': instance.isTemplate,
  'code_of_conduct': instance.codeOfConduct,
  'security_and_analysis': instance.securityAndAnalysis,
  'visibility': instance.visibility,
};

const _$FullRepositorySquashMergeCommitTitleEnumMap = {
  FullRepositorySquashMergeCommitTitle.prTitle: 'PR_TITLE',
  FullRepositorySquashMergeCommitTitle.commitOrPrTitle: 'COMMIT_OR_PR_TITLE',
  FullRepositorySquashMergeCommitTitle.$unknown: r'$unknown',
};

const _$FullRepositorySquashMergeCommitMessageEnumMap = {
  FullRepositorySquashMergeCommitMessage.prBody: 'PR_BODY',
  FullRepositorySquashMergeCommitMessage.commitMessages: 'COMMIT_MESSAGES',
  FullRepositorySquashMergeCommitMessage.blank: 'BLANK',
  FullRepositorySquashMergeCommitMessage.$unknown: r'$unknown',
};

const _$FullRepositoryMergeCommitTitleEnumMap = {
  FullRepositoryMergeCommitTitle.prTitle: 'PR_TITLE',
  FullRepositoryMergeCommitTitle.mergeMessage: 'MERGE_MESSAGE',
  FullRepositoryMergeCommitTitle.$unknown: r'$unknown',
};

const _$FullRepositoryMergeCommitMessageEnumMap = {
  FullRepositoryMergeCommitMessage.prBody: 'PR_BODY',
  FullRepositoryMergeCommitMessage.prTitle: 'PR_TITLE',
  FullRepositoryMergeCommitMessage.blank: 'BLANK',
  FullRepositoryMergeCommitMessage.$unknown: r'$unknown',
};

const _$FullRepositoryPullRequestCreationPolicyEnumMap = {
  FullRepositoryPullRequestCreationPolicy.all: 'all',
  FullRepositoryPullRequestCreationPolicy.collaboratorsOnly:
      'collaborators_only',
  FullRepositoryPullRequestCreationPolicy.$unknown: r'$unknown',
};
