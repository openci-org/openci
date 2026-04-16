// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nullable_repository.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NullableRepository {

@JsonKey(name: 'issue_events_url') String get issueEventsUrl;@JsonKey(name: 'node_id') String get nodeId;/// The name of the repository.
 String get name;@JsonKey(name: 'full_name') String get fullName;@JsonKey(name: 'License') NullableLicenseSimple? get license; int get forks; int get watchers; SimpleUser get owner;@JsonKey(name: 'html_url') String get htmlUrl; String? get description; bool get fork; String get url;@JsonKey(name: 'archive_url') String get archiveUrl;@JsonKey(name: 'assignees_url') String get assigneesUrl;@JsonKey(name: 'blobs_url') String get blobsUrl;@JsonKey(name: 'branches_url') String get branchesUrl;@JsonKey(name: 'collaborators_url') String get collaboratorsUrl;@JsonKey(name: 'comments_url') String get commentsUrl;@JsonKey(name: 'commits_url') String get commitsUrl;@JsonKey(name: 'compare_url') String get compareUrl;@JsonKey(name: 'contents_url') String get contentsUrl;@JsonKey(name: 'contributors_url') String get contributorsUrl;@JsonKey(name: 'deployments_url') String get deploymentsUrl;@JsonKey(name: 'downloads_url') String get downloadsUrl;@JsonKey(name: 'events_url') String get eventsUrl;@JsonKey(name: 'forks_url') String get forksUrl;@JsonKey(name: 'git_commits_url') String get gitCommitsUrl;@JsonKey(name: 'git_refs_url') String get gitRefsUrl;@JsonKey(name: 'git_tags_url') String get gitTagsUrl;@JsonKey(name: 'git_url') String get gitUrl;@JsonKey(name: 'issue_comment_url') String get issueCommentUrl;/// Unique identifier of the Repository
 int get id;@JsonKey(name: 'issues_url') String get issuesUrl;@JsonKey(name: 'keys_url') String get keysUrl;@JsonKey(name: 'labels_url') String get labelsUrl;@JsonKey(name: 'languages_url') String get languagesUrl;@JsonKey(name: 'merges_url') String get mergesUrl;@JsonKey(name: 'milestones_url') String get milestonesUrl;@JsonKey(name: 'notifications_url') String get notificationsUrl;@JsonKey(name: 'pulls_url') String get pullsUrl;@JsonKey(name: 'releases_url') String get releasesUrl;@JsonKey(name: 'ssh_url') String get sshUrl;@JsonKey(name: 'stargazers_url') String get stargazersUrl;@JsonKey(name: 'statuses_url') String get statusesUrl;@JsonKey(name: 'subscribers_url') String get subscribersUrl;@JsonKey(name: 'subscription_url') String get subscriptionUrl;@JsonKey(name: 'tags_url') String get tagsUrl;@JsonKey(name: 'teams_url') String get teamsUrl;@JsonKey(name: 'trees_url') String get treesUrl;@JsonKey(name: 'clone_url') String get cloneUrl;@JsonKey(name: 'mirror_url') String? get mirrorUrl;@JsonKey(name: 'hooks_url') String get hooksUrl;@JsonKey(name: 'svn_url') String get svnUrl; String? get homepage;@JsonKey(name: 'Language') String? get language;@JsonKey(name: 'forks_count') int get forksCount;@JsonKey(name: 'stargazers_count') int get stargazersCount;@JsonKey(name: 'watchers_count') int get watchersCount;/// The size of the repository, in kilobytes. Size is calculated hourly. When a Repository is initially created, the size is 0.
 int get size;/// The default branch of the repository.
@JsonKey(name: 'default_branch') String get defaultBranch;@JsonKey(name: 'open_issues_count') int get openIssuesCount;@JsonKey(name: 'open_issues') int get openIssues;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;@JsonKey(name: 'pushed_at') DateTime? get pushedAt;/// Returns whether or not this Repository disabled.
 bool get disabled;@JsonKey(name: 'has_pages') bool get hasPages;/// Whether the wiki is enabled.
@JsonKey(name: 'has_wiki') bool get hasWiki;/// Whether downloads are enabled.
@JsonKey(name: 'has_downloads')@Deprecated('This is marked as deprecated') bool get hasDownloads;/// Whether discussions are enabled.
@JsonKey(name: 'has_discussions') bool get hasDiscussions;/// Whether pull requests are enabled.
@JsonKey(name: 'has_pull_requests') bool get hasPullRequests;/// Whether to allow merge commits for pull requests.
@JsonKey(name: 'allow_merge_commit') bool get allowMergeCommit;/// Whether the Repository is archived.
 bool get archived;/// Whether projects are enabled.
@JsonKey(name: 'has_projects') bool get hasProjects;/// The Repository visibility: public, private, or internal.
 String get visibility;/// Whether to require contributors to sign off on web-based commits
@JsonKey(name: 'web_commit_signoff_required') bool get webCommitSignoffRequired;/// Whether this Repository acts as a template that can be used to generate new repositories.
@JsonKey(name: 'is_template') bool get isTemplate;/// Whether the Repository is private or public.
 bool get private;/// Whether to allow rebase merges for pull requests.
@JsonKey(name: 'allow_rebase_merge') bool get allowRebaseMerge;/// Whether a squash merge Commit can use the pull request title as default. **This property is closing down. Please use `squash_merge_commit_title` instead.
@JsonKey(name: 'use_squash_pr_title_as_default')@Deprecated('This is marked as deprecated') bool get useSquashPrTitleAsDefault;/// Whether to allow squash merges for pull requests.
@JsonKey(name: 'allow_squash_merge') bool get allowSquashMerge;/// Whether to allow Auto-merge to be used on pull requests.
@JsonKey(name: 'allow_auto_merge') bool get allowAutoMerge;/// Whether to delete head branches when pull requests are merged
@JsonKey(name: 'delete_branch_on_merge') bool get deleteBranchOnMerge;/// Whether or not a pull request head branch that is behind its base branch can always be updated even if it is not required to be up to date before merging.
@JsonKey(name: 'allow_update_branch') bool get allowUpdateBranch;/// Whether issues are enabled.
@JsonKey(name: 'has_issues') bool get hasIssues;/// The default value for a squash merge Commit title:.
///
/// - `PR_TITLE` - default to the pull request's title.
/// - `COMMIT_OR_PR_TITLE` - default to the Commit's title (if only one commit) or the pull request's title (when more than one commit).
@JsonKey(name: 'squash_merge_commit_title') NullableRepositorySquashMergeCommitTitle? get squashMergeCommitTitle;/// The default value for a squash merge Commit message:.
///
/// - `PR_BODY` - default to the pull request's body.
/// - `COMMIT_MESSAGES` - default to the branch's Commit messages.
/// - `BLANK` - default to a blank Commit message.
@JsonKey(name: 'squash_merge_commit_message') NullableRepositorySquashMergeCommitMessage? get squashMergeCommitMessage;/// The default value for a merge Commit title.
///
/// - `PR_TITLE` - default to the pull request's title.
/// - `MERGE_MESSAGE` - default to the classic title for a merge message (e.g., Merge pull request #123 from branch-name).
@JsonKey(name: 'merge_commit_title') NullableRepositoryMergeCommitTitle? get mergeCommitTitle;/// The default value for a merge Commit message.
///
/// - `PR_TITLE` - default to the pull request's title.
/// - `PR_BODY` - default to the pull request's body.
/// - `BLANK` - default to a blank Commit message.
@JsonKey(name: 'merge_commit_message') NullableRepositoryMergeCommitMessage? get mergeCommitMessage;/// The policy controlling who can create pull requests: all or collaborators_only.
@JsonKey(name: 'pull_request_creation_policy') NullableRepositoryPullRequestCreationPolicy? get pullRequestCreationPolicy;/// Whether to allow forking this repo
@JsonKey(name: 'allow_forking') bool? get allowForking;/// The Status of the code search index for this Repository
@JsonKey(name: 'code_search_index_status') CodeSearchIndexStatus2? get codeSearchIndexStatus; List<String>? get topics; Permissions10? get permissions;@JsonKey(name: 'master_branch') String? get masterBranch;@JsonKey(name: 'starred_at') String? get starredAt;/// Whether anonymous git access is enabled for this Repository
@JsonKey(name: 'anonymous_access_enabled') bool? get anonymousAccessEnabled;@JsonKey(name: 'temp_clone_token') String? get tempCloneToken;
/// Create a copy of NullableRepository
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NullableRepositoryCopyWith<NullableRepository> get copyWith => _$NullableRepositoryCopyWithImpl<NullableRepository>(this as NullableRepository, _$identity);

  /// Serializes this NullableRepository to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NullableRepository&&(identical(other.issueEventsUrl, issueEventsUrl) || other.issueEventsUrl == issueEventsUrl)&&(identical(other.nodeId, nodeId) || other.nodeId == nodeId)&&(identical(other.name, name) || other.name == name)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.license, license) || other.license == license)&&(identical(other.forks, forks) || other.forks == forks)&&(identical(other.watchers, watchers) || other.watchers == watchers)&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.htmlUrl, htmlUrl) || other.htmlUrl == htmlUrl)&&(identical(other.description, description) || other.description == description)&&(identical(other.fork, fork) || other.fork == fork)&&(identical(other.url, url) || other.url == url)&&(identical(other.archiveUrl, archiveUrl) || other.archiveUrl == archiveUrl)&&(identical(other.assigneesUrl, assigneesUrl) || other.assigneesUrl == assigneesUrl)&&(identical(other.blobsUrl, blobsUrl) || other.blobsUrl == blobsUrl)&&(identical(other.branchesUrl, branchesUrl) || other.branchesUrl == branchesUrl)&&(identical(other.collaboratorsUrl, collaboratorsUrl) || other.collaboratorsUrl == collaboratorsUrl)&&(identical(other.commentsUrl, commentsUrl) || other.commentsUrl == commentsUrl)&&(identical(other.commitsUrl, commitsUrl) || other.commitsUrl == commitsUrl)&&(identical(other.compareUrl, compareUrl) || other.compareUrl == compareUrl)&&(identical(other.contentsUrl, contentsUrl) || other.contentsUrl == contentsUrl)&&(identical(other.contributorsUrl, contributorsUrl) || other.contributorsUrl == contributorsUrl)&&(identical(other.deploymentsUrl, deploymentsUrl) || other.deploymentsUrl == deploymentsUrl)&&(identical(other.downloadsUrl, downloadsUrl) || other.downloadsUrl == downloadsUrl)&&(identical(other.eventsUrl, eventsUrl) || other.eventsUrl == eventsUrl)&&(identical(other.forksUrl, forksUrl) || other.forksUrl == forksUrl)&&(identical(other.gitCommitsUrl, gitCommitsUrl) || other.gitCommitsUrl == gitCommitsUrl)&&(identical(other.gitRefsUrl, gitRefsUrl) || other.gitRefsUrl == gitRefsUrl)&&(identical(other.gitTagsUrl, gitTagsUrl) || other.gitTagsUrl == gitTagsUrl)&&(identical(other.gitUrl, gitUrl) || other.gitUrl == gitUrl)&&(identical(other.issueCommentUrl, issueCommentUrl) || other.issueCommentUrl == issueCommentUrl)&&(identical(other.id, id) || other.id == id)&&(identical(other.issuesUrl, issuesUrl) || other.issuesUrl == issuesUrl)&&(identical(other.keysUrl, keysUrl) || other.keysUrl == keysUrl)&&(identical(other.labelsUrl, labelsUrl) || other.labelsUrl == labelsUrl)&&(identical(other.languagesUrl, languagesUrl) || other.languagesUrl == languagesUrl)&&(identical(other.mergesUrl, mergesUrl) || other.mergesUrl == mergesUrl)&&(identical(other.milestonesUrl, milestonesUrl) || other.milestonesUrl == milestonesUrl)&&(identical(other.notificationsUrl, notificationsUrl) || other.notificationsUrl == notificationsUrl)&&(identical(other.pullsUrl, pullsUrl) || other.pullsUrl == pullsUrl)&&(identical(other.releasesUrl, releasesUrl) || other.releasesUrl == releasesUrl)&&(identical(other.sshUrl, sshUrl) || other.sshUrl == sshUrl)&&(identical(other.stargazersUrl, stargazersUrl) || other.stargazersUrl == stargazersUrl)&&(identical(other.statusesUrl, statusesUrl) || other.statusesUrl == statusesUrl)&&(identical(other.subscribersUrl, subscribersUrl) || other.subscribersUrl == subscribersUrl)&&(identical(other.subscriptionUrl, subscriptionUrl) || other.subscriptionUrl == subscriptionUrl)&&(identical(other.tagsUrl, tagsUrl) || other.tagsUrl == tagsUrl)&&(identical(other.teamsUrl, teamsUrl) || other.teamsUrl == teamsUrl)&&(identical(other.treesUrl, treesUrl) || other.treesUrl == treesUrl)&&(identical(other.cloneUrl, cloneUrl) || other.cloneUrl == cloneUrl)&&(identical(other.mirrorUrl, mirrorUrl) || other.mirrorUrl == mirrorUrl)&&(identical(other.hooksUrl, hooksUrl) || other.hooksUrl == hooksUrl)&&(identical(other.svnUrl, svnUrl) || other.svnUrl == svnUrl)&&(identical(other.homepage, homepage) || other.homepage == homepage)&&(identical(other.language, language) || other.language == language)&&(identical(other.forksCount, forksCount) || other.forksCount == forksCount)&&(identical(other.stargazersCount, stargazersCount) || other.stargazersCount == stargazersCount)&&(identical(other.watchersCount, watchersCount) || other.watchersCount == watchersCount)&&(identical(other.size, size) || other.size == size)&&(identical(other.defaultBranch, defaultBranch) || other.defaultBranch == defaultBranch)&&(identical(other.openIssuesCount, openIssuesCount) || other.openIssuesCount == openIssuesCount)&&(identical(other.openIssues, openIssues) || other.openIssues == openIssues)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.pushedAt, pushedAt) || other.pushedAt == pushedAt)&&(identical(other.disabled, disabled) || other.disabled == disabled)&&(identical(other.hasPages, hasPages) || other.hasPages == hasPages)&&(identical(other.hasWiki, hasWiki) || other.hasWiki == hasWiki)&&(identical(other.hasDownloads, hasDownloads) || other.hasDownloads == hasDownloads)&&(identical(other.hasDiscussions, hasDiscussions) || other.hasDiscussions == hasDiscussions)&&(identical(other.hasPullRequests, hasPullRequests) || other.hasPullRequests == hasPullRequests)&&(identical(other.allowMergeCommit, allowMergeCommit) || other.allowMergeCommit == allowMergeCommit)&&(identical(other.archived, archived) || other.archived == archived)&&(identical(other.hasProjects, hasProjects) || other.hasProjects == hasProjects)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.webCommitSignoffRequired, webCommitSignoffRequired) || other.webCommitSignoffRequired == webCommitSignoffRequired)&&(identical(other.isTemplate, isTemplate) || other.isTemplate == isTemplate)&&(identical(other.private, private) || other.private == private)&&(identical(other.allowRebaseMerge, allowRebaseMerge) || other.allowRebaseMerge == allowRebaseMerge)&&(identical(other.useSquashPrTitleAsDefault, useSquashPrTitleAsDefault) || other.useSquashPrTitleAsDefault == useSquashPrTitleAsDefault)&&(identical(other.allowSquashMerge, allowSquashMerge) || other.allowSquashMerge == allowSquashMerge)&&(identical(other.allowAutoMerge, allowAutoMerge) || other.allowAutoMerge == allowAutoMerge)&&(identical(other.deleteBranchOnMerge, deleteBranchOnMerge) || other.deleteBranchOnMerge == deleteBranchOnMerge)&&(identical(other.allowUpdateBranch, allowUpdateBranch) || other.allowUpdateBranch == allowUpdateBranch)&&(identical(other.hasIssues, hasIssues) || other.hasIssues == hasIssues)&&(identical(other.squashMergeCommitTitle, squashMergeCommitTitle) || other.squashMergeCommitTitle == squashMergeCommitTitle)&&(identical(other.squashMergeCommitMessage, squashMergeCommitMessage) || other.squashMergeCommitMessage == squashMergeCommitMessage)&&(identical(other.mergeCommitTitle, mergeCommitTitle) || other.mergeCommitTitle == mergeCommitTitle)&&(identical(other.mergeCommitMessage, mergeCommitMessage) || other.mergeCommitMessage == mergeCommitMessage)&&(identical(other.pullRequestCreationPolicy, pullRequestCreationPolicy) || other.pullRequestCreationPolicy == pullRequestCreationPolicy)&&(identical(other.allowForking, allowForking) || other.allowForking == allowForking)&&(identical(other.codeSearchIndexStatus, codeSearchIndexStatus) || other.codeSearchIndexStatus == codeSearchIndexStatus)&&const DeepCollectionEquality().equals(other.topics, topics)&&(identical(other.permissions, permissions) || other.permissions == permissions)&&(identical(other.masterBranch, masterBranch) || other.masterBranch == masterBranch)&&(identical(other.starredAt, starredAt) || other.starredAt == starredAt)&&(identical(other.anonymousAccessEnabled, anonymousAccessEnabled) || other.anonymousAccessEnabled == anonymousAccessEnabled)&&(identical(other.tempCloneToken, tempCloneToken) || other.tempCloneToken == tempCloneToken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,issueEventsUrl,nodeId,name,fullName,license,forks,watchers,owner,htmlUrl,description,fork,url,archiveUrl,assigneesUrl,blobsUrl,branchesUrl,collaboratorsUrl,commentsUrl,commitsUrl,compareUrl,contentsUrl,contributorsUrl,deploymentsUrl,downloadsUrl,eventsUrl,forksUrl,gitCommitsUrl,gitRefsUrl,gitTagsUrl,gitUrl,issueCommentUrl,id,issuesUrl,keysUrl,labelsUrl,languagesUrl,mergesUrl,milestonesUrl,notificationsUrl,pullsUrl,releasesUrl,sshUrl,stargazersUrl,statusesUrl,subscribersUrl,subscriptionUrl,tagsUrl,teamsUrl,treesUrl,cloneUrl,mirrorUrl,hooksUrl,svnUrl,homepage,language,forksCount,stargazersCount,watchersCount,size,defaultBranch,openIssuesCount,openIssues,createdAt,updatedAt,pushedAt,disabled,hasPages,hasWiki,hasDownloads,hasDiscussions,hasPullRequests,allowMergeCommit,archived,hasProjects,visibility,webCommitSignoffRequired,isTemplate,private,allowRebaseMerge,useSquashPrTitleAsDefault,allowSquashMerge,allowAutoMerge,deleteBranchOnMerge,allowUpdateBranch,hasIssues,squashMergeCommitTitle,squashMergeCommitMessage,mergeCommitTitle,mergeCommitMessage,pullRequestCreationPolicy,allowForking,codeSearchIndexStatus,const DeepCollectionEquality().hash(topics),permissions,masterBranch,starredAt,anonymousAccessEnabled,tempCloneToken]);

