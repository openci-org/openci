// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nullable_repository.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NullableRepository _$NullableRepositoryFromJson(
  Map<String, dynamic> json,
) => _NullableRepository(
  issueEventsUrl: json['issue_events_url'] as String,
  nodeId: json['node_id'] as String,
  name: json['name'] as String,
  fullName: json['full_name'] as String,
  license: json['License'] == null
      ? null
      : NullableLicenseSimple.fromJson(json['License'] as Map<String, dynamic>),
  forks: (json['forks'] as num).toInt(),
  watchers: (json['watchers'] as num).toInt(),
  owner: SimpleUser.fromJson(json['owner'] as Map<String, dynamic>),
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
  id: (json['id'] as num).toInt(),
  issuesUrl: json['issues_url'] as String,
  keysUrl: json['keys_url'] as String,
  labelsUrl: json['labels_url'] as String,
  languagesUrl: json['languages_url'] as String,
  mergesUrl: json['merges_url'] as String,
  milestonesUrl: json['milestones_url'] as String,
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
  openIssues: (json['open_issues'] as num).toInt(),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  pushedAt: json['pushed_at'] == null
      ? null
      : DateTime.parse(json['pushed_at'] as String),
  disabled: json['disabled'] as bool,
  hasPages: json['has_pages'] as bool,
  hasWiki: json['has_wiki'] as bool? ?? true,
  hasDownloads: json['has_downloads'] as bool? ?? true,
  hasDiscussions: json['has_discussions'] as bool? ?? false,
  hasPullRequests: json['has_pull_requests'] as bool? ?? true,
  allowMergeCommit: json['allow_merge_commit'] as bool? ?? true,
  archived: json['archived'] as bool? ?? false,
  hasProjects: json['has_projects'] as bool? ?? true,
  visibility: json['visibility'] as String? ?? 'public',
  webCommitSignoffRequired:
      json['web_commit_signoff_required'] as bool? ?? false,
  isTemplate: json['is_template'] as bool? ?? false,
  private: json['private'] as bool? ?? false,
  allowRebaseMerge: json['allow_rebase_merge'] as bool? ?? true,
  useSquashPrTitleAsDefault:
      json['use_squash_pr_title_as_default'] as bool? ?? false,
  allowSquashMerge: json['allow_squash_merge'] as bool? ?? true,
  allowAutoMerge: json['allow_auto_merge'] as bool? ?? false,
  deleteBranchOnMerge: json['delete_branch_on_merge'] as bool? ?? false,
  allowUpdateBranch: json['allow_update_branch'] as bool? ?? false,
  hasIssues: json['has_issues'] as bool? ?? true,
  squashMergeCommitTitle: json['squash_merge_commit_title'] == null
      ? null
      : NullableRepositorySquashMergeCommitTitle.fromJson(
          json['squash_merge_commit_title'] as String,
        ),
  squashMergeCommitMessage: json['squash_merge_commit_message'] == null
      ? null
      : NullableRepositorySquashMergeCommitMessage.fromJson(
          json['squash_merge_commit_message'] as String,
        ),
  mergeCommitTitle: json['merge_commit_title'] == null
      ? null
      : NullableRepositoryMergeCommitTitle.fromJson(
          json['merge_commit_title'] as String,
        ),
  mergeCommitMessage: json['merge_commit_message'] == null
      ? null
      : NullableRepositoryMergeCommitMessage.fromJson(
          json['merge_commit_message'] as String,
        ),
  pullRequestCreationPolicy: json['pull_request_creation_policy'] == null
      ? null
      : NullableRepositoryPullRequestCreationPolicy.fromJson(
          json['pull_request_creation_policy'] as String,
        ),
  allowForking: json['allow_forking'] as bool?,
  codeSearchIndexStatus: json['code_search_index_status'] == null
      ? null
      : CodeSearchIndexStatus2.fromJson(
          json['code_search_index_status'] as Map<String, dynamic>,
        ),
  topics: (json['topics'] as List<dynamic>?)?.map((e) => e as String).toList(),
  permissions: json['permissions'] == null
      ? null
      : Permissions10.fromJson(json['permissions'] as Map<String, dynamic>),
  masterBranch: json['master_branch'] as String?,
  starredAt: json['starred_at'] as String?,
  anonymousAccessEnabled: json['anonymous_access_enabled'] as bool?,
  tempCloneToken: json['temp_clone_token'] as String?,
);