@override
String toString() {
  return 'NullableRepository(issueEventsUrl: $issueEventsUrl, nodeId: $nodeId, name: $name, fullName: $fullName, license: $license, forks: $forks, watchers: $watchers, owner: $owner, htmlUrl: $htmlUrl, description: $description, fork: $fork, url: $url, archiveUrl: $archiveUrl, assigneesUrl: $assigneesUrl, blobsUrl: $blobsUrl, branchesUrl: $branchesUrl, collaboratorsUrl: $collaboratorsUrl, commentsUrl: $commentsUrl, commitsUrl: $commitsUrl, compareUrl: $compareUrl, contentsUrl: $contentsUrl, contributorsUrl: $contributorsUrl, deploymentsUrl: $deploymentsUrl, downloadsUrl: $downloadsUrl, eventsUrl: $eventsUrl, forksUrl: $forksUrl, gitCommitsUrl: $gitCommitsUrl, gitRefsUrl: $gitRefsUrl, gitTagsUrl: $gitTagsUrl, gitUrl: $gitUrl, issueCommentUrl: $issueCommentUrl, id: $id, issuesUrl: $issuesUrl, keysUrl: $keysUrl, labelsUrl: $labelsUrl, languagesUrl: $languagesUrl, mergesUrl: $mergesUrl, milestonesUrl: $milestonesUrl, notificationsUrl: $notificationsUrl, pullsUrl: $pullsUrl, releasesUrl: $releasesUrl, sshUrl: $sshUrl, stargazersUrl: $stargazersUrl, statusesUrl: $statusesUrl, subscribersUrl: $subscribersUrl, subscriptionUrl: $subscriptionUrl, tagsUrl: $tagsUrl, teamsUrl: $teamsUrl, treesUrl: $treesUrl, cloneUrl: $cloneUrl, mirrorUrl: $mirrorUrl, hooksUrl: $hooksUrl, svnUrl: $svnUrl, homepage: $homepage, language: $language, forksCount: $forksCount, stargazersCount: $stargazersCount, watchersCount: $watchersCount, size: $size, defaultBranch: $defaultBranch, openIssuesCount: $openIssuesCount, openIssues: $openIssues, createdAt: $createdAt, updatedAt: $updatedAt, pushedAt: $pushedAt, disabled: $disabled, hasPages: $hasPages, hasWiki: $hasWiki, hasDownloads: $hasDownloads, hasDiscussions: $hasDiscussions, hasPullRequests: $hasPullRequests, allowMergeCommit: $allowMergeCommit, archived: $archived, hasProjects: $hasProjects, visibility: $visibility, webCommitSignoffRequired: $webCommitSignoffRequired, isTemplate: $isTemplate, private: $private, allowRebaseMerge: $allowRebaseMerge, useSquashPrTitleAsDefault: $useSquashPrTitleAsDefault, allowSquashMerge: $allowSquashMerge, allowAutoMerge: $allowAutoMerge, deleteBranchOnMerge: $deleteBranchOnMerge, allowUpdateBranch: $allowUpdateBranch, hasIssues: $hasIssues, squashMergeCommitTitle: $squashMergeCommitTitle, squashMergeCommitMessage: $squashMergeCommitMessage, mergeCommitTitle: $mergeCommitTitle, mergeCommitMessage: $mergeCommitMessage, pullRequestCreationPolicy: $pullRequestCreationPolicy, allowForking: $allowForking, codeSearchIndexStatus: $codeSearchIndexStatus, topics: $topics, permissions: $permissions, masterBranch: $masterBranch, starredAt: $starredAt, anonymousAccessEnabled: $anonymousAccessEnabled, tempCloneToken: $tempCloneToken)';
}


}

/// @nodoc
abstract mixin class $NullableRepositoryCopyWith<$Res>  {
  factory $NullableRepositoryCopyWith(NullableRepository value, $Res Function(NullableRepository) _then) = _$NullableRepositoryCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'issue_events_url') String issueEventsUrl,@JsonKey(name: 'node_id') String nodeId, String name,@JsonKey(name: 'full_name') String fullName,@JsonKey(name: 'License') NullableLicenseSimple? license, int forks, int watchers, SimpleUser owner,@JsonKey(name: 'html_url') String htmlUrl, String? description, bool fork, String url,@JsonKey(name: 'archive_url') String archiveUrl,@JsonKey(name: 'assignees_url') String assigneesUrl,@JsonKey(name: 'blobs_url') String blobsUrl,@JsonKey(name: 'branches_url') String branchesUrl,@JsonKey(name: 'collaborators_url') String collaboratorsUrl,@JsonKey(name: 'comments_url') String commentsUrl,@JsonKey(name: 'commits_url') String commitsUrl,@JsonKey(name: 'compare_url') String compareUrl,@JsonKey(name: 'contents_url') String contentsUrl,@JsonKey(name: 'contributors_url') String contributorsUrl,@JsonKey(name: 'deployments_url') String deploymentsUrl,@JsonKey(name: 'downloads_url') String downloadsUrl,@JsonKey(name: 'events_url') String eventsUrl,@JsonKey(name: 'forks_url') String forksUrl,@JsonKey(name: 'git_commits_url') String gitCommitsUrl,@JsonKey(name: 'git_refs_url') String gitRefsUrl,@JsonKey(name: 'git_tags_url') String gitTagsUrl,@JsonKey(name: 'git_url') String gitUrl,@JsonKey(name: 'issue_comment_url') String issueCommentUrl, int id,@JsonKey(name: 'issues_url') String issuesUrl,@JsonKey(name: 'keys_url') String keysUrl,@JsonKey(name: 'labels_url') String labelsUrl,@JsonKey(name: 'languages_url') String languagesUrl,@JsonKey(name: 'merges_url') String mergesUrl,@JsonKey(name: 'milestones_url') String milestonesUrl,@JsonKey(name: 'notifications_url') String notificationsUrl,@JsonKey(name: 'pulls_url') String pullsUrl,@JsonKey(name: 'releases_url') String releasesUrl,@JsonKey(name: 'ssh_url') String sshUrl,@JsonKey(name: 'stargazers_url') String stargazersUrl,@JsonKey(name: 'statuses_url') String statusesUrl,@JsonKey(name: 'subscribers_url') String subscribersUrl,@JsonKey(name: 'subscription_url') String subscriptionUrl,@JsonKey(name: 'tags_url') String tagsUrl,@JsonKey(name: 'teams_url') String teamsUrl,@JsonKey(name: 'trees_url') String treesUrl,@JsonKey(name: 'clone_url') String cloneUrl,@JsonKey(name: 'mirror_url') String? mirrorUrl,@JsonKey(name: 'hooks_url') String hooksUrl,@JsonKey(name: 'svn_url') String svnUrl, String? homepage,@JsonKey(name: 'Language') String? language,@JsonKey(name: 'forks_count') int forksCount,@JsonKey(name: 'stargazers_count') int stargazersCount,@JsonKey(name: 'watchers_count') int watchersCount, int size,@JsonKey(name: 'default_branch') String defaultBranch,@JsonKey(name: 'open_issues_count') int openIssuesCount,@JsonKey(name: 'open_issues') int openIssues,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'pushed_at') DateTime? pushedAt, bool disabled,@JsonKey(name: 'has_pages') bool hasPages,@JsonKey(name: 'has_wiki') bool hasWiki,@JsonKey(name: 'has_downloads')@Deprecated('This is marked as deprecated') bool hasDownloads,@JsonKey(name: 'has_discussions') bool hasDiscussions,@JsonKey(name: 'has_pull_requests') bool hasPullRequests,@JsonKey(name: 'allow_merge_commit') bool allowMergeCommit, bool archived,@JsonKey(name: 'has_projects') bool hasProjects, String visibility,@JsonKey(name: 'web_commit_signoff_required') bool webCommitSignoffRequired,@JsonKey(name: 'is_template') bool isTemplate, bool private,@JsonKey(name: 'allow_rebase_merge') bool allowRebaseMerge,@JsonKey(name: 'use_squash_pr_title_as_default')@Deprecated('This is marked as deprecated') bool useSquashPrTitleAsDefault,@JsonKey(name: 'allow_squash_merge') bool allowSquashMerge,@JsonKey(name: 'allow_auto_merge') bool allowAutoMerge,@JsonKey(name: 'delete_branch_on_merge') bool deleteBranchOnMerge,@JsonKey(name: 'allow_update_branch') bool allowUpdateBranch,@JsonKey(name: 'has_issues') bool hasIssues,@JsonKey(name: 'squash_merge_commit_title') NullableRepositorySquashMergeCommitTitle? squashMergeCommitTitle,@JsonKey(name: 'squash_merge_commit_message') NullableRepositorySquashMergeCommitMessage? squashMergeCommitMessage,@JsonKey(name: 'merge_commit_title') NullableRepositoryMergeCommitTitle? mergeCommitTitle,@JsonKey(name: 'merge_commit_message') NullableRepositoryMergeCommitMessage? mergeCommitMessage,@JsonKey(name: 'pull_request_creation_policy') NullableRepositoryPullRequestCreationPolicy? pullRequestCreationPolicy,@JsonKey(name: 'allow_forking') bool? allowForking,@JsonKey(name: 'code_search_index_status') CodeSearchIndexStatus2? codeSearchIndexStatus, List<String>? topics, Permissions10? permissions,@JsonKey(name: 'master_branch') String? masterBranch,@JsonKey(name: 'starred_at') String? starredAt,@JsonKey(name: 'anonymous_access_enabled') bool? anonymousAccessEnabled,@JsonKey(name: 'temp_clone_token') String? tempCloneToken
});