Map<String, dynamic> _$NullableRepositoryToJson(
  _NullableRepository instance,
) => <String, dynamic>{
  'issue_events_url': instance.issueEventsUrl,
  'node_id': instance.nodeId,
  'name': instance.name,
  'full_name': instance.fullName,
  'License': instance.license,
  'forks': instance.forks,
  'watchers': instance.watchers,
  'owner': instance.owner,
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
  'id': instance.id,
  'issues_url': instance.issuesUrl,
  'keys_url': instance.keysUrl,
  'labels_url': instance.labelsUrl,
  'languages_url': instance.languagesUrl,
  'merges_url': instance.mergesUrl,
  'milestones_url': instance.milestonesUrl,
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
  'open_issues': instance.openIssues,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'pushed_at': instance.pushedAt?.toIso8601String(),
  'disabled': instance.disabled,
  'has_pages': instance.hasPages,
  'has_wiki': instance.hasWiki,
  'has_downloads': instance.hasDownloads,
  'has_discussions': instance.hasDiscussions,
  'has_pull_requests': instance.hasPullRequests,
  'allow_merge_commit': instance.allowMergeCommit,
  'archived': instance.archived,
  'has_projects': instance.hasProjects,
  'visibility': instance.visibility,
  'web_commit_signoff_required': instance.webCommitSignoffRequired,
  'is_template': instance.isTemplate,
  'private': instance.private,
  'allow_rebase_merge': instance.allowRebaseMerge,
  'use_squash_pr_title_as_default': instance.useSquashPrTitleAsDefault,
  'allow_squash_merge': instance.allowSquashMerge,
  'allow_auto_merge': instance.allowAutoMerge,
  'delete_branch_on_merge': instance.deleteBranchOnMerge,
  'allow_update_branch': instance.allowUpdateBranch,
  'has_issues': instance.hasIssues,
  'squash_merge_commit_title':
      _$NullableRepositorySquashMergeCommitTitleEnumMap[instance
          .squashMergeCommitTitle],
  'squash_merge_commit_message':
      _$NullableRepositorySquashMergeCommitMessageEnumMap[instance
          .squashMergeCommitMessage],
  'merge_commit_title':
      _$NullableRepositoryMergeCommitTitleEnumMap[instance.mergeCommitTitle],
  'merge_commit_message':
      _$NullableRepositoryMergeCommitMessageEnumMap[instance
          .mergeCommitMessage],
  'pull_request_creation_policy':
      _$NullableRepositoryPullRequestCreationPolicyEnumMap[instance
          .pullRequestCreationPolicy],
  'allow_forking': instance.allowForking,
  'code_search_index_status': instance.codeSearchIndexStatus,
  'topics': instance.topics,
  'permissions': instance.permissions,
  'master_branch': instance.masterBranch,
  'starred_at': instance.starredAt,
  'anonymous_access_enabled': instance.anonymousAccessEnabled,
  'temp_clone_token': instance.tempCloneToken,
};

const _$NullableRepositorySquashMergeCommitTitleEnumMap = {
  NullableRepositorySquashMergeCommitTitle.prTitle: 'PR_TITLE',
  NullableRepositorySquashMergeCommitTitle.commitOrPrTitle:
      'COMMIT_OR_PR_TITLE',
  NullableRepositorySquashMergeCommitTitle.$unknown: r'$unknown',
};

const _$NullableRepositorySquashMergeCommitMessageEnumMap = {
  NullableRepositorySquashMergeCommitMessage.prBody: 'PR_BODY',
  NullableRepositorySquashMergeCommitMessage.commitMessages: 'COMMIT_MESSAGES',
  NullableRepositorySquashMergeCommitMessage.blank: 'BLANK',
  NullableRepositorySquashMergeCommitMessage.$unknown: r'$unknown',
};

const _$NullableRepositoryMergeCommitTitleEnumMap = {
  NullableRepositoryMergeCommitTitle.prTitle: 'PR_TITLE',
  NullableRepositoryMergeCommitTitle.mergeMessage: 'MERGE_MESSAGE',
  NullableRepositoryMergeCommitTitle.$unknown: r'$unknown',
};

const _$NullableRepositoryMergeCommitMessageEnumMap = {
  NullableRepositoryMergeCommitMessage.prBody: 'PR_BODY',
  NullableRepositoryMergeCommitMessage.prTitle: 'PR_TITLE',
  NullableRepositoryMergeCommitMessage.blank: 'BLANK',
  NullableRepositoryMergeCommitMessage.$unknown: r'$unknown',
};

const _$NullableRepositoryPullRequestCreationPolicyEnumMap = {
  NullableRepositoryPullRequestCreationPolicy.all: 'all',
  NullableRepositoryPullRequestCreationPolicy.collaboratorsOnly:
      'collaborators_only',
  NullableRepositoryPullRequestCreationPolicy.$unknown: r'$unknown',
};