$NullableLicenseSimpleCopyWith<$Res>? get license;$SimpleUserCopyWith<$Res> get owner;$CodeSearchIndexStatus2CopyWith<$Res>? get codeSearchIndexStatus;$Permissions10CopyWith<$Res>? get permissions;

}
/// @nodoc
class _$NullableRepositoryCopyWithImpl<$Res>
    implements $NullableRepositoryCopyWith<$Res> {
  _$NullableRepositoryCopyWithImpl(this._self, this._then);

  final NullableRepository _self;
  final $Res Function(NullableRepository) _then;

/// Create a copy of NullableRepository
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? issueEventsUrl = null,Object? nodeId = null,Object? name = null,Object? fullName = null,Object? license = freezed,Object? forks = null,Object? watchers = null,Object? owner = null,Object? htmlUrl = null,Object? description = freezed,Object? fork = null,Object? url = null,Object? archiveUrl = null,Object? assigneesUrl = null,Object? blobsUrl = null,Object? branchesUrl = null,Object? collaboratorsUrl = null,Object? commentsUrl = null,Object? commitsUrl = null,Object? compareUrl = null,Object? contentsUrl = null,Object? contributorsUrl = null,Object? deploymentsUrl = null,Object? downloadsUrl = null,Object? eventsUrl = null,Object? forksUrl = null,Object? gitCommitsUrl = null,Object? gitRefsUrl = null,Object? gitTagsUrl = null,Object? gitUrl = null,Object? issueCommentUrl = null,Object? id = null,Object? issuesUrl = null,Object? keysUrl = null,Object? labelsUrl = null,Object? languagesUrl = null,Object? mergesUrl = null,Object? milestonesUrl = null,Object? notificationsUrl = null,Object? pullsUrl = null,Object? releasesUrl = null,Object? sshUrl = null,Object? stargazersUrl = null,Object? statusesUrl = null,Object? subscribersUrl = null,Object? subscriptionUrl = null,Object? tagsUrl = null,Object? teamsUrl = null,Object? treesUrl = null,Object? cloneUrl = null,Object? mirrorUrl = freezed,Object? hooksUrl = null,Object? svnUrl = null,Object? homepage = freezed,Object? language = freezed,Object? forksCount = null,Object? stargazersCount = null,Object? watchersCount = null,Object? size = null,Object? defaultBranch = null,Object? openIssuesCount = null,Object? openIssues = null,Object? createdAt = freezed,Object? updatedAt = freezed,Object? pushedAt = freezed,Object? disabled = null,Object? hasPages = null,Object? hasWiki = null,Object? hasDownloads = null,Object? hasDiscussions = null,Object? hasPullRequests = null,Object? allowMergeCommit = null,Object? archived = null,Object? hasProjects = null,Object? visibility = null,Object? webCommitSignoffRequired = null,Object? isTemplate = null,Object? private = null,Object? allowRebaseMerge = null,Object? useSquashPrTitleAsDefault = null,Object? allowSquashMerge = null,Object? allowAutoMerge = null,Object? deleteBranchOnMerge = null,Object? allowUpdateBranch = null,Object? hasIssues = null,Object? squashMergeCommitTitle = freezed,Object? squashMergeCommitMessage = freezed,Object? mergeCommitTitle = freezed,Object? mergeCommitMessage = freezed,Object? pullRequestCreationPolicy = freezed,Object? allowForking = freezed,Object? codeSearchIndexStatus = freezed,Object? topics = freezed,Object? permissions = freezed,Object? masterBranch = freezed,Object? starredAt = freezed,Object? anonymousAccessEnabled = freezed,Object? tempCloneToken = freezed,}) {
  return _then(_self.copyWith(
issueEventsUrl: null == issueEventsUrl ? _self.issueEventsUrl : issueEventsUrl // ignore: cast_nullable_to_non_nullable
as String,nodeId: null == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,license: freezed == license ? _self.license : license // ignore: cast_nullable_to_non_nullable
as NullableLicenseSimple?,forks: null == forks ? _self.forks : forks // ignore: cast_nullable_to_non_nullable
as int,watchers: null == watchers ? _self.watchers : watchers // ignore: cast_nullable_to_non_nullable
as int,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as SimpleUser,htmlUrl: null == htmlUrl ? _self.htmlUrl : htmlUrl // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,fork: null == fork ? _self.fork : fork // ignore: cast_nullable_to_non_nullable
as bool,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,archiveUrl: null == archiveUrl ? _self.archiveUrl : archiveUrl // ignore: cast_nullable_to_non_nullable
as String,assigneesUrl: null == assigneesUrl ? _self.assigneesUrl : assigneesUrl // ignore: cast_nullable_to_non_nullable
as String,blobsUrl: null == blobsUrl ? _self.blobsUrl : blobsUrl // ignore: cast_nullable_to_non_nullable
as String,branchesUrl: null == branchesUrl ? _self.branchesUrl : branchesUrl // ignore: cast_nullable_to_non_nullable
as String,collaboratorsUrl: null == collaboratorsUrl ? _self.collaboratorsUrl : collaboratorsUrl // ignore: cast_nullable_to_non_nullable
as String,commentsUrl: null == commentsUrl ? _self.commentsUrl : commentsUrl // ignore: cast_nullable_to_non_nullable
as String,commitsUrl: null == commitsUrl ? _self.commitsUrl : commitsUrl // ignore: cast_nullable_to_non_nullable
as String,compareUrl: null == compareUrl ? _self.compareUrl : compareUrl // ignore: cast_nullable_to_non_nullable
as String,contentsUrl: null == contentsUrl ? _self.contentsUrl : contentsUrl // ignore: cast_nullable_to_non_nullable
as String,contributorsUrl: null == contributorsUrl ? _self.contributorsUrl : contributorsUrl // ignore: cast_nullable_to_non_nullable
as String,deploymentsUrl: null == deploymentsUrl ? _self.deploymentsUrl : deploymentsUrl // ignore: cast_nullable_to_non_nullable
as String,downloadsUrl: null == downloadsUrl ? _self.downloadsUrl : downloadsUrl // ignore: cast_nullable_to_non_nullable
as String,eventsUrl: null == eventsUrl ? _self.eventsUrl : eventsUrl // ignore: cast_nullable_to_non_nullable
as String,forksUrl: null == forksUrl ? _self.forksUrl : forksUrl // ignore: cast_nullable_to_non_nullable
as String,gitCommitsUrl: null == gitCommitsUrl ? _self.gitCommitsUrl : gitCommitsUrl // ignore: cast_nullable_to_non_nullable
as String,gitRefsUrl: null == gitRefsUrl ? _self.gitRefsUrl : gitRefsUrl // ignore: cast_nullable_to_non_nullable
as String,gitTagsUrl: null == gitTagsUrl ? _self.gitTagsUrl : gitTagsUrl // ignore: cast_nullable_to_non_nullable
as String,gitUrl: null == gitUrl ? _self.gitUrl : gitUrl // ignore: cast_nullable_to_non_nullable
as String,issueCommentUrl: null == issueCommentUrl ? _self.issueCommentUrl : issueCommentUrl // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,issuesUrl: null == issuesUrl ? _self.issuesUrl : issuesUrl // ignore: cast_nullable_to_non_nullable
as String,keysUrl: null == keysUrl ? _self.keysUrl : keysUrl // ignore: cast_nullable_to_non_nullable
as String,labelsUrl: null == labelsUrl ? _self.labelsUrl : labelsUrl // ignore: cast_nullable_to_non_nullable
as String,languagesUrl: null == languagesUrl ? _self.languagesUrl : languagesUrl // ignore: cast_nullable_to_non_nullable
as String,mergesUrl: null == mergesUrl ? _self.mergesUrl : mergesUrl // ignore: cast_nullable_to_non_nullable
as String,milestonesUrl: null == milestonesUrl ? _self.milestonesUrl : milestonesUrl // ignore: cast_nullable_to_non_nullable
as String,notificationsUrl: null == notificationsUrl ? _self.notificationsUrl : notificationsUrl // ignore: cast_nullable_to_non_nullable
as String,pullsUrl: null == pullsUrl ? _self.pullsUrl : pullsUrl // ignore: cast_nullable_to_non_nullable
as String,releasesUrl: null == releasesUrl ? _self.releasesUrl : releasesUrl // ignore: cast_nullable_to_non_nullable
as String,sshUrl: null == sshUrl ? _self.sshUrl : sshUrl // ignore: cast_nullable_to_non_nullable
as String,stargazersUrl: null == stargazersUrl ? _self.stargazersUrl : stargazersUrl // ignore: cast_nullable_to_non_nullable
as String,statusesUrl: null == statusesUrl ? _self.statusesUrl : statusesUrl // ignore: cast_nullable_to_non_nullable
as String,subscribersUrl: null == subscribersUrl ? _self.subscribersUrl : subscribersUrl // ignore: cast_nullable_to_non_nullable
as String,subscriptionUrl: null == subscriptionUrl ? _self.subscriptionUrl : subscriptionUrl // ignore: cast_nullable_to_non_nullable
as String,tagsUrl: null == tagsUrl ? _self.tagsUrl : tagsUrl // ignore: cast_nullable_to_non_nullable
as String,teamsUrl: null == teamsUrl ? _self.teamsUrl : teamsUrl // ignore: cast_nullable_to_non_nullable
as String,treesUrl: null == treesUrl ? _self.treesUrl : treesUrl // ignore: cast_nullable_to_non_nullable
as String,cloneUrl: null == cloneUrl ? _self.cloneUrl : cloneUrl // ignore: cast_nullable_to_non_nullable
as String,mirrorUrl: freezed == mirrorUrl ? _self.mirrorUrl : mirrorUrl // ignore: cast_nullable_to_non_nullable
as String?,hooksUrl: null == hooksUrl ? _self.hooksUrl : hooksUrl // ignore: cast_nullable_to_non_nullable
as String,svnUrl: null == svnUrl ? _self.svnUrl : svnUrl // ignore: cast_nullable_to_non_nullable
as String,homepage: freezed == homepage ? _self.homepage : homepage // ignore: cast_nullable_to_non_nullable
as String?,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,forksCount: null == forksCount ? _self.forksCount : forksCount // ignore: cast_nullable_to_non_nullable
as int,stargazersCount: null == stargazersCount ? _self.stargazersCount : stargazersCount // ignore: cast_nullable_to_non_nullable
as int,watchersCount: null == watchersCount ? _self.watchersCount : watchersCount // ignore: cast_nullable_to_non_nullable
as int,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,defaultBranch: null == defaultBranch ? _self.defaultBranch : defaultBranch // ignore: cast_nullable_to_non_nullable
as String,openIssuesCount: null == openIssuesCount ? _self.openIssuesCount : openIssuesCount // ignore: cast_nullable_to_non_nullable
as int,openIssues: null == openIssues ? _self.openIssues : openIssues // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,pushedAt: freezed == pushedAt ? _self.pushedAt : pushedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,disabled: null == disabled ? _self.disabled : disabled // ignore: cast_nullable_to_non_nullable
as bool,hasPages: null == hasPages ? _self.hasPages : hasPages // ignore: cast_nullable_to_non_nullable
as bool,hasWiki: null == hasWiki ? _self.hasWiki : hasWiki // ignore: cast_nullable_to_non_nullable
as bool,hasDownloads: null == hasDownloads ? _self.hasDownloads : hasDownloads // ignore: cast_nullable_to_non_nullable
as bool,hasDiscussions: null == hasDiscussions ? _self.hasDiscussions : hasDiscussions // ignore: cast_nullable_to_non_nullable
as bool,hasPullRequests: null == hasPullRequests ? _self.hasPullRequests : hasPullRequests // ignore: cast_nullable_to_non_nullable
as bool,allowMergeCommit: null == allowMergeCommit ? _self.allowMergeCommit : allowMergeCommit // ignore: cast_nullable_to_non_nullable
as bool,archived: null == archived ? _self.archived : archived // ignore: cast_nullable_to_non_nullable
as bool,hasProjects: null == hasProjects ? _self.hasProjects : hasProjects // ignore: cast_nullable_to_non_nullable
as bool,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as String,webCommitSignoffRequired: null == webCommitSignoffRequired ? _self.webCommitSignoffRequired : webCommitSignoffRequired // ignore: cast_nullable_to_non_nullable
as bool,isTemplate: null == isTemplate ? _self.isTemplate : isTemplate // ignore: cast_nullable_to_non_nullable
as bool,private: null == private ? _self.private : private // ignore: cast_nullable_to_non_nullable
as bool,allowRebaseMerge: null == allowRebaseMerge ? _self.allowRebaseMerge : allowRebaseMerge // ignore: cast_nullable_to_non_nullable
as bool,useSquashPrTitleAsDefault: null == useSquashPrTitleAsDefault ? _self.useSquashPrTitleAsDefault : useSquashPrTitleAsDefault // ignore: cast_nullable_to_non_nullable
as bool,allowSquashMerge: null == allowSquashMerge ? _self.allowSquashMerge : allowSquashMerge // ignore: cast_nullable_to_non_nullable
as bool,allowAutoMerge: null == allowAutoMerge ? _self.allowAutoMerge : allowAutoMerge // ignore: cast_nullable_to_non_nullable
as bool,deleteBranchOnMerge: null == deleteBranchOnMerge ? _self.deleteBranchOnMerge : deleteBranchOnMerge // ignore: cast_nullable_to_non_nullable
as bool,allowUpdateBranch: null == allowUpdateBranch ? _self.allowUpdateBranch : allowUpdateBranch // ignore: cast_nullable_to_non_nullable
as bool,hasIssues: null == hasIssues ? _self.hasIssues : hasIssues // ignore: cast_nullable_to_non_nullable
as bool,squashMergeCommitTitle: freezed == squashMergeCommitTitle ? _self.squashMergeCommitTitle : squashMergeCommitTitle // ignore: cast_nullable_to_non_nullable
as NullableRepositorySquashMergeCommitTitle?,squashMergeCommitMessage: freezed == squashMergeCommitMessage ? _self.squashMergeCommitMessage : squashMergeCommitMessage // ignore: cast_nullable_to_non_nullable
as NullableRepositorySquashMergeCommitMessage?,mergeCommitTitle: freezed == mergeCommitTitle ? _self.mergeCommitTitle : mergeCommitTitle // ignore: cast_nullable_to_non_nullable
as NullableRepositoryMergeCommitTitle?,mergeCommitMessage: freezed == mergeCommitMessage ? _self.mergeCommitMessage : mergeCommitMessage // ignore: cast_nullable_to_non_nullable
as NullableRepositoryMergeCommitMessage?,pullRequestCreationPolicy: freezed == pullRequestCreationPolicy ? _self.pullRequestCreationPolicy : pullRequestCreationPolicy // ignore: cast_nullable_to_non_nullable
as NullableRepositoryPullRequestCreationPolicy?,allowForking: freezed == allowForking ? _self.allowForking : allowForking // ignore: cast_nullable_to_non_nullable
as bool?,codeSearchIndexStatus: freezed == codeSearchIndexStatus ? _self.codeSearchIndexStatus : codeSearchIndexStatus // ignore: cast_nullable_to_non_nullable
as CodeSearchIndexStatus2?,topics: freezed == topics ? _self.topics : topics // ignore: cast_nullable_to_non_nullable
as List<String>?,permissions: freezed == permissions ? _self.permissions : permissions // ignore: cast_nullable_to_non_nullable
as Permissions10?,masterBranch: freezed == masterBranch ? _self.masterBranch : masterBranch // ignore: cast_nullable_to_non_nullable
as String?,starredAt: freezed == starredAt ? _self.starredAt : starredAt // ignore: cast_nullable_to_non_nullable
as String?,anonymousAccessEnabled: freezed == anonymousAccessEnabled ? _self.anonymousAccessEnabled : anonymousAccessEnabled // ignore: cast_nullable_to_non_nullable
as bool?,tempCloneToken: freezed == tempCloneToken ? _self.tempCloneToken : tempCloneToken // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of NullableRepository
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NullableLicenseSimpleCopyWith<$Res>? get license {
    if (_self.license == null) {
    return null;
  }

  return $NullableLicenseSimpleCopyWith<$Res>(_self.license!, (value) {
    return _then(_self.copyWith(license: value));
  });
}/// Create a copy of NullableRepository
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SimpleUserCopyWith<$Res> get owner {
  
  return $SimpleUserCopyWith<$Res>(_self.owner, (value) {
    return _then(_self.copyWith(owner: value));
  });
}/// Create a copy of NullableRepository
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CodeSearchIndexStatus2CopyWith<$Res>? get codeSearchIndexStatus {
    if (_self.codeSearchIndexStatus == null) {
    return null;
  }

  return $CodeSearchIndexStatus2CopyWith<$Res>(_self.codeSearchIndexStatus!, (value) {
    return _then(_self.copyWith(codeSearchIndexStatus: value));
  });
}/// Create a copy of NullableRepository
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Permissions10CopyWith<$Res>? get permissions {
    if (_self.permissions == null) {
    return null;
  }

  return $Permissions10CopyWith<$Res>(_self.permissions!, (value) {
    return _then(_self.copyWith(permissions: value));
  });
}
}


/// Adds pattern-matching-related methods to [NullableRepository].
extension NullableRepositoryPatterns on NullableRepository {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NullableRepository value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NullableRepository() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NullableRepository value)  $default,){
final _that = this;
switch (_that) {
case _NullableRepository():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NullableRepository value)?  $default,){
final _that = this;
switch (_that) {
case _NullableRepository() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'issue_events_url')  String issueEventsUrl, @JsonKey(name: 'node_id')  String nodeId,  String name, @JsonKey(name: 'full_name')  String fullName, @JsonKey(name: 'License')  NullableLicenseSimple? license,  int forks,  int watchers,  SimpleUser owner, @JsonKey(name: 'html_url')  String htmlUrl,  String? description,  bool fork,  String url, @JsonKey(name: 'archive_url')  String archiveUrl, @JsonKey(name: 'assignees_url')  String assigneesUrl, @JsonKey(name: 'blobs_url')  String blobsUrl, @JsonKey(name: 'branches_url')  String branchesUrl, @JsonKey(name: 'collaborators_url')  String collaboratorsUrl, @JsonKey(name: 'comments_url')  String commentsUrl, @JsonKey(name: 'commits_url')  String commitsUrl, @JsonKey(name: 'compare_url')  String compareUrl, @JsonKey(name: 'contents_url')  String contentsUrl, @JsonKey(name: 'contributors_url')  String contributorsUrl, @JsonKey(name: 'deployments_url')  String deploymentsUrl, @JsonKey(name: 'downloads_url')  String downloadsUrl, @JsonKey(name: 'events_url')  String eventsUrl, @JsonKey(name: 'forks_url')  String forksUrl, @JsonKey(name: 'git_commits_url')  String gitCommitsUrl, @JsonKey(name: 'git_refs_url')  String gitRefsUrl, @JsonKey(name: 'git_tags_url')  String gitTagsUrl, @JsonKey(name: 'git_url')  String gitUrl, @JsonKey(name: 'issue_comment_url')  String issueCommentUrl,  int id, @JsonKey(name: 'issues_url')  String issuesUrl, @JsonKey(name: 'keys_url')  String keysUrl, @JsonKey(name: 'labels_url')  String labelsUrl, @JsonKey(name: 'languages_url')  String languagesUrl, @JsonKey(name: 'merges_url')  String mergesUrl, @JsonKey(name: 'milestones_url')  String milestonesUrl, @JsonKey(name: 'notifications_url')  String notificationsUrl, @JsonKey(name: 'pulls_url')  String pullsUrl, @JsonKey(name: 'releases_url')  String releasesUrl, @JsonKey(name: 'ssh_url')  String sshUrl, @JsonKey(name: 'stargazers_url')  String stargazersUrl, @JsonKey(name: 'statuses_url')  String statusesUrl, @JsonKey(name: 'subscribers_url')  String subscribersUrl, @JsonKey(name: 'subscription_url')  String subscriptionUrl, @JsonKey(name: 'tags_url')  String tagsUrl, @JsonKey(name: 'teams_url')  String teamsUrl, @JsonKey(name: 'trees_url')  String treesUrl, @JsonKey(name: 'clone_url')  String cloneUrl, @JsonKey(name: 'mirror_url')  String? mirrorUrl, @JsonKey(name: 'hooks_url')  String hooksUrl, @JsonKey(name: 'svn_url')  String svnUrl,  String? homepage, @JsonKey(name: 'Language')  String? language, @JsonKey(name: 'forks_count')  int forksCount, @JsonKey(name: 'stargazers_count')  int stargazersCount, @JsonKey(name: 'watchers_count')  int watchersCount,  int size, @JsonKey(name: 'default_branch')  String defaultBranch, @JsonKey(name: 'open_issues_count')  int openIssuesCount, @JsonKey(name: 'open_issues')  int openIssues, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'pushed_at')  DateTime? pushedAt,  bool disabled, @JsonKey(name: 'has_pages')  bool hasPages, @JsonKey(name: 'has_wiki')  bool hasWiki, @JsonKey(name: 'has_downloads')@Deprecated('This is marked as deprecated')  bool hasDownloads, @JsonKey(name: 'has_discussions')  bool hasDiscussions, @JsonKey(name: 'has_pull_requests')  bool hasPullRequests, @JsonKey(name: 'allow_merge_commit')  bool allowMergeCommit,  bool archived, @JsonKey(name: 'has_projects')  bool hasProjects,  String visibility, @JsonKey(name: 'web_commit_signoff_required')  bool webCommitSignoffRequired, @JsonKey(name: 'is_template')  bool isTemplate,  bool private, @JsonKey(name: 'allow_rebase_merge')  bool allowRebaseMerge, @JsonKey(name: 'use_squash_pr_title_as_default')@Deprecated('This is marked as deprecated')  bool useSquashPrTitleAsDefault, @JsonKey(name: 'allow_squash_merge')  bool allowSquashMerge, @JsonKey(name: 'allow_auto_merge')  bool allowAutoMerge, @JsonKey(name: 'delete_branch_on_merge')  bool deleteBranchOnMerge, @JsonKey(name: 'allow_update_branch')  bool allowUpdateBranch, @JsonKey(name: 'has_issues')  bool hasIssues, @JsonKey(name: 'squash_merge_commit_title')  NullableRepositorySquashMergeCommitTitle? squashMergeCommitTitle, @JsonKey(name: 'squash_merge_commit_message')  NullableRepositorySquashMergeCommitMessage? squashMergeCommitMessage, @JsonKey(name: 'merge_commit_title')  NullableRepositoryMergeCommitTitle? mergeCommitTitle, @JsonKey(name: 'merge_commit_message')  NullableRepositoryMergeCommitMessage? mergeCommitMessage, @JsonKey(name: 'pull_request_creation_policy')  NullableRepositoryPullRequestCreationPolicy? pullRequestCreationPolicy, @JsonKey(name: 'allow_forking')  bool? allowForking, @JsonKey(name: 'code_search_index_status')  CodeSearchIndexStatus2? codeSearchIndexStatus,  List<String>? topics,  Permissions10? permissions, @JsonKey(name: 'master_branch')  String? masterBranch, @JsonKey(name: 'starred_at')  String? starredAt, @JsonKey(name: 'anonymous_access_enabled')  bool? anonymousAccessEnabled, @JsonKey(name: 'temp_clone_token')  String? tempCloneToken)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NullableRepository() when $default != null:
return $default(_that.issueEventsUrl,_that.nodeId,_that.name,_that.fullName,_that.license,_that.forks,_that.watchers,_that.owner,_that.htmlUrl,_that.description,_that.fork,_that.url,_that.archiveUrl,_that.assigneesUrl,_that.blobsUrl,_that.branchesUrl,_that.collaboratorsUrl,_that.commentsUrl,_that.commitsUrl,_that.compareUrl,_that.contentsUrl,_that.contributorsUrl,_that.deploymentsUrl,_that.downloadsUrl,_that.eventsUrl,_that.forksUrl,_that.gitCommitsUrl,_that.gitRefsUrl,_that.gitTagsUrl,_that.gitUrl,_that.issueCommentUrl,_that.id,_that.issuesUrl,_that.keysUrl,_that.labelsUrl,_that.languagesUrl,_that.mergesUrl,_that.milestonesUrl,_that.notificationsUrl,_that.pullsUrl,_that.releasesUrl,_that.sshUrl,_that.stargazersUrl,_that.statusesUrl,_that.subscribersUrl,_that.subscriptionUrl,_that.tagsUrl,_that.teamsUrl,_that.treesUrl,_that.cloneUrl,_that.mirrorUrl,_that.hooksUrl,_that.svnUrl,_that.homepage,_that.language,_that.forksCount,_that.stargazersCount,_that.watchersCount,_that.size,_that.defaultBranch,_that.openIssuesCount,_that.openIssues,_that.createdAt,_that.updatedAt,_that.pushedAt,_that.disabled,_that.hasPages,_that.hasWiki,_that.hasDownloads,_that.hasDiscussions,_that.hasPullRequests,_that.allowMergeCommit,_that.archived,_that.hasProjects,_that.visibility,_that.webCommitSignoffRequired,_that.isTemplate,_that.private,_that.allowRebaseMerge,_that.useSquashPrTitleAsDefault,_that.allowSquashMerge,_that.allowAutoMerge,_that.deleteBranchOnMerge,_that.allowUpdateBranch,_that.hasIssues,_that.squashMergeCommitTitle,_that.squashMergeCommitMessage,_that.mergeCommitTitle,_that.mergeCommitMessage,_that.pullRequestCreationPolicy,_that.allowForking,_that.codeSearchIndexStatus,_that.topics,_that.permissions,_that.masterBranch,_that.starredAt,_that.anonymousAccessEnabled,_that.tempCloneToken);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'issue_events_url')  String issueEventsUrl, @JsonKey(name: 'node_id')  String nodeId,  String name, @JsonKey(name: 'full_name')  String fullName, @JsonKey(name: 'License')  NullableLicenseSimple? license,  int forks,  int watchers,  SimpleUser owner, @JsonKey(name: 'html_url')  String htmlUrl,  String? description,  bool fork,  String url, @JsonKey(name: 'archive_url')  String archiveUrl, @JsonKey(name: 'assignees_url')  String assigneesUrl, @JsonKey(name: 'blobs_url')  String blobsUrl, @JsonKey(name: 'branches_url')  String branchesUrl, @JsonKey(name: 'collaborators_url')  String collaboratorsUrl, @JsonKey(name: 'comments_url')  String commentsUrl, @JsonKey(name: 'commits_url')  String commitsUrl, @JsonKey(name: 'compare_url')  String compareUrl, @JsonKey(name: 'contents_url')  String contentsUrl, @JsonKey(name: 'contributors_url')  String contributorsUrl, @JsonKey(name: 'deployments_url')  String deploymentsUrl, @JsonKey(name: 'downloads_url')  String downloadsUrl, @JsonKey(name: 'events_url')  String eventsUrl, @JsonKey(name: 'forks_url')  String forksUrl, @JsonKey(name: 'git_commits_url')  String gitCommitsUrl, @JsonKey(name: 'git_refs_url')  String gitRefsUrl, @JsonKey(name: 'git_tags_url')  String gitTagsUrl, @JsonKey(name: 'git_url')  String gitUrl, @JsonKey(name: 'issue_comment_url')  String issueCommentUrl,  int id, @JsonKey(name: 'issues_url')  String issuesUrl, @JsonKey(name: 'keys_url')  String keysUrl, @JsonKey(name: 'labels_url')  String labelsUrl, @JsonKey(name: 'languages_url')  String languagesUrl, @JsonKey(name: 'merges_url')  String mergesUrl, @JsonKey(name: 'milestones_url')  String milestonesUrl, @JsonKey(name: 'notifications_url')  String notificationsUrl, @JsonKey(name: 'pulls_url')  String pullsUrl, @JsonKey(name: 'releases_url')  String releasesUrl, @JsonKey(name: 'ssh_url')  String sshUrl, @JsonKey(name: 'stargazers_url')  String stargazersUrl, @JsonKey(name: 'statuses_url')  String statusesUrl, @JsonKey(name: 'subscribers_url')  String subscribersUrl, @JsonKey(name: 'subscription_url')  String subscriptionUrl, @JsonKey(name: 'tags_url')  String tagsUrl, @JsonKey(name: 'teams_url')  String teamsUrl, @JsonKey(name: 'trees_url')  String treesUrl, @JsonKey(name: 'clone_url')  String cloneUrl, @JsonKey(name: 'mirror_url')  String? mirrorUrl, @JsonKey(name: 'hooks_url')  String hooksUrl, @JsonKey(name: 'svn_url')  String svnUrl,  String? homepage, @JsonKey(name: 'Language')  String? language, @JsonKey(name: 'forks_count')  int forksCount, @JsonKey(name: 'stargazers_count')  int stargazersCount, @JsonKey(name: 'watchers_count')  int watchersCount,  int size, @JsonKey(name: 'default_branch')  String defaultBranch, @JsonKey(name: 'open_issues_count')  int openIssuesCount, @JsonKey(name: 'open_issues')  int openIssues, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'pushed_at')  DateTime? pushedAt,  bool disabled, @JsonKey(name: 'has_pages')  bool hasPages, @JsonKey(name: 'has_wiki')  bool hasWiki, @JsonKey(name: 'has_downloads')@Deprecated('This is marked as deprecated')  bool hasDownloads, @JsonKey(name: 'has_discussions')  bool hasDiscussions, @JsonKey(name: 'has_pull_requests')  bool hasPullRequests, @JsonKey(name: 'allow_merge_commit')  bool allowMergeCommit,  bool archived, @JsonKey(name: 'has_projects')  bool hasProjects,  String visibility, @JsonKey(name: 'web_commit_signoff_required')  bool webCommitSignoffRequired, @JsonKey(name: 'is_template')  bool isTemplate,  bool private, @JsonKey(name: 'allow_rebase_merge')  bool allowRebaseMerge, @JsonKey(name: 'use_squash_pr_title_as_default')@Deprecated('This is marked as deprecated')  bool useSquashPrTitleAsDefault, @JsonKey(name: 'allow_squash_merge')  bool allowSquashMerge, @JsonKey(name: 'allow_auto_merge')  bool allowAutoMerge, @JsonKey(name: 'delete_branch_on_merge')  bool deleteBranchOnMerge, @JsonKey(name: 'allow_update_branch')  bool allowUpdateBranch, @JsonKey(name: 'has_issues')  bool hasIssues, @JsonKey(name: 'squash_merge_commit_title')  NullableRepositorySquashMergeCommitTitle? squashMergeCommitTitle, @JsonKey(name: 'squash_merge_commit_message')  NullableRepositorySquashMergeCommitMessage? squashMergeCommitMessage, @JsonKey(name: 'merge_commit_title')  NullableRepositoryMergeCommitTitle? mergeCommitTitle, @JsonKey(name: 'merge_commit_message')  NullableRepositoryMergeCommitMessage? mergeCommitMessage, @JsonKey(name: 'pull_request_creation_policy')  NullableRepositoryPullRequestCreationPolicy? pullRequestCreationPolicy, @JsonKey(name: 'allow_forking')  bool? allowForking, @JsonKey(name: 'code_search_index_status')  CodeSearchIndexStatus2? codeSearchIndexStatus,  List<String>? topics,  Permissions10? permissions, @JsonKey(name: 'master_branch')  String? masterBranch, @JsonKey(name: 'starred_at')  String? starredAt, @JsonKey(name: 'anonymous_access_enabled')  bool? anonymousAccessEnabled, @JsonKey(name: 'temp_clone_token')  String? tempCloneToken)  $default,) {final _that = this;
switch (_that) {
case _NullableRepository():
return $default(_that.issueEventsUrl,_that.nodeId,_that.name,_that.fullName,_that.license,_that.forks,_that.watchers,_that.owner,_that.htmlUrl,_that.description,_that.fork,_that.url,_that.archiveUrl,_that.assigneesUrl,_that.blobsUrl,_that.branchesUrl,_that.collaboratorsUrl,_that.commentsUrl,_that.commitsUrl,_that.compareUrl,_that.contentsUrl,_that.contributorsUrl,_that.deploymentsUrl,_that.downloadsUrl,_that.eventsUrl,_that.forksUrl,_that.gitCommitsUrl,_that.gitRefsUrl,_that.gitTagsUrl,_that.gitUrl,_that.issueCommentUrl,_that.id,_that.issuesUrl,_that.keysUrl,_that.labelsUrl,_that.languagesUrl,_that.mergesUrl,_that.milestonesUrl,_that.notificationsUrl,_that.pullsUrl,_that.releasesUrl,_that.sshUrl,_that.stargazersUrl,_that.statusesUrl,_that.subscribersUrl,_that.subscriptionUrl,_that.tagsUrl,_that.teamsUrl,_that.treesUrl,_that.cloneUrl,_that.mirrorUrl,_that.hooksUrl,_that.svnUrl,_that.homepage,_that.language,_that.forksCount,_that.stargazersCount,_that.watchersCount,_that.size,_that.defaultBranch,_that.openIssuesCount,_that.openIssues,_that.createdAt,_that.updatedAt,_that.pushedAt,_that.disabled,_that.hasPages,_that.hasWiki,_that.hasDownloads,_that.hasDiscussions,_that.hasPullRequests,_that.allowMergeCommit,_that.archived,_that.hasProjects,_that.visibility,_that.webCommitSignoffRequired,_that.isTemplate,_that.private,_that.allowRebaseMerge,_that.useSquashPrTitleAsDefault,_that.allowSquashMerge,_that.allowAutoMerge,_that.deleteBranchOnMerge,_that.allowUpdateBranch,_that.hasIssues,_that.squashMergeCommitTitle,_that.squashMergeCommitMessage,_that.mergeCommitTitle,_that.mergeCommitMessage,_that.pullRequestCreationPolicy,_that.allowForking,_that.codeSearchIndexStatus,_that.topics,_that.permissions,_that.masterBranch,_that.starredAt,_that.anonymousAccessEnabled,_that.tempCloneToken);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'issue_events_url')  String issueEventsUrl, @JsonKey(name: 'node_id')  String nodeId,  String name, @JsonKey(name: 'full_name')  String fullName, @JsonKey(name: 'License')  NullableLicenseSimple? license,  int forks,  int watchers,  SimpleUser owner, @JsonKey(name: 'html_url')  String htmlUrl,  String? description,  bool fork,  String url, @JsonKey(name: 'archive_url')  String archiveUrl, @JsonKey(name: 'assignees_url')  String assigneesUrl, @JsonKey(name: 'blobs_url')  String blobsUrl, @JsonKey(name: 'branches_url')  String branchesUrl, @JsonKey(name: 'collaborators_url')  String collaboratorsUrl, @JsonKey(name: 'comments_url')  String commentsUrl, @JsonKey(name: 'commits_url')  String commitsUrl, @JsonKey(name: 'compare_url')  String compareUrl, @JsonKey(name: 'contents_url')  String contentsUrl, @JsonKey(name: 'contributors_url')  String contributorsUrl, @JsonKey(name: 'deployments_url')  String deploymentsUrl, @JsonKey(name: 'downloads_url')  String downloadsUrl, @JsonKey(name: 'events_url')  String eventsUrl, @JsonKey(name: 'forks_url')  String forksUrl, @JsonKey(name: 'git_commits_url')  String gitCommitsUrl, @JsonKey(name: 'git_refs_url')  String gitRefsUrl, @JsonKey(name: 'git_tags_url')  String gitTagsUrl, @JsonKey(name: 'git_url')  String gitUrl, @JsonKey(name: 'issue_comment_url')  String issueCommentUrl,  int id, @JsonKey(name: 'issues_url')  String issuesUrl, @JsonKey(name: 'keys_url')  String keysUrl, @JsonKey(name: 'labels_url')  String labelsUrl, @JsonKey(name: 'languages_url')  String languagesUrl, @JsonKey(name: 'merges_url')  String mergesUrl, @JsonKey(name: 'milestones_url')  String milestonesUrl, @JsonKey(name: 'notifications_url')  String notificationsUrl, @JsonKey(name: 'pulls_url')  String pullsUrl, @JsonKey(name: 'releases_url')  String releasesUrl, @JsonKey(name: 'ssh_url')  String sshUrl, @JsonKey(name: 'stargazers_url')  String stargazersUrl, @JsonKey(name: 'statuses_url')  String statusesUrl, @JsonKey(name: 'subscribers_url')  String subscribersUrl, @JsonKey(name: 'subscription_url')  String subscriptionUrl, @JsonKey(name: 'tags_url')  String tagsUrl, @JsonKey(name: 'teams_url')  String teamsUrl, @JsonKey(name: 'trees_url')  String treesUrl, @JsonKey(name: 'clone_url')  String cloneUrl, @JsonKey(name: 'mirror_url')  String? mirrorUrl, @JsonKey(name: 'hooks_url')  String hooksUrl, @JsonKey(name: 'svn_url')  String svnUrl,  String? homepage, @JsonKey(name: 'Language')  String? language, @JsonKey(name: 'forks_count')  int forksCount, @JsonKey(name: 'stargazers_count')  int stargazersCount, @JsonKey(name: 'watchers_count')  int watchersCount,  int size, @JsonKey(name: 'default_branch')  String defaultBranch, @JsonKey(name: 'open_issues_count')  int openIssuesCount, @JsonKey(name: 'open_issues')  int openIssues, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt, @JsonKey(name: 'pushed_at')  DateTime? pushedAt,  bool disabled, @JsonKey(name: 'has_pages')  bool hasPages, @JsonKey(name: 'has_wiki')  bool hasWiki, @JsonKey(name: 'has_downloads')@Deprecated('This is marked as deprecated')  bool hasDownloads, @JsonKey(name: 'has_discussions')  bool hasDiscussions, @JsonKey(name: 'has_pull_requests')  bool hasPullRequests, @JsonKey(name: 'allow_merge_commit')  bool allowMergeCommit,  bool archived, @JsonKey(name: 'has_projects')  bool hasProjects,  String visibility, @JsonKey(name: 'web_commit_signoff_required')  bool webCommitSignoffRequired, @JsonKey(name: 'is_template')  bool isTemplate,  bool private, @JsonKey(name: 'allow_rebase_merge')  bool allowRebaseMerge, @JsonKey(name: 'use_squash_pr_title_as_default')@Deprecated('This is marked as deprecated')  bool useSquashPrTitleAsDefault, @JsonKey(name: 'allow_squash_merge')  bool allowSquashMerge, @JsonKey(name: 'allow_auto_merge')  bool allowAutoMerge, @JsonKey(name: 'delete_branch_on_merge')  bool deleteBranchOnMerge, @JsonKey(name: 'allow_update_branch')  bool allowUpdateBranch, @JsonKey(name: 'has_issues')  bool hasIssues, @JsonKey(name: 'squash_merge_commit_title')  NullableRepositorySquashMergeCommitTitle? squashMergeCommitTitle, @JsonKey(name: 'squash_merge_commit_message')  NullableRepositorySquashMergeCommitMessage? squashMergeCommitMessage, @JsonKey(name: 'merge_commit_title')  NullableRepositoryMergeCommitTitle? mergeCommitTitle, @JsonKey(name: 'merge_commit_message')  NullableRepositoryMergeCommitMessage? mergeCommitMessage, @JsonKey(name: 'pull_request_creation_policy')  NullableRepositoryPullRequestCreationPolicy? pullRequestCreationPolicy, @JsonKey(name: 'allow_forking')  bool? allowForking, @JsonKey(name: 'code_search_index_status')  CodeSearchIndexStatus2? codeSearchIndexStatus,  List<String>? topics,  Permissions10? permissions, @JsonKey(name: 'master_branch')  String? masterBranch, @JsonKey(name: 'starred_at')  String? starredAt, @JsonKey(name: 'anonymous_access_enabled')  bool? anonymousAccessEnabled, @JsonKey(name: 'temp_clone_token')  String? tempCloneToken)?  $default,) {final _that = this;
switch (_that) {
case _NullableRepository() when $default != null:
return $default(_that.issueEventsUrl,_that.nodeId,_that.name,_that.fullName,_that.license,_that.forks,_that.watchers,_that.owner,_that.htmlUrl,_that.description,_that.fork,_that.url,_that.archiveUrl,_that.assigneesUrl,_that.blobsUrl,_that.branchesUrl,_that.collaboratorsUrl,_that.commentsUrl,_that.commitsUrl,_that.compareUrl,_that.contentsUrl,_that.contributorsUrl,_that.deploymentsUrl,_that.downloadsUrl,_that.eventsUrl,_that.forksUrl,_that.gitCommitsUrl,_that.gitRefsUrl,_that.gitTagsUrl,_that.gitUrl,_that.issueCommentUrl,_that.id,_that.issuesUrl,_that.keysUrl,_that.labelsUrl,_that.languagesUrl,_that.mergesUrl,_that.milestonesUrl,_that.notificationsUrl,_that.pullsUrl,_that.releasesUrl,_that.sshUrl,_that.stargazersUrl,_that.statusesUrl,_that.subscribersUrl,_that.subscriptionUrl,_that.tagsUrl,_that.teamsUrl,_that.treesUrl,_that.cloneUrl,_that.mirrorUrl,_that.hooksUrl,_that.svnUrl,_that.homepage,_that.language,_that.forksCount,_that.stargazersCount,_that.watchersCount,_that.size,_that.defaultBranch,_that.openIssuesCount,_that.openIssues,_that.createdAt,_that.updatedAt,_that.pushedAt,_that.disabled,_that.hasPages,_that.hasWiki,_that.hasDownloads,_that.hasDiscussions,_that.hasPullRequests,_that.allowMergeCommit,_that.archived,_that.hasProjects,_that.visibility,_that.webCommitSignoffRequired,_that.isTemplate,_that.private,_that.allowRebaseMerge,_that.useSquashPrTitleAsDefault,_that.allowSquashMerge,_that.allowAutoMerge,_that.deleteBranchOnMerge,_that.allowUpdateBranch,_that.hasIssues,_that.squashMergeCommitTitle,_that.squashMergeCommitMessage,_that.mergeCommitTitle,_that.mergeCommitMessage,_that.pullRequestCreationPolicy,_that.allowForking,_that.codeSearchIndexStatus,_that.topics,_that.permissions,_that.masterBranch,_that.starredAt,_that.anonymousAccessEnabled,_that.tempCloneToken);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NullableRepository implements NullableRepository {
  const _NullableRepository({@JsonKey(name: 'issue_events_url') required this.issueEventsUrl, @JsonKey(name: 'node_id') required this.nodeId, required this.name, @JsonKey(name: 'full_name') required this.fullName, @JsonKey(name: 'License') required this.license, required this.forks, required this.watchers, required this.owner, @JsonKey(name: 'html_url') required this.htmlUrl, required this.description, required this.fork, required this.url, @JsonKey(name: 'archive_url') required this.archiveUrl, @JsonKey(name: 'assignees_url') required this.assigneesUrl, @JsonKey(name: 'blobs_url') required this.blobsUrl, @JsonKey(name: 'branches_url') required this.branchesUrl, @JsonKey(name: 'collaborators_url') required this.collaboratorsUrl, @JsonKey(name: 'comments_url') required this.commentsUrl, @JsonKey(name: 'commits_url') required this.commitsUrl, @JsonKey(name: 'compare_url') required this.compareUrl, @JsonKey(name: 'contents_url') required this.contentsUrl, @JsonKey(name: 'contributors_url') required this.contributorsUrl, @JsonKey(name: 'deployments_url') required this.deploymentsUrl, @JsonKey(name: 'downloads_url') required this.downloadsUrl, @JsonKey(name: 'events_url') required this.eventsUrl, @JsonKey(name: 'forks_url') required this.forksUrl, @JsonKey(name: 'git_commits_url') required this.gitCommitsUrl, @JsonKey(name: 'git_refs_url') required this.gitRefsUrl, @JsonKey(name: 'git_tags_url') required this.gitTagsUrl, @JsonKey(name: 'git_url') required this.gitUrl, @JsonKey(name: 'issue_comment_url') required this.issueCommentUrl, required this.id, @JsonKey(name: 'issues_url') required this.issuesUrl, @JsonKey(name: 'keys_url') required this.keysUrl, @JsonKey(name: 'labels_url') required this.labelsUrl, @JsonKey(name: 'languages_url') required this.languagesUrl, @JsonKey(name: 'merges_url') required this.mergesUrl, @JsonKey(name: 'milestones_url') required this.milestonesUrl, @JsonKey(name: 'notifications_url') required this.notificationsUrl, @JsonKey(name: 'pulls_url') required this.pullsUrl, @JsonKey(name: 'releases_url') required this.releasesUrl, @JsonKey(name: 'ssh_url') required this.sshUrl, @JsonKey(name: 'stargazers_url') required this.stargazersUrl, @JsonKey(name: 'statuses_url') required this.statusesUrl, @JsonKey(name: 'subscribers_url') required this.subscribersUrl, @JsonKey(name: 'subscription_url') required this.subscriptionUrl, @JsonKey(name: 'tags_url') required this.tagsUrl, @JsonKey(name: 'teams_url') required this.teamsUrl, @JsonKey(name: 'trees_url') required this.treesUrl, @JsonKey(name: 'clone_url') required this.cloneUrl, @JsonKey(name: 'mirror_url') required this.mirrorUrl, @JsonKey(name: 'hooks_url') required this.hooksUrl, @JsonKey(name: 'svn_url') required this.svnUrl, required this.homepage, @JsonKey(name: 'Language') required this.language, @JsonKey(name: 'forks_count') required this.forksCount, @JsonKey(name: 'stargazers_count') required this.stargazersCount, @JsonKey(name: 'watchers_count') required this.watchersCount, required this.size, @JsonKey(name: 'default_branch') required this.defaultBranch, @JsonKey(name: 'open_issues_count') required this.openIssuesCount, @JsonKey(name: 'open_issues') required this.openIssues, @JsonKey(name: 'created_at') required this.createdAt, @JsonKey(name: 'updated_at') required this.updatedAt, @JsonKey(name: 'pushed_at') required this.pushedAt, required this.disabled, @JsonKey(name: 'has_pages') required this.hasPages, @JsonKey(name: 'has_wiki') this.hasWiki = true, @JsonKey(name: 'has_downloads')@Deprecated('This is marked as deprecated') this.hasDownloads = true, @JsonKey(name: 'has_discussions') this.hasDiscussions = false, @JsonKey(name: 'has_pull_requests') this.hasPullRequests = true, @JsonKey(name: 'allow_merge_commit') this.allowMergeCommit = true, this.archived = false, @JsonKey(name: 'has_projects') this.hasProjects = true, this.visibility = 'public', @JsonKey(name: 'web_commit_signoff_required') this.webCommitSignoffRequired = false, @JsonKey(name: 'is_template') this.isTemplate = false, this.private = false, @JsonKey(name: 'allow_rebase_merge') this.allowRebaseMerge = true, @JsonKey(name: 'use_squash_pr_title_as_default')@Deprecated('This is marked as deprecated') this.useSquashPrTitleAsDefault = false, @JsonKey(name: 'allow_squash_merge') this.allowSquashMerge = true, @JsonKey(name: 'allow_auto_merge') this.allowAutoMerge = false, @JsonKey(name: 'delete_branch_on_merge') this.deleteBranchOnMerge = false, @JsonKey(name: 'allow_update_branch') this.allowUpdateBranch = false, @JsonKey(name: 'has_issues') this.hasIssues = true, @JsonKey(name: 'squash_merge_commit_title') this.squashMergeCommitTitle, @JsonKey(name: 'squash_merge_commit_message') this.squashMergeCommitMessage, @JsonKey(name: 'merge_commit_title') this.mergeCommitTitle, @JsonKey(name: 'merge_commit_message') this.mergeCommitMessage, @JsonKey(name: 'pull_request_creation_policy') this.pullRequestCreationPolicy, @JsonKey(name: 'allow_forking') this.allowForking, @JsonKey(name: 'code_search_index_status') this.codeSearchIndexStatus, final  List<String>? topics, this.permissions, @JsonKey(name: 'master_branch') this.masterBranch, @JsonKey(name: 'starred_at') this.starredAt, @JsonKey(name: 'anonymous_access_enabled') this.anonymousAccessEnabled, @JsonKey(name: 'temp_clone_token') this.tempCloneToken}): _topics = topics;
  factory _NullableRepository.fromJson(Map<String, dynamic> json) => _$NullableRepositoryFromJson(json);

@override@JsonKey(name: 'issue_events_url') final  String issueEventsUrl;
@override@JsonKey(name: 'node_id') final  String nodeId;
/// The name of the repository.
@override final  String name;
@override@JsonKey(name: 'full_name') final  String fullName;
@override@JsonKey(name: 'License') final  NullableLicenseSimple? license;
@override final  int forks;
@override final  int watchers;
@override final  SimpleUser owner;
@override@JsonKey(name: 'html_url') final  String htmlUrl;
@override final  String? description;
@override final  bool fork;
@override final  String url;
@override@JsonKey(name: 'archive_url') final  String archiveUrl;
@override@JsonKey(name: 'assignees_url') final  String assigneesUrl;
@override@JsonKey(name: 'blobs_url') final  String blobsUrl;
@override@JsonKey(name: 'branches_url') final  String branchesUrl;
@override@JsonKey(name: 'collaborators_url') final  String collaboratorsUrl;
@override@JsonKey(name: 'comments_url') final  String commentsUrl;
@override@JsonKey(name: 'commits_url') final  String commitsUrl;
@override@JsonKey(name: 'compare_url') final  String compareUrl;
@override@JsonKey(name: 'contents_url') final  String contentsUrl;
@override@JsonKey(name: 'contributors_url') final  String contributorsUrl;
@override@JsonKey(name: 'deployments_url') final  String deploymentsUrl;
@override@JsonKey(name: 'downloads_url') final  String downloadsUrl;
@override@JsonKey(name: 'events_url') final  String eventsUrl;
@override@JsonKey(name: 'forks_url') final  String forksUrl;
@override@JsonKey(name: 'git_commits_url') final  String gitCommitsUrl;
@override@JsonKey(name: 'git_refs_url') final  String gitRefsUrl;
@override@JsonKey(name: 'git_tags_url') final  String gitTagsUrl;
@override@JsonKey(name: 'git_url') final  String gitUrl;
@override@JsonKey(name: 'issue_comment_url') final  String issueCommentUrl;
/// Unique identifier of the Repository
@override final  int id;
@override@JsonKey(name: 'issues_url') final  String issuesUrl;
@override@JsonKey(name: 'keys_url') final  String keysUrl;
@override@JsonKey(name: 'labels_url') final  String labelsUrl;
@override@JsonKey(name: 'languages_url') final  String languagesUrl;
@override@JsonKey(name: 'merges_url') final  String mergesUrl;
@override@JsonKey(name: 'milestones_url') final  String milestonesUrl;
@override@JsonKey(name: 'notifications_url') final  String notificationsUrl;
@override@JsonKey(name: 'pulls_url') final  String pullsUrl;
@override@JsonKey(name: 'releases_url') final  String releasesUrl;
@override@JsonKey(name: 'ssh_url') final  String sshUrl;
@override@JsonKey(name: 'stargazers_url') final  String stargazersUrl;
@override@JsonKey(name: 'statuses_url') final  String statusesUrl;
@override@JsonKey(name: 'subscribers_url') final  String subscribersUrl;
@override@JsonKey(name: 'subscription_url') final  String subscriptionUrl;
@override@JsonKey(name: 'tags_url') final  String tagsUrl;
@override@JsonKey(name: 'teams_url') final  String teamsUrl;
@override@JsonKey(name: 'trees_url') final  String treesUrl;
@override@JsonKey(name: 'clone_url') final  String cloneUrl;
@override@JsonKey(name: 'mirror_url') final  String? mirrorUrl;
@override@JsonKey(name: 'hooks_url') final  String hooksUrl;
@override@JsonKey(name: 'svn_url') final  String svnUrl;
@override final  String? homepage;
@override@JsonKey(name: 'Language') final  String? language;
@override@JsonKey(name: 'forks_count') final  int forksCount;
@override@JsonKey(name: 'stargazers_count') final  int stargazersCount;
@override@JsonKey(name: 'watchers_count') final  int watchersCount;
/// The size of the repository, in kilobytes. Size is calculated hourly. When a Repository is initially created, the size is 0.
@override final  int size;
/// The default branch of the repository.
@override@JsonKey(name: 'default_branch') final  String defaultBranch;
@override@JsonKey(name: 'open_issues_count') final  int openIssuesCount;
@override@JsonKey(name: 'open_issues') final  int openIssues;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;
@override@JsonKey(name: 'pushed_at') final  DateTime? pushedAt;
/// Returns whether or not this Repository disabled.
@override final  bool disabled;
@override@JsonKey(name: 'has_pages') final  bool hasPages;
/// Whether the wiki is enabled.
@override@JsonKey(name: 'has_wiki') final  bool hasWiki;
/// Whether downloads are enabled.
@override@JsonKey(name: 'has_downloads')@Deprecated('This is marked as deprecated') final  bool hasDownloads;
/// Whether discussions are enabled.
@override@JsonKey(name: 'has_discussions') final  bool hasDiscussions;
/// Whether pull requests are enabled.
@override@JsonKey(name: 'has_pull_requests') final  bool hasPullRequests;
/// Whether to allow merge commits for pull requests.
@override@JsonKey(name: 'allow_merge_commit') final  bool allowMergeCommit;
/// Whether the Repository is archived.
@override@JsonKey() final  bool archived;
/// Whether projects are enabled.
@override@JsonKey(name: 'has_projects') final  bool hasProjects;
/// The Repository visibility: public, private, or internal.
@override@JsonKey() final  String visibility;
/// Whether to require contributors to sign off on web-based commits
@override@JsonKey(name: 'web_commit_signoff_required') final  bool webCommitSignoffRequired;
/// Whether this Repository acts as a template that can be used to generate new repositories.
@override@JsonKey(name: 'is_template') final  bool isTemplate;
/// Whether the Repository is private or public.
@override@JsonKey() final  bool private;
/// Whether to allow rebase merges for pull requests.
@override@JsonKey(name: 'allow_rebase_merge') final  bool allowRebaseMerge;
/// Whether a squash merge Commit can use the pull request title as default. **This property is closing down. Please use `squash_merge_commit_title` instead.
@override@JsonKey(name: 'use_squash_pr_title_as_default')@Deprecated('This is marked as deprecated') final  bool useSquashPrTitleAsDefault;
/// Whether to allow squash merges for pull requests.
@override@JsonKey(name: 'allow_squash_merge') final  bool allowSquashMerge;
/// Whether to allow Auto-merge to be used on pull requests.
@override@JsonKey(name: 'allow_auto_merge') final  bool allowAutoMerge;
/// Whether to delete head branches when pull requests are merged
@override@JsonKey(name: 'delete_branch_on_merge') final  bool deleteBranchOnMerge;
/// Whether or not a pull request head branch that is behind its base branch can always be updated even if it is not required to be up to date before merging.
@override@JsonKey(name: 'allow_update_branch') final  bool allowUpdateBranch;
/// Whether issues are enabled.
@override@JsonKey(name: 'has_issues') final  bool hasIssues;
/// The default value for a squash merge Commit title:.
///
/// - `PR_TITLE` - default to the pull request's title.
/// - `COMMIT_OR_PR_TITLE` - default to the Commit's title (if only one commit) or the pull request's title (when more than one commit).
@override@JsonKey(name: 'squash_merge_commit_title') final  NullableRepositorySquashMergeCommitTitle? squashMergeCommitTitle;
/// The default value for a squash merge Commit message:.
///
/// - `PR_BODY` - default to the pull request's body.
/// - `COMMIT_MESSAGES` - default to the branch's Commit messages.
/// - `BLANK` - default to a blank Commit message.
@override@JsonKey(name: 'squash_merge_commit_message') final  NullableRepositorySquashMergeCommitMessage? squashMergeCommitMessage;
/// The default value for a merge Commit title.
///
/// - `PR_TITLE` - default to the pull request's title.
/// - `MERGE_MESSAGE` - default to the classic title for a merge message (e.g., Merge pull request #123 from branch-name).
@override@JsonKey(name: 'merge_commit_title') final  NullableRepositoryMergeCommitTitle? mergeCommitTitle;
/// The default value for a merge Commit message.
///
/// - `PR_TITLE` - default to the pull request's title.
/// - `PR_BODY` - default to the pull request's body.
/// - `BLANK` - default to a blank Commit message.
@override@JsonKey(name: 'merge_commit_message') final  NullableRepositoryMergeCommitMessage? mergeCommitMessage;
/// The policy controlling who can create pull requests: all or collaborators_only.
@override@JsonKey(name: 'pull_request_creation_policy') final  NullableRepositoryPullRequestCreationPolicy? pullRequestCreationPolicy;
/// Whether to allow forking this repo
@override@JsonKey(name: 'allow_forking') final  bool? allowForking;
/// The Status of the code search index for this Repository
@override@JsonKey(name: 'code_search_index_status') final  CodeSearchIndexStatus2? codeSearchIndexStatus;
 final  List<String>? _topics;
@override List<String>? get topics {
  final value = _topics;
  if (value == null) return null;
  if (_topics is EqualUnmodifiableListView) return _topics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  Permissions10? permissions;
@override@JsonKey(name: 'master_branch') final  String? masterBranch;
@override@JsonKey(name: 'starred_at') final  String? starredAt;
/// Whether anonymous git access is enabled for this Repository
@override@JsonKey(name: 'anonymous_access_enabled') final  bool? anonymousAccessEnabled;
@override@JsonKey(name: 'temp_clone_token') final  String? tempCloneToken;

/// Create a copy of NullableRepository
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NullableRepositoryCopyWith<_NullableRepository> get copyWith => __$NullableRepositoryCopyWithImpl<_NullableRepository>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NullableRepositoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NullableRepository&&(identical(other.issueEventsUrl, issueEventsUrl) || other.issueEventsUrl == issueEventsUrl)&&(identical(other.nodeId, nodeId) || other.nodeId == nodeId)&&(identical(other.name, name) || other.name == name)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.license, license) || other.license == license)&&(identical(other.forks, forks) || other.forks == forks)&&(identical(other.watchers, watchers) || other.watchers == watchers)&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.htmlUrl, htmlUrl) || other.htmlUrl == htmlUrl)&&(identical(other.description, description) || other.description == description)&&(identical(other.fork, fork) || other.fork == fork)&&(identical(other.url, url) || other.url == url)&&(identical(other.archiveUrl, archiveUrl) || other.archiveUrl == archiveUrl)&&(identical(other.assigneesUrl, assigneesUrl) || other.assigneesUrl == assigneesUrl)&&(identical(other.blobsUrl, blobsUrl) || other.blobsUrl == blobsUrl)&&(identical(other.branchesUrl, branchesUrl) || other.branchesUrl == branchesUrl)&&(identical(other.collaboratorsUrl, collaboratorsUrl) || other.collaboratorsUrl == collaboratorsUrl)&&(identical(other.commentsUrl, commentsUrl) || other.commentsUrl == commentsUrl)&&(identical(other.commitsUrl, commitsUrl) || other.commitsUrl == commitsUrl)&&(identical(other.compareUrl, compareUrl) || other.compareUrl == compareUrl)&&(identical(other.contentsUrl, contentsUrl) || other.contentsUrl == contentsUrl)&&(identical(other.contributorsUrl, contributorsUrl) || other.contributorsUrl == contributorsUrl)&&(identical(other.deploymentsUrl, deploymentsUrl) || other.deploymentsUrl == deploymentsUrl)&&(identical(other.downloadsUrl, downloadsUrl) || other.downloadsUrl == downloadsUrl)&&(identical(other.eventsUrl, eventsUrl) || other.eventsUrl == eventsUrl)&&(identical(other.forksUrl, forksUrl) || other.forksUrl == forksUrl)&&(identical(other.gitCommitsUrl, gitCommitsUrl) || other.gitCommitsUrl == gitCommitsUrl)&&(identical(other.gitRefsUrl, gitRefsUrl) || other.gitRefsUrl == gitRefsUrl)&&(identical(other.gitTagsUrl, gitTagsUrl) || other.gitTagsUrl == gitTagsUrl)&&(identical(other.gitUrl, gitUrl) || other.gitUrl == gitUrl)&&(identical(other.issueCommentUrl, issueCommentUrl) || other.issueCommentUrl == issueCommentUrl)&&(identical(other.id, id) || other.id == id)&&(identical(other.issuesUrl, issuesUrl) || other.issuesUrl == issuesUrl)&&(identical(other.keysUrl, keysUrl) || other.keysUrl == keysUrl)&&(identical(other.labelsUrl, labelsUrl) || other.labelsUrl == labelsUrl)&&(identical(other.languagesUrl, languagesUrl) || other.languagesUrl == languagesUrl)&&(identical(other.mergesUrl, mergesUrl) || other.mergesUrl == mergesUrl)&&(identical(other.milestonesUrl, milestonesUrl) || other.milestonesUrl == milestonesUrl)&&(identical(other.notificationsUrl, notificationsUrl) || other.notificationsUrl == notificationsUrl)&&(identical(other.pullsUrl, pullsUrl) || other.pullsUrl == pullsUrl)&&(identical(other.releasesUrl, releasesUrl) || other.releasesUrl == releasesUrl)&&(identical(other.sshUrl, sshUrl) || other.sshUrl == sshUrl)&&(identical(other.stargazersUrl, stargazersUrl) || other.stargazersUrl == stargazersUrl)&&(identical(other.statusesUrl, statusesUrl) || other.statusesUrl == statusesUrl)&&(identical(other.subscribersUrl, subscribersUrl) || other.subscribersUrl == subscribersUrl)&&(identical(other.subscriptionUrl, subscriptionUrl) || other.subscriptionUrl == subscriptionUrl)&&(identical(other.tagsUrl, tagsUrl) || other.tagsUrl == tagsUrl)&&(identical(other.teamsUrl, teamsUrl) || other.teamsUrl == teamsUrl)&&(identical(other.treesUrl, treesUrl) || other.treesUrl == treesUrl)&&(identical(other.cloneUrl, cloneUrl) || other.cloneUrl == cloneUrl)&&(identical(other.mirrorUrl, mirrorUrl) || other.mirrorUrl == mirrorUrl)&&(identical(other.hooksUrl, hooksUrl) || other.hooksUrl == hooksUrl)&&(identical(other.svnUrl, svnUrl) || other.svnUrl == svnUrl)&&(identical(other.homepage, homepage) || other.homepage == homepage)&&(identical(other.language, language) || other.language == language)&&(identical(other.forksCount, forksCount) || other.forksCount == forksCount)&&(identical(other.stargazersCount, stargazersCount) || other.stargazersCount == stargazersCount)&&(identical(other.watchersCount, watchersCount) || other.watchersCount == watchersCount)&&(identical(other.size, size) || other.size == size)&&(identical(other.defaultBranch, defaultBranch) || other.defaultBranch == defaultBranch)&&(identical(other.openIssuesCount, openIssuesCount) || other.openIssuesCount == openIssuesCount)&&(identical(other.openIssues, openIssues) || other.openIssues == openIssues)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.pushedAt, pushedAt) || other.pushedAt == pushedAt)&&(identical(other.disabled, disabled) || other.disabled == disabled)&&(identical(other.hasPages, hasPages) || other.hasPages == hasPages)&&(identical(other.hasWiki, hasWiki) || other.hasWiki == hasWiki)&&(identical(other.hasDownloads, hasDownloads) || other.hasDownloads == hasDownloads)&&(identical(other.hasDiscussions, hasDiscussions) || other.hasDiscussions == hasDiscussions)&&(identical(other.hasPullRequests, hasPullRequests) || other.hasPullRequests == hasPullRequests)&&(identical(other.allowMergeCommit, allowMergeCommit) || other.allowMergeCommit == allowMergeCommit)&&(identical(other.archived, archived) || other.archived == archived)&&(identical(other.hasProjects, hasProjects) || other.hasProjects == hasProjects)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.webCommitSignoffRequired, webCommitSignoffRequired) || other.webCommitSignoffRequired == webCommitSignoffRequired)&&(identical(other.isTemplate, isTemplate) || other.isTemplate == isTemplate)&&(identical(other.private, private) || other.private == private)&&(identical(other.allowRebaseMerge, allowRebaseMerge) || other.allowRebaseMerge == allowRebaseMerge)&&(identical(other.useSquashPrTitleAsDefault, useSquashPrTitleAsDefault) || other.useSquashPrTitleAsDefault == useSquashPrTitleAsDefault)&&(identical(other.allowSquashMerge, allowSquashMerge) || other.allowSquashMerge == allowSquashMerge)&&(identical(other.allowAutoMerge, allowAutoMerge) || other.allowAutoMerge == allowAutoMerge)&&(identical(other.deleteBranchOnMerge, deleteBranchOnMerge) || other.deleteBranchOnMerge == deleteBranchOnMerge)&&(identical(other.allowUpdateBranch, allowUpdateBranch) || other.allowUpdateBranch == allowUpdateBranch)&&(identical(other.hasIssues, hasIssues) || other.hasIssues == hasIssues)&&(identical(other.squashMergeCommitTitle, squashMergeCommitTitle) || other.squashMergeCommitTitle == squashMergeCommitTitle)&&(identical(other.squashMergeCommitMessage, squashMergeCommitMessage) || other.squashMergeCommitMessage == squashMergeCommitMessage)&&(identical(other.mergeCommitTitle, mergeCommitTitle) || other.mergeCommitTitle == mergeCommitTitle)&&(identical(other.mergeCommitMessage, mergeCommitMessage) || other.mergeCommitMessage == mergeCommitMessage)&&(identical(other.pullRequestCreationPolicy, pullRequestCreationPolicy) || other.pullRequestCreationPolicy == pullRequestCreationPolicy)&&(identical(other.allowForking, allowForking) || other.allowForking == allowForking)&&(identical(other.codeSearchIndexStatus, codeSearchIndexStatus) || other.codeSearchIndexStatus == codeSearchIndexStatus)&&const DeepCollectionEquality().equals(other._topics, _topics)&&(identical(other.permissions, permissions) || other.permissions == permissions)&&(identical(other.masterBranch, masterBranch) || other.masterBranch == masterBranch)&&(identical(other.starredAt, starredAt) || other.starredAt == starredAt)&&(identical(other.anonymousAccessEnabled, anonymousAccessEnabled) || other.anonymousAccessEnabled == anonymousAccessEnabled)&&(identical(other.tempCloneToken, tempCloneToken) || other.tempCloneToken == tempCloneToken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,issueEventsUrl,nodeId,name,fullName,license,forks,watchers,owner,htmlUrl,description,fork,url,archiveUrl,assigneesUrl,blobsUrl,branchesUrl,collaboratorsUrl,commentsUrl,commitsUrl,compareUrl,contentsUrl,contributorsUrl,deploymentsUrl,downloadsUrl,eventsUrl,forksUrl,gitCommitsUrl,gitRefsUrl,gitTagsUrl,gitUrl,issueCommentUrl,id,issuesUrl,keysUrl,labelsUrl,languagesUrl,mergesUrl,milestonesUrl,notificationsUrl,pullsUrl,releasesUrl,sshUrl,stargazersUrl,statusesUrl,subscribersUrl,subscriptionUrl,tagsUrl,teamsUrl,treesUrl,cloneUrl,mirrorUrl,hooksUrl,svnUrl,homepage,language,forksCount,stargazersCount,watchersCount,size,defaultBranch,openIssuesCount,openIssues,createdAt,updatedAt,pushedAt,disabled,hasPages,hasWiki,hasDownloads,hasDiscussions,hasPullRequests,allowMergeCommit,archived,hasProjects,visibility,webCommitSignoffRequired,isTemplate,private,allowRebaseMerge,useSquashPrTitleAsDefault,allowSquashMerge,allowAutoMerge,deleteBranchOnMerge,allowUpdateBranch,hasIssues,squashMergeCommitTitle,squashMergeCommitMessage,mergeCommitTitle,mergeCommitMessage,pullRequestCreationPolicy,allowForking,codeSearchIndexStatus,const DeepCollectionEquality().hash(_topics),permissions,masterBranch,starredAt,anonymousAccessEnabled,tempCloneToken]);

@override
String toString() {
  return 'NullableRepository(issueEventsUrl: $issueEventsUrl, nodeId: $nodeId, name: $name, fullName: $fullName, license: $license, forks: $forks, watchers: $watchers, owner: $owner, htmlUrl: $htmlUrl, description: $description, fork: $fork, url: $url, archiveUrl: $archiveUrl, assigneesUrl: $assigneesUrl, blobsUrl: $blobsUrl, branchesUrl: $branchesUrl, collaboratorsUrl: $collaboratorsUrl, commentsUrl: $commentsUrl, commitsUrl: $commitsUrl, compareUrl: $compareUrl, contentsUrl: $contentsUrl, contributorsUrl: $contributorsUrl, deploymentsUrl: $deploymentsUrl, downloadsUrl: $downloadsUrl, eventsUrl: $eventsUrl, forksUrl: $forksUrl, gitCommitsUrl: $gitCommitsUrl, gitRefsUrl: $gitRefsUrl, gitTagsUrl: $gitTagsUrl, gitUrl: $gitUrl, issueCommentUrl: $issueCommentUrl, id: $id, issuesUrl: $issuesUrl, keysUrl: $keysUrl, labelsUrl: $labelsUrl, languagesUrl: $languagesUrl, mergesUrl: $mergesUrl, milestonesUrl: $milestonesUrl, notificationsUrl: $notificationsUrl, pullsUrl: $pullsUrl, releasesUrl: $releasesUrl, sshUrl: $sshUrl, stargazersUrl: $stargazersUrl, statusesUrl: $statusesUrl, subscribersUrl: $subscribersUrl, subscriptionUrl: $subscriptionUrl, tagsUrl: $tagsUrl, teamsUrl: $teamsUrl, treesUrl: $treesUrl, cloneUrl: $cloneUrl, mirrorUrl: $mirrorUrl, hooksUrl: $hooksUrl, svnUrl: $svnUrl, homepage: $homepage, language: $language, forksCount: $forksCount, stargazersCount: $stargazersCount, watchersCount: $watchersCount, size: $size, defaultBranch: $defaultBranch, openIssuesCount: $openIssuesCount, openIssues: $openIssues, createdAt: $createdAt, updatedAt: $updatedAt, pushedAt: $pushedAt, disabled: $disabled, hasPages: $hasPages, hasWiki: $hasWiki, hasDownloads: $hasDownloads, hasDiscussions: $hasDiscussions, hasPullRequests: $hasPullRequests, allowMergeCommit: $allowMergeCommit, archived: $archived, hasProjects: $hasProjects, visibility: $visibility, webCommitSignoffRequired: $webCommitSignoffRequired, isTemplate: $isTemplate, private: $private, allowRebaseMerge: $allowRebaseMerge, useSquashPrTitleAsDefault: $useSquashPrTitleAsDefault, allowSquashMerge: $allowSquashMerge, allowAutoMerge: $allowAutoMerge, deleteBranchOnMerge: $deleteBranchOnMerge, allowUpdateBranch: $allowUpdateBranch, hasIssues: $hasIssues, squashMergeCommitTitle: $squashMergeCommitTitle, squashMergeCommitMessage: $squashMergeCommitMessage, mergeCommitTitle: $mergeCommitTitle, mergeCommitMessage: $mergeCommitMessage, pullRequestCreationPolicy: $pullRequestCreationPolicy, allowForking: $allowForking, codeSearchIndexStatus: $codeSearchIndexStatus, topics: $topics, permissions: $permissions, masterBranch: $masterBranch, starredAt: $starredAt, anonymousAccessEnabled: $anonymousAccessEnabled, tempCloneToken: $tempCloneToken)';
}


}

/// @nodoc
abstract mixin class _$NullableRepositoryCopyWith<$Res> implements $NullableRepositoryCopyWith<$Res> {
  factory _$NullableRepositoryCopyWith(_NullableRepository value, $Res Function(_NullableRepository) _then) = __$NullableRepositoryCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'issue_events_url') String issueEventsUrl,@JsonKey(name: 'node_id') String nodeId, String name,@JsonKey(name: 'full_name') String fullName,@JsonKey(name: 'License') NullableLicenseSimple? license, int forks, int watchers, SimpleUser owner,@JsonKey(name: 'html_url') String htmlUrl, String? description, bool fork, String url,@JsonKey(name: 'archive_url') String archiveUrl,@JsonKey(name: 'assignees_url') String assigneesUrl,@JsonKey(name: 'blobs_url') String blobsUrl,@JsonKey(name: 'branches_url') String branchesUrl,@JsonKey(name: 'collaborators_url') String collaboratorsUrl,@JsonKey(name: 'comments_url') String commentsUrl,@JsonKey(name: 'commits_url') String commitsUrl,@JsonKey(name: 'compare_url') String compareUrl,@JsonKey(name: 'contents_url') String contentsUrl,@JsonKey(name: 'contributors_url') String contributorsUrl,@JsonKey(name: 'deployments_url') String deploymentsUrl,@JsonKey(name: 'downloads_url') String downloadsUrl,@JsonKey(name: 'events_url') String eventsUrl,@JsonKey(name: 'forks_url') String forksUrl,@JsonKey(name: 'git_commits_url') String gitCommitsUrl,@JsonKey(name: 'git_refs_url') String gitRefsUrl,@JsonKey(name: 'git_tags_url') String gitTagsUrl,@JsonKey(name: 'git_url') String gitUrl,@JsonKey(name: 'issue_comment_url') String issueCommentUrl, int id,@JsonKey(name: 'issues_url') String issuesUrl,@JsonKey(name: 'keys_url') String keysUrl,@JsonKey(name: 'labels_url') String labelsUrl,@JsonKey(name: 'languages_url') String languagesUrl,@JsonKey(name: 'merges_url') String mergesUrl,@JsonKey(name: 'milestones_url') String milestonesUrl,@JsonKey(name: 'notifications_url') String notificationsUrl,@JsonKey(name: 'pulls_url') String pullsUrl,@JsonKey(name: 'releases_url') String releasesUrl,@JsonKey(name: 'ssh_url') String sshUrl,@JsonKey(name: 'stargazers_url') String stargazersUrl,@JsonKey(name: 'statuses_url') String statusesUrl,@JsonKey(name: 'subscribers_url') String subscribersUrl,@JsonKey(name: 'subscription_url') String subscriptionUrl,@JsonKey(name: 'tags_url') String tagsUrl,@JsonKey(name: 'teams_url') String teamsUrl,@JsonKey(name: 'trees_url') String treesUrl,@JsonKey(name: 'clone_url') String cloneUrl,@JsonKey(name: 'mirror_url') String? mirrorUrl,@JsonKey(name: 'hooks_url') String hooksUrl,@JsonKey(name: 'svn_url') String svnUrl, String? homepage,@JsonKey(name: 'Language') String? language,@JsonKey(name: 'forks_count') int forksCount,@JsonKey(name: 'stargazers_count') int stargazersCount,@JsonKey(name: 'watchers_count') int watchersCount, int size,@JsonKey(name: 'default_branch') String defaultBranch,@JsonKey(name: 'open_issues_count') int openIssuesCount,@JsonKey(name: 'open_issues') int openIssues,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt,@JsonKey(name: 'pushed_at') DateTime? pushedAt, bool disabled,@JsonKey(name: 'has_pages') bool hasPages,@JsonKey(name: 'has_wiki') bool hasWiki,@JsonKey(name: 'has_downloads')@Deprecated('This is marked as deprecated') bool hasDownloads,@JsonKey(name: 'has_discussions') bool hasDiscussions,@JsonKey(name: 'has_pull_requests') bool hasPullRequests,@JsonKey(name: 'allow_merge_commit') bool allowMergeCommit, bool archived,@JsonKey(name: 'has_projects') bool hasProjects, String visibility,@JsonKey(name: 'web_commit_signoff_required') bool webCommitSignoffRequired,@JsonKey(name: 'is_template') bool isTemplate, bool private,@JsonKey(name: 'allow_rebase_merge') bool allowRebaseMerge,@JsonKey(name: 'use_squash_pr_title_as_default')@Deprecated('This is marked as deprecated') bool useSquashPrTitleAsDefault,@JsonKey(name: 'allow_squash_merge') bool allowSquashMerge,@JsonKey(name: 'allow_auto_merge') bool allowAutoMerge,@JsonKey(name: 'delete_branch_on_merge') bool deleteBranchOnMerge,@JsonKey(name: 'allow_update_branch') bool allowUpdateBranch,@JsonKey(name: 'has_issues') bool hasIssues,@JsonKey(name: 'squash_merge_commit_title') NullableRepositorySquashMergeCommitTitle? squashMergeCommitTitle,@JsonKey(name: 'squash_merge_commit_message') NullableRepositorySquashMergeCommitMessage? squashMergeCommitMessage,@JsonKey(name: 'merge_commit_title') NullableRepositoryMergeCommitTitle? mergeCommitTitle,@JsonKey(name: 'merge_commit_message') NullableRepositoryMergeCommitMessage? mergeCommitMessage,@JsonKey(name: 'pull_request_creation_policy') NullableRepositoryPullRequestCreationPolicy? pullRequestCreationPolicy,@JsonKey(name: 'allow_forking') bool? allowForking,@JsonKey(name: 'code_search_index_status') CodeSearchIndexStatus2? codeSearchIndexStatus, List<String>? topics, Permissions10? permissions,@JsonKey(name: 'master_branch') String? masterBranch,@JsonKey(name: 'starred_at') String? starredAt,@JsonKey(name: 'anonymous_access_enabled') bool? anonymousAccessEnabled,@JsonKey(name: 'temp_clone_token') String? tempCloneToken
});


@override $NullableLicenseSimpleCopyWith<$Res>? get license;@override $SimpleUserCopyWith<$Res> get owner;@override $CodeSearchIndexStatus2CopyWith<$Res>? get codeSearchIndexStatus;@override $Permissions10CopyWith<$Res>? get permissions;

}
/// @nodoc
class __$NullableRepositoryCopyWithImpl<$Res>
    implements _$NullableRepositoryCopyWith<$Res> {
  __$NullableRepositoryCopyWithImpl(this._self, this._then);

  final _NullableRepository _self;
  final $Res Function(_NullableRepository) _then;

/// Create a copy of NullableRepository
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? issueEventsUrl = null,Object? nodeId = null,Object? name = null,Object? fullName = null,Object? license = freezed,Object? forks = null,Object? watchers = null,Object? owner = null,Object? htmlUrl = null,Object? description = freezed,Object? fork = null,Object? url = null,Object? archiveUrl = null,Object? assigneesUrl = null,Object? blobsUrl = null,Object? branchesUrl = null,Object? collaboratorsUrl = null,Object? commentsUrl = null,Object? commitsUrl = null,Object? compareUrl = null,Object? contentsUrl = null,Object? contributorsUrl = null,Object? deploymentsUrl = null,Object? downloadsUrl = null,Object? eventsUrl = null,Object? forksUrl = null,Object? gitCommitsUrl = null,Object? gitRefsUrl = null,Object? gitTagsUrl = null,Object? gitUrl = null,Object? issueCommentUrl = null,Object? id = null,Object? issuesUrl = null,Object? keysUrl = null,Object? labelsUrl = null,Object? languagesUrl = null,Object? mergesUrl = null,Object? milestonesUrl = null,Object? notificationsUrl = null,Object? pullsUrl = null,Object? releasesUrl = null,Object? sshUrl = null,Object? stargazersUrl = null,Object? statusesUrl = null,Object? subscribersUrl = null,Object? subscriptionUrl = null,Object? tagsUrl = null,Object? teamsUrl = null,Object? treesUrl = null,Object? cloneUrl = null,Object? mirrorUrl = freezed,Object? hooksUrl = null,Object? svnUrl = null,Object? homepage = freezed,Object? language = freezed,Object? forksCount = null,Object? stargazersCount = null,Object? watchersCount = null,Object? size = null,Object? defaultBranch = null,Object? openIssuesCount = null,Object? openIssues = null,Object? createdAt = freezed,Object? updatedAt = freezed,Object? pushedAt = freezed,Object? disabled = null,Object? hasPages = null,Object? hasWiki = null,Object? hasDownloads = null,Object? hasDiscussions = null,Object? hasPullRequests = null,Object? allowMergeCommit = null,Object? archived = null,Object? hasProjects = null,Object? visibility = null,Object? webCommitSignoffRequired = null,Object? isTemplate = null,Object? private = null,Object? allowRebaseMerge = null,Object? useSquashPrTitleAsDefault = null,Object? allowSquashMerge = null,Object? allowAutoMerge = null,Object? deleteBranchOnMerge = null,Object? allowUpdateBranch = null,Object? hasIssues = null,Object? squashMergeCommitTitle = freezed,Object? squashMergeCommitMessage = freezed,Object? mergeCommitTitle = freezed,Object? mergeCommitMessage = freezed,Object? pullRequestCreationPolicy = freezed,Object? allowForking = freezed,Object? codeSearchIndexStatus = freezed,Object? topics = freezed,Object? permissions = freezed,Object? masterBranch = freezed,Object? starredAt = freezed,Object? anonymousAccessEnabled = freezed,Object? tempCloneToken = freezed,}) {
  return _then(_NullableRepository(
issueEventsUrl: null == issueEventsUrl ? _self.issueEventsUrl : issueEventsUrl // ignore: cast_nullable_to_non_nullable
as String,nodeId: null == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,license: freezed == license ? _self.license : license // ignore: cast_nullable_to_non_nullable
as NullableLicenseSimple?,forks: null == forks ? _self.forks : forks // ignore: cast_nullable_to_non_nullable
as int,watchers: null == watchers ? _self.watchers : watchers // ignore: cast_nullable_to_non_nullable
as int,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as SimpleUser,htmlUrl: null == htmlUrl ? _self.htmlUrl : htmlUrl // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,fork: null == fork ? _self.fork : fork // ignore: cast_nullable_to_non_nullable
as bool,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,archiveUrl: null == archiveUrl ? _self.archiveUrl : archiveUrl // ignore: cast_nullable_to_non_nullable
as String,assigneesUrl: null == assigneesUrl ? _self.assigneesUrl : assigneesUrl // ignore: cast_nullable_to_non_nullable
as String,blobsUrl: null == blobsUrl ? _self.blobsUrl : blobsUrl // ignore: cast_nullable_to_non_nullable
as String,branchesUrl: null == branchesUrl ? _self.branchesUrl : branchesUrl // ignore: cast_nullable_to_non_nullable
as String,collaboratorsUrl: null == collaboratorsUrl ? _self.collaboratorsUrl : collaboratorsUrl // ignore: cast_nullable_to_non_nullable
as String,commentsUrl: null == commentsUrl ? _self.commentsUrl : commentsUrl // ignore: cast_nullable_to_non_nullable
as String,commitsUrl: null == commitsUrl ? _self.commitsUrl : commitsUrl // ignore: cast_nullable_to_non_nullable
as String,compareUrl: null == compareUrl ? _self.compareUrl : compareUrl // ignore: cast_nullable_to_non_nullable
as String,contentsUrl: null == contentsUrl ? _self.contentsUrl : contentsUrl // ignore: cast_nullable_to_non_nullable
as String,contributorsUrl: null == contributorsUrl ? _self.contributorsUrl : contributorsUrl // ignore: cast_nullable_to_non_nullable
as String,deploymentsUrl: null == deploymentsUrl ? _self.deploymentsUrl : deploymentsUrl // ignore: cast_nullable_to_non_nullable
as String,downloadsUrl: null == downloadsUrl ? _self.downloadsUrl : downloadsUrl // ignore: cast_nullable_to_non_nullable
as String,eventsUrl: null == eventsUrl ? _self.eventsUrl : eventsUrl // ignore: cast_nullable_to_non_nullable
as String,forksUrl: null == forksUrl ? _self.forksUrl : forksUrl // ignore: cast_nullable_to_non_nullable
as String,gitCommitsUrl: null == gitCommitsUrl ? _self.gitCommitsUrl : gitCommitsUrl // ignore: cast_nullable_to_non_nullable
as String,gitRefsUrl: null == gitRefsUrl ? _self.gitRefsUrl : gitRefsUrl // ignore: cast_nullable_to_non_nullable
as String,gitTagsUrl: null == gitTagsUrl ? _self.gitTagsUrl : gitTagsUrl // ignore: cast_nullable_to_non_nullable
as String,gitUrl: null == gitUrl ? _self.gitUrl : gitUrl // ignore: cast_nullable_to_non_nullable
as String,issueCommentUrl: null == issueCommentUrl ? _self.issueCommentUrl : issueCommentUrl // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,issuesUrl: null == issuesUrl ? _self.issuesUrl : issuesUrl // ignore: cast_nullable_to_non_nullable
as String,keysUrl: null == keysUrl ? _self.keysUrl : keysUrl // ignore: cast_nullable_to_non_nullable
as String,labelsUrl: null == labelsUrl ? _self.labelsUrl : labelsUrl // ignore: cast_nullable_to_non_nullable
as String,languagesUrl: null == languagesUrl ? _self.languagesUrl : languagesUrl // ignore: cast_nullable_to_non_nullable
as String,mergesUrl: null == mergesUrl ? _self.mergesUrl : mergesUrl // ignore: cast_nullable_to_non_nullable
as String,milestonesUrl: null == milestonesUrl ? _self.milestonesUrl : milestonesUrl // ignore: cast_nullable_to_non_nullable
as String,notificationsUrl: null == notificationsUrl ? _self.notificationsUrl : notificationsUrl // ignore: cast_nullable_to_non_nullable
as String,pullsUrl: null == pullsUrl ? _self.pullsUrl : pullsUrl // ignore: cast_nullable_to_non_nullable
as String,releasesUrl: null == releasesUrl ? _self.releasesUrl : releasesUrl // ignore: cast_nullable_to_non_nullable
as String,sshUrl: null == sshUrl ? _self.sshUrl : sshUrl // ignore: cast_nullable_to_non_nullable
as String,stargazersUrl: null == stargazersUrl ? _self.stargazersUrl : stargazersUrl // ignore: cast_nullable_to_non_nullable
as String,statusesUrl: null == statusesUrl ? _self.statusesUrl : statusesUrl // ignore: cast_nullable_to_non_nullable
as String,subscribersUrl: null == subscribersUrl ? _self.subscribersUrl : subscribersUrl // ignore: cast_nullable_to_non_nullable
as String,subscriptionUrl: null == subscriptionUrl ? _self.subscriptionUrl : subscriptionUrl // ignore: cast_nullable_to_non_nullable
as String,tagsUrl: null == tagsUrl ? _self.tagsUrl : tagsUrl // ignore: cast_nullable_to_non_nullable
as String,teamsUrl: null == teamsUrl ? _self.teamsUrl : teamsUrl // ignore: cast_nullable_to_non_nullable
as String,treesUrl: null == treesUrl ? _self.treesUrl : treesUrl // ignore: cast_nullable_to_non_nullable
as String,cloneUrl: null == cloneUrl ? _self.cloneUrl : cloneUrl // ignore: cast_nullable_to_non_nullable
as String,mirrorUrl: freezed == mirrorUrl ? _self.mirrorUrl : mirrorUrl // ignore: cast_nullable_to_non_nullable
as String?,hooksUrl: null == hooksUrl ? _self.hooksUrl : hooksUrl // ignore: cast_nullable_to_non_nullable
as String,svnUrl: null == svnUrl ? _self.svnUrl : svnUrl // ignore: cast_nullable_to_non_nullable
as String,homepage: freezed == homepage ? _self.homepage : homepage // ignore: cast_nullable_to_non_nullable
as String?,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,forksCount: null == forksCount ? _self.forksCount : forksCount // ignore: cast_nullable_to_non_nullable
as int,stargazersCount: null == stargazersCount ? _self.stargazersCount : stargazersCount // ignore: cast_nullable_to_non_nullable
as int,watchersCount: null == watchersCount ? _self.watchersCount : watchersCount // ignore: cast_nullable_to_non_nullable
as int,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as int,defaultBranch: null == defaultBranch ? _self.defaultBranch : defaultBranch // ignore: cast_nullable_to_non_nullable
as String,openIssuesCount: null == openIssuesCount ? _self.openIssuesCount : openIssuesCount // ignore: cast_nullable_to_non_nullable
as int,openIssues: null == openIssues ? _self.openIssues : openIssues // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,pushedAt: freezed == pushedAt ? _self.pushedAt : pushedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,disabled: null == disabled ? _self.disabled : disabled // ignore: cast_nullable_to_non_nullable
as bool,hasPages: null == hasPages ? _self.hasPages : hasPages // ignore: cast_nullable_to_non_nullable
as bool,hasWiki: null == hasWiki ? _self.hasWiki : hasWiki // ignore: cast_nullable_to_non_nullable
as bool,hasDownloads: null == hasDownloads ? _self.hasDownloads : hasDownloads // ignore: cast_nullable_to_non_nullable
as bool,hasDiscussions: null == hasDiscussions ? _self.hasDiscussions : hasDiscussions // ignore: cast_nullable_to_non_nullable
as bool,hasPullRequests: null == hasPullRequests ? _self.hasPullRequests : hasPullRequests // ignore: cast_nullable_to_non_nullable
as bool,allowMergeCommit: null == allowMergeCommit ? _self.allowMergeCommit : allowMergeCommit // ignore: cast_nullable_to_non_nullable
as bool,archived: null == archived ? _self.archived : archived // ignore: cast_nullable_to_non_nullable
as bool,hasProjects: null == hasProjects ? _self.hasProjects : hasProjects // ignore: cast_nullable_to_non_nullable
as bool,visibility: null == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as String,webCommitSignoffRequired: null == webCommitSignoffRequired ? _self.webCommitSignoffRequired : webCommitSignoffRequired // ignore: cast_nullable_to_non_nullable
as bool,isTemplate: null == isTemplate ? _self.isTemplate : isTemplate // ignore: cast_nullable_to_non_nullable
as bool,private: null == private ? _self.private : private // ignore: cast_nullable_to_non_nullable
as bool,allowRebaseMerge: null == allowRebaseMerge ? _self.allowRebaseMerge : allowRebaseMerge // ignore: cast_nullable_to_non_nullable
as bool,useSquashPrTitleAsDefault: null == useSquashPrTitleAsDefault ? _self.useSquashPrTitleAsDefault : useSquashPrTitleAsDefault // ignore: cast_nullable_to_non_nullable
as bool,allowSquashMerge: null == allowSquashMerge ? _self.allowSquashMerge : allowSquashMerge // ignore: cast_nullable_to_non_nullable
as bool,allowAutoMerge: null == allowAutoMerge ? _self.allowAutoMerge : allowAutoMerge // ignore: cast_nullable_to_non_nullable
as bool,deleteBranchOnMerge: null == deleteBranchOnMerge ? _self.deleteBranchOnMerge : deleteBranchOnMerge // ignore: cast_nullable_to_non_nullable
as bool,allowUpdateBranch: null == allowUpdateBranch ? _self.allowUpdateBranch : allowUpdateBranch // ignore: cast_nullable_to_non_nullable
as bool,hasIssues: null == hasIssues ? _self.hasIssues : hasIssues // ignore: cast_nullable_to_non_nullable
as bool,squashMergeCommitTitle: freezed == squashMergeCommitTitle ? _self.squashMergeCommitTitle : squashMergeCommitTitle // ignore: cast_nullable_to_non_nullable
as NullableRepositorySquashMergeCommitTitle?,squashMergeCommitMessage: freezed == squashMergeCommitMessage ? _self.squashMergeCommitMessage : squashMergeCommitMessage // ignore: cast_nullable_to_non_nullable
as NullableRepositorySquashMergeCommitMessage?,mergeCommitTitle: freezed == mergeCommitTitle ? _self.mergeCommitTitle : mergeCommitTitle // ignore: cast_nullable_to_non_nullable
as NullableRepositoryMergeCommitTitle?,mergeCommitMessage: freezed == mergeCommitMessage ? _self.mergeCommitMessage : mergeCommitMessage // ignore: cast_nullable_to_non_nullable
as NullableRepositoryMergeCommitMessage?,pullRequestCreationPolicy: freezed == pullRequestCreationPolicy ? _self.pullRequestCreationPolicy : pullRequestCreationPolicy // ignore: cast_nullable_to_non_nullable
as NullableRepositoryPullRequestCreationPolicy?,allowForking: freezed == allowForking ? _self.allowForking : allowForking // ignore: cast_nullable_to_non_nullable
as bool?,codeSearchIndexStatus: freezed == codeSearchIndexStatus ? _self.codeSearchIndexStatus : codeSearchIndexStatus // ignore: cast_nullable_to_non_nullable
as CodeSearchIndexStatus2?,topics: freezed == topics ? _self._topics : topics // ignore: cast_nullable_to_non_nullable
as List<String>?,permissions: freezed == permissions ? _self.permissions : permissions // ignore: cast_nullable_to_non_nullable
as Permissions10?,masterBranch: freezed == masterBranch ? _self.masterBranch : masterBranch // ignore: cast_nullable_to_non_nullable
as String?,starredAt: freezed == starredAt ? _self.starredAt : starredAt // ignore: cast_nullable_to_non_nullable
as String?,anonymousAccessEnabled: freezed == anonymousAccessEnabled ? _self.anonymousAccessEnabled : anonymousAccessEnabled // ignore: cast_nullable_to_non_nullable
as bool?,tempCloneToken: freezed == tempCloneToken ? _self.tempCloneToken : tempCloneToken // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of NullableRepository
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NullableLicenseSimpleCopyWith<$Res>? get license {
    if (_self.license == null) {
    return null;
  }

  return $NullableLicenseSimpleCopyWith<$Res>(_self.license!, (value) {
    return _then(_self.copyWith(license: value));
  });
}/// Create a copy of NullableRepository
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SimpleUserCopyWith<$Res> get owner {
  
  return $SimpleUserCopyWith<$Res>(_self.owner, (value) {
    return _then(_self.copyWith(owner: value));
  });
}/// Create a copy of NullableRepository
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CodeSearchIndexStatus2CopyWith<$Res>? get codeSearchIndexStatus {
    if (_self.codeSearchIndexStatus == null) {
    return null;
  }

  return $CodeSearchIndexStatus2CopyWith<$Res>(_self.codeSearchIndexStatus!, (value) {
    return _then(_self.copyWith(codeSearchIndexStatus: value));
  });
}/// Create a copy of NullableRepository
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Permissions10CopyWith<$Res>? get permissions {
    if (_self.permissions == null) {
    return null;
  }

  return $Permissions10CopyWith<$Res>(_self.permissions!, (value) {
    return _then(_self.copyWith(permissions: value));
  });
}
}

// dart format on
