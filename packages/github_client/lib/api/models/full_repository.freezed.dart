// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'full_repository.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FullRepository {

@JsonKey(name: 'milestones_url') String get milestonesUrl;@JsonKey(name: 'node_id') String get nodeId; String get name;@JsonKey(name: 'full_name') String get fullName; SimpleUser get owner; bool get private;@JsonKey(name: 'html_url') String get htmlUrl; String? get description; bool get fork; String get url;@JsonKey(name: 'archive_url') String get archiveUrl;@JsonKey(name: 'assignees_url') String get assigneesUrl;@JsonKey(name: 'blobs_url') String get blobsUrl;@JsonKey(name: 'branches_url') String get branchesUrl;@JsonKey(name: 'collaborators_url') String get collaboratorsUrl;@JsonKey(name: 'comments_url') String get commentsUrl;@JsonKey(name: 'commits_url') String get commitsUrl;@JsonKey(name: 'compare_url') String get compareUrl;@JsonKey(name: 'contents_url') String get contentsUrl;@JsonKey(name: 'contributors_url') String get contributorsUrl;@JsonKey(name: 'deployments_url') String get deploymentsUrl;@JsonKey(name: 'downloads_url') String get downloadsUrl;@JsonKey(name: 'events_url') String get eventsUrl;@JsonKey(name: 'forks_url') String get forksUrl;@JsonKey(name: 'git_commits_url') String get gitCommitsUrl;@JsonKey(name: 'git_refs_url') String get gitRefsUrl;@JsonKey(name: 'git_tags_url') String get gitTagsUrl;@JsonKey(name: 'git_url') String get gitUrl;@JsonKey(name: 'issue_comment_url') String get issueCommentUrl;@JsonKey(name: 'issue_events_url') String get issueEventsUrl;@JsonKey(name: 'issues_url') String get issuesUrl;@JsonKey(name: 'keys_url') String get keysUrl;@JsonKey(name: 'labels_url') String get labelsUrl;@JsonKey(name: 'languages_url') String get languagesUrl;@JsonKey(name: 'merges_url') String get mergesUrl; int get id;@JsonKey(name: 'notifications_url') String get notificationsUrl;@JsonKey(name: 'pulls_url') String get pullsUrl;@JsonKey(name: 'releases_url') String get releasesUrl;@JsonKey(name: 'ssh_url') String get sshUrl;@JsonKey(name: 'stargazers_url') String get stargazersUrl;@JsonKey(name: 'statuses_url') String get statusesUrl;@JsonKey(name: 'subscribers_url') String get subscribersUrl;@JsonKey(name: 'subscription_url') String get subscriptionUrl;@JsonKey(name: 'tags_url') String get tagsUrl;@JsonKey(name: 'teams_url') String get teamsUrl;@JsonKey(name: 'trees_url') String get treesUrl;@JsonKey(name: 'clone_url') String get cloneUrl;@JsonKey(name: 'mirror_url') String? get mirrorUrl;@JsonKey(name: 'hooks_url') String get hooksUrl;@JsonKey(name: 'svn_url') String get svnUrl; String? get homepage;@JsonKey(name: 'Language') String? get language;@JsonKey(name: 'forks_count') int get forksCount;@JsonKey(name: 'stargazers_count') int get stargazersCount;@JsonKey(name: 'watchers_count') int get watchersCount;/// The size of the repository, in kilobytes. Size is calculated hourly. When a Repository is initially created, the size is 0.
 int get size;@JsonKey(name: 'default_branch') String get defaultBranch;@JsonKey(name: 'open_issues_count') int get openIssuesCount; int get watchers;@JsonKey(name: 'open_issues') int get openIssues;@JsonKey(name: 'has_issues') bool get hasIssues;@JsonKey(name: 'has_projects') bool get hasProjects;@JsonKey(name: 'has_wiki') bool get hasWiki;@JsonKey(name: 'has_pages') bool get hasPages; int get forks;@JsonKey(name: 'has_discussions') bool get hasDiscussions;@JsonKey(name: 'License') NullableLicenseSimple? get license;@JsonKey(name: 'network_count') int get networkCount;@JsonKey(name: 'subscribers_count') int get subscribersCount;/// Returns whether or not this Repository disabled.
 bool get disabled;@JsonKey(name: 'updated_at') DateTime get updatedAt;@JsonKey(name: 'pushed_at') DateTime get pushedAt;@JsonKey(name: 'created_at') DateTime get createdAt; bool get archived;/// Whether anonymous git access is allowed.
@JsonKey(name: 'anonymous_access_enabled') bool get anonymousAccessEnabled; Permissions11? get permissions;@JsonKey(name: 'allow_rebase_merge') bool? get allowRebaseMerge;@JsonKey(name: 'template_repository') NullableRepository? get templateRepository;@JsonKey(name: 'temp_clone_token') String? get tempCloneToken;@JsonKey(name: 'allow_squash_merge') bool? get allowSquashMerge;@JsonKey(name: 'allow_auto_merge') bool? get allowAutoMerge;@JsonKey(name: 'delete_branch_on_merge') bool? get deleteBranchOnMerge;@JsonKey(name: 'allow_merge_commit') bool? get allowMergeCommit;@JsonKey(name: 'allow_update_branch') bool? get allowUpdateBranch;@JsonKey(name: 'use_squash_pr_title_as_default') bool? get useSquashPrTitleAsDefault;/// The default value for a squash merge Commit title:.
///
/// - `PR_TITLE` - default to the pull request's title.
/// - `COMMIT_OR_PR_TITLE` - default to the Commit's title (if only one commit) or the pull request's title (when more than one commit).
@JsonKey(name: 'squash_merge_commit_title') FullRepositorySquashMergeCommitTitle? get squashMergeCommitTitle;/// The default value for a squash merge Commit message:.
///
/// - `PR_BODY` - default to the pull request's body.
/// - `COMMIT_MESSAGES` - default to the branch's Commit messages.
/// - `BLANK` - default to a blank Commit message.
@JsonKey(name: 'squash_merge_commit_message') FullRepositorySquashMergeCommitMessage? get squashMergeCommitMessage;/// The default value for a merge Commit title.
///
///   - `PR_TITLE` - default to the pull request's title.
///   - `MERGE_MESSAGE` - default to the classic title for a merge message (e.g., Merge pull request #123 from branch-name).
@JsonKey(name: 'merge_commit_title') FullRepositoryMergeCommitTitle? get mergeCommitTitle;/// The default value for a merge Commit message.
///
/// - `PR_TITLE` - default to the pull request's title.
/// - `PR_BODY` - default to the pull request's body.
/// - `BLANK` - default to a blank Commit message.
@JsonKey(name: 'merge_commit_message') FullRepositoryMergeCommitMessage? get mergeCommitMessage;@JsonKey(name: 'allow_forking') bool? get allowForking;@JsonKey(name: 'web_commit_signoff_required') bool? get webCommitSignoffRequired;/// The custom properties that were defined for the repository. The keys are the custom property names, and the values are the corresponding custom property values.
@JsonKey(name: 'custom_properties') dynamic get customProperties;/// The policy controlling who can create pull requests: all or collaborators_only.
@JsonKey(name: 'pull_request_creation_policy') FullRepositoryPullRequestCreationPolicy? get pullRequestCreationPolicy;@JsonKey(name: 'has_pull_requests') bool? get hasPullRequests; NullableSimpleUser? get organization; Repository? get parent; Repository? get source;@JsonKey(name: 'has_downloads') bool? get hasDownloads;@JsonKey(name: 'master_branch') String? get masterBranch; List<String>? get topics;@JsonKey(name: 'is_template') bool? get isTemplate;@JsonKey(name: 'code_of_conduct') CodeOfConductSimple? get codeOfConduct;@JsonKey(name: 'security_and_analysis') SecurityAndAnalysis? get securityAndAnalysis;/// The Repository visibility: public, private, or internal.
 String? get visibility;
/// Create a copy of FullRepository
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FullRepositoryCopyWith<FullRepository> get copyWith => _$FullRepositoryCopyWithImpl<FullRepository>(this as FullRepository, _$identity);

  /// Serializes this FullRepository to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FullRepository&&(identical(other.milestonesUrl, milestonesUrl) || other.milestonesUrl == milestonesUrl)&&(identical(other.nodeId, nodeId) || other.nodeId == nodeId)&&(identical(other.name, name) || other.name == name)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.private, private) || other.private == private)&&(identical(other.htmlUrl, htmlUrl) || other.htmlUrl == htmlUrl)&&(identical(other.description, description) || other.description == description)&&(identical(other.fork, fork) || other.fork == fork)&&(identical(other.url, url) || other.url == url)&&(identical(other.archiveUrl, archiveUrl) || other.archiveUrl == archiveUrl)&&(identical(other.assigneesUrl, assigneesUrl) || other.assigneesUrl == assigneesUrl)&&(identical(other.blobsUrl, blobsUrl) || other.blobsUrl == blobsUrl)&&(identical(other.branchesUrl, branchesUrl) || other.branchesUrl == branchesUrl)&&(identical(other.collaboratorsUrl, collaboratorsUrl) || other.collaboratorsUrl == collaboratorsUrl)&&(identical(other.commentsUrl, commentsUrl) || other.commentsUrl == commentsUrl)&&(identical(other.commitsUrl, commitsUrl) || other.commitsUrl == commitsUrl)&&(identical(other.compareUrl, compareUrl) || other.compareUrl == compareUrl)&&(identical(other.contentsUrl, contentsUrl) || other.contentsUrl == contentsUrl)&&(identical(other.contributorsUrl, contributorsUrl) || other.contributorsUrl == contributorsUrl)&&(identical(other.deploymentsUrl, deploymentsUrl) || other.deploymentsUrl == deploymentsUrl)&&(identical(other.downloadsUrl, downloadsUrl) || other.downloadsUrl == downloadsUrl)&&(identical(other.eventsUrl, eventsUrl) || other.eventsUrl == eventsUrl)&&(identical(other.forksUrl, forksUrl) || other.forksUrl == forksUrl)&&(identical(other.gitCommitsUrl, gitCommitsUrl) || other.gitCommitsUrl == gitCommitsUrl)&&(identical(other.gitRefsUrl, gitRefsUrl) || other.gitRefsUrl == gitRefsUrl)&&(identical(other.gitTagsUrl, gitTagsUrl) || other.gitTagsUrl == gitTagsUrl)&&(identical(other.gitUrl, gitUrl) || other.gitUrl == gitUrl)&&(identical(other.issueCommentUrl, issueCommentUrl) || other.issueCommentUrl == issueCommentUrl)&&(identical(other.issueEventsUrl, issueEventsUrl) || other.issueEventsUrl == issueEventsUrl)&&(identical(other.issuesUrl, issuesUrl) || other.issuesUrl == issuesUrl)&&(identical(other.keysUrl, keysUrl) || other.keysUrl == keysUrl)&&(identical(other.labelsUrl, labelsUrl) || other.labelsUrl == labelsUrl)&&(identical(other.languagesUrl, languagesUrl) || other.languagesUrl == languagesUrl)&&(identical(other.mergesUrl, mergesUrl) || other.mergesUrl == mergesUrl)&&(identical(other.id, id) || other.id == id)&&(identical(other.notificationsUrl, notificationsUrl) || other.notificationsUrl == notificationsUrl)&&(identical(other.pullsUrl, pullsUrl) || other.pullsUrl == pullsUrl)&&(identical(other.releasesUrl, releasesUrl) || other.releasesUrl == releasesUrl)&&(identical(other.sshUrl, sshUrl) || other.sshUrl == sshUrl)&&(identical(other.stargazersUrl, stargazersUrl) || other.stargazersUrl == stargazersUrl)&&(identical(other.statusesUrl, statusesUrl) || other.statusesUrl == statusesUrl)&&(identical(other.subscribersUrl, subscribersUrl) || other.subscribersUrl == subscribersUrl)&&(identical(other.subscriptionUrl, subscriptionUrl) || other.subscriptionUrl == subscriptionUrl)&&(identical(other.tagsUrl, tagsUrl) || other.tagsUrl == tagsUrl)&&(identical(other.teamsUrl, teamsUrl) || other.teamsUrl == teamsUrl)&&(identical(other.treesUrl, treesUrl) || other.treesUrl == treesUrl)&&(identical(other.cloneUrl, cloneUrl) || other.cloneUrl == cloneUrl)&&(identical(other.mirrorUrl, mirrorUrl) || other.mirrorUrl == mirrorUrl)&&(identical(other.hooksUrl, hooksUrl) || other.hooksUrl == hooksUrl)&&(identical(other.svnUrl, svnUrl) || other.svnUrl == svnUrl)&&(identical(other.homepage, homepage) || other.homepage == homepage)&&(identical(other.language, language) || other.language == language)&&(identical(other.forksCount, forksCount) || other.forksCount == forksCount)&&(identical(other.stargazersCount, stargazersCount) || other.stargazersCount == stargazersCount)&&(identical(other.watchersCount, watchersCount) || other.watchersCount == watchersCount)&&(identical(other.size, size) || other.size == size)&&(identical(other.defaultBranch, defaultBranch) || other.defaultBranch == defaultBranch)&&(identical(other.openIssuesCount, openIssuesCount) || other.openIssuesCount == openIssuesCount)&&(identical(other.watchers, watchers) || other.watchers == watchers)&&(identical(other.openIssues, openIssues) || other.openIssues == openIssues)&&(identical(other.hasIssues, hasIssues) || other.hasIssues == hasIssues)&&(identical(other.hasProjects, hasProjects) || other.hasProjects == hasProjects)&&(identical(other.hasWiki, hasWiki) || other.hasWiki == hasWiki)&&(identical(other.hasPages, hasPages) || other.hasPages == hasPages)&&(identical(other.forks, forks) || other.forks == forks)&&(identical(other.hasDiscussions, hasDiscussions) || other.hasDiscussions == hasDiscussions)&&(identical(other.license, license) || other.license == license)&&(identical(other.networkCount, networkCount) || other.networkCount == networkCount)&&(identical(other.subscribersCount, subscribersCount) || other.subscribersCount == subscribersCount)&&(identical(other.disabled, disabled) || other.disabled == disabled)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.pushedAt, pushedAt) || other.pushedAt == pushedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.archived, archived) || other.archived == archived)&&(identical(other.anonymousAccessEnabled, anonymousAccessEnabled) || other.anonymousAccessEnabled == anonymousAccessEnabled)&&(identical(other.permissions, permissions) || other.permissions == permissions)&&(identical(other.allowRebaseMerge, allowRebaseMerge) || other.allowRebaseMerge == allowRebaseMerge)&&(identical(other.templateRepository, templateRepository) || other.templateRepository == templateRepository)&&(identical(other.tempCloneToken, tempCloneToken) || other.tempCloneToken == tempCloneToken)&&(identical(other.allowSquashMerge, allowSquashMerge) || other.allowSquashMerge == allowSquashMerge)&&(identical(other.allowAutoMerge, allowAutoMerge) || other.allowAutoMerge == allowAutoMerge)&&(identical(other.deleteBranchOnMerge, deleteBranchOnMerge) || other.deleteBranchOnMerge == deleteBranchOnMerge)&&(identical(other.allowMergeCommit, allowMergeCommit) || other.allowMergeCommit == allowMergeCommit)&&(identical(other.allowUpdateBranch, allowUpdateBranch) || other.allowUpdateBranch == allowUpdateBranch)&&(identical(other.useSquashPrTitleAsDefault, useSquashPrTitleAsDefault) || other.useSquashPrTitleAsDefault == useSquashPrTitleAsDefault)&&(identical(other.squashMergeCommitTitle, squashMergeCommitTitle) || other.squashMergeCommitTitle == squashMergeCommitTitle)&&(identical(other.squashMergeCommitMessage, squashMergeCommitMessage) || other.squashMergeCommitMessage == squashMergeCommitMessage)&&(identical(other.mergeCommitTitle, mergeCommitTitle) || other.mergeCommitTitle == mergeCommitTitle)&&(identical(other.mergeCommitMessage, mergeCommitMessage) || other.mergeCommitMessage == mergeCommitMessage)&&(identical(other.allowForking, allowForking) || other.allowForking == allowForking)&&(identical(other.webCommitSignoffRequired, webCommitSignoffRequired) || other.webCommitSignoffRequired == webCommitSignoffRequired)&&const DeepCollectionEquality().equals(other.customProperties, customProperties)&&(identical(other.pullRequestCreationPolicy, pullRequestCreationPolicy) || other.pullRequestCreationPolicy == pullRequestCreationPolicy)&&(identical(other.hasPullRequests, hasPullRequests) || other.hasPullRequests == hasPullRequests)&&(identical(other.organization, organization) || other.organization == organization)&&(identical(other.parent, parent) || other.parent == parent)&&(identical(other.source, source) || other.source == source)&&(identical(other.hasDownloads, hasDownloads) || other.hasDownloads == hasDownloads)&&(identical(other.masterBranch, masterBranch) || other.masterBranch == masterBranch)&&const DeepCollectionEquality().equals(other.topics, topics)&&(identical(other.isTemplate, isTemplate) || other.isTemplate == isTemplate)&&(identical(other.codeOfConduct, codeOfConduct) || other.codeOfConduct == codeOfConduct)&&(identical(other.securityAndAnalysis, securityAndAnalysis) || other.securityAndAnalysis == securityAndAnalysis)&&(identical(other.visibility, visibility) || other.visibility == visibility));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,milestonesUrl,nodeId,name,fullName,owner,private,htmlUrl,description,fork,url,archiveUrl,assigneesUrl,blobsUrl,branchesUrl,collaboratorsUrl,commentsUrl,commitsUrl,compareUrl,contentsUrl,contributorsUrl,deploymentsUrl,downloadsUrl,eventsUrl,forksUrl,gitCommitsUrl,gitRefsUrl,gitTagsUrl,gitUrl,issueCommentUrl,issueEventsUrl,issuesUrl,keysUrl,labelsUrl,languagesUrl,mergesUrl,id,notificationsUrl,pullsUrl,releasesUrl,sshUrl,stargazersUrl,statusesUrl,subscribersUrl,subscriptionUrl,tagsUrl,teamsUrl,treesUrl,cloneUrl,mirrorUrl,hooksUrl,svnUrl,homepage,language,forksCount,stargazersCount,watchersCount,size,defaultBranch,openIssuesCount,watchers,openIssues,hasIssues,hasProjects,hasWiki,hasPages,forks,hasDiscussions,license,networkCount,subscribersCount,disabled,updatedAt,pushedAt,createdAt,archived,anonymousAccessEnabled,permissions,allowRebaseMerge,templateRepository,tempCloneToken,allowSquashMerge,allowAutoMerge,deleteBranchOnMerge,allowMergeCommit,allowUpdateBranch,useSquashPrTitleAsDefault,squashMergeCommitTitle,squashMergeCommitMessage,mergeCommitTitle,mergeCommitMessage,allowForking,webCommitSignoffRequired,const DeepCollectionEquality().hash(customProperties),pullRequestCreationPolicy,hasPullRequests,organization,parent,source,hasDownloads,masterBranch,const DeepCollectionEquality().hash(topics),isTemplate,codeOfConduct,securityAndAnalysis,visibility]);

@override
String toString() {
  return 'FullRepository(milestonesUrl: $milestonesUrl, nodeId: $nodeId, name: $name, fullName: $fullName, owner: $owner, private: $private, htmlUrl: $htmlUrl, description: $description, fork: $fork, url: $url, archiveUrl: $archiveUrl, assigneesUrl: $assigneesUrl, blobsUrl: $blobsUrl, branchesUrl: $branchesUrl, collaboratorsUrl: $collaboratorsUrl, commentsUrl: $commentsUrl, commitsUrl: $commitsUrl, compareUrl: $compareUrl, contentsUrl: $contentsUrl, contributorsUrl: $contributorsUrl, deploymentsUrl: $deploymentsUrl, downloadsUrl: $downloadsUrl, eventsUrl: $eventsUrl, forksUrl: $forksUrl, gitCommitsUrl: $gitCommitsUrl, gitRefsUrl: $gitRefsUrl, gitTagsUrl: $gitTagsUrl, gitUrl: $gitUrl, issueCommentUrl: $issueCommentUrl, issueEventsUrl: $issueEventsUrl, issuesUrl: $issuesUrl, keysUrl: $keysUrl, labelsUrl: $labelsUrl, languagesUrl: $languagesUrl, mergesUrl: $mergesUrl, id: $id, notificationsUrl: $notificationsUrl, pullsUrl: $pullsUrl, releasesUrl: $releasesUrl, sshUrl: $sshUrl, stargazersUrl: $stargazersUrl, statusesUrl: $statusesUrl, subscribersUrl: $subscribersUrl, subscriptionUrl: $subscriptionUrl, tagsUrl: $tagsUrl, teamsUrl: $teamsUrl, treesUrl: $treesUrl, cloneUrl: $cloneUrl, mirrorUrl: $mirrorUrl, hooksUrl: $hooksUrl, svnUrl: $svnUrl, homepage: $homepage, language: $language, forksCount: $forksCount, stargazersCount: $stargazersCount, watchersCount: $watchersCount, size: $size, defaultBranch: $defaultBranch, openIssuesCount: $openIssuesCount, watchers: $watchers, openIssues: $openIssues, hasIssues: $hasIssues, hasProjects: $hasProjects, hasWiki: $hasWiki, hasPages: $hasPages, forks: $forks, hasDiscussions: $hasDiscussions, license: $license, networkCount: $networkCount, subscribersCount: $subscribersCount, disabled: $disabled, updatedAt: $updatedAt, pushedAt: $pushedAt, createdAt: $createdAt, archived: $archived, anonymousAccessEnabled: $anonymousAccessEnabled, permissions: $permissions, allowRebaseMerge: $allowRebaseMerge, templateRepository: $templateRepository, tempCloneToken: $tempCloneToken, allowSquashMerge: $allowSquashMerge, allowAutoMerge: $allowAutoMerge, deleteBranchOnMerge: $deleteBranchOnMerge, allowMergeCommit: $allowMergeCommit, allowUpdateBranch: $allowUpdateBranch, useSquashPrTitleAsDefault: $useSquashPrTitleAsDefault, squashMergeCommitTitle: $squashMergeCommitTitle, squashMergeCommitMessage: $squashMergeCommitMessage, mergeCommitTitle: $mergeCommitTitle, mergeCommitMessage: $mergeCommitMessage, allowForking: $allowForking, webCommitSignoffRequired: $webCommitSignoffRequired, customProperties: $customProperties, pullRequestCreationPolicy: $pullRequestCreationPolicy, hasPullRequests: $hasPullRequests, organization: $organization, parent: $parent, source: $source, hasDownloads: $hasDownloads, masterBranch: $masterBranch, topics: $topics, isTemplate: $isTemplate, codeOfConduct: $codeOfConduct, securityAndAnalysis: $securityAndAnalysis, visibility: $visibility)';
}


}

/// @nodoc
abstract mixin class $FullRepositoryCopyWith<$Res>  {
  factory $FullRepositoryCopyWith(FullRepository value, $Res Function(FullRepository) _then) = _$FullRepositoryCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'milestones_url') String milestonesUrl,@JsonKey(name: 'node_id') String nodeId, String name,@JsonKey(name: 'full_name') String fullName, SimpleUser owner, bool private,@JsonKey(name: 'html_url') String htmlUrl, String? description, bool fork, String url,@JsonKey(name: 'archive_url') String archiveUrl,@JsonKey(name: 'assignees_url') String assigneesUrl,@JsonKey(name: 'blobs_url') String blobsUrl,@JsonKey(name: 'branches_url') String branchesUrl,@JsonKey(name: 'collaborators_url') String collaboratorsUrl,@JsonKey(name: 'comments_url') String commentsUrl,@JsonKey(name: 'commits_url') String commitsUrl,@JsonKey(name: 'compare_url') String compareUrl,@JsonKey(name: 'contents_url') String contentsUrl,@JsonKey(name: 'contributors_url') String contributorsUrl,@JsonKey(name: 'deployments_url') String deploymentsUrl,@JsonKey(name: 'downloads_url') String downloadsUrl,@JsonKey(name: 'events_url') String eventsUrl,@JsonKey(name: 'forks_url') String forksUrl,@JsonKey(name: 'git_commits_url') String gitCommitsUrl,@JsonKey(name: 'git_refs_url') String gitRefsUrl,@JsonKey(name: 'git_tags_url') String gitTagsUrl,@JsonKey(name: 'git_url') String gitUrl,@JsonKey(name: 'issue_comment_url') String issueCommentUrl,@JsonKey(name: 'issue_events_url') String issueEventsUrl,@JsonKey(name: 'issues_url') String issuesUrl,@JsonKey(name: 'keys_url') String keysUrl,@JsonKey(name: 'labels_url') String labelsUrl,@JsonKey(name: 'languages_url') String languagesUrl,@JsonKey(name: 'merges_url') String mergesUrl, int id,@JsonKey(name: 'notifications_url') String notificationsUrl,@JsonKey(name: 'pulls_url') String pullsUrl,@JsonKey(name: 'releases_url') String releasesUrl,@JsonKey(name: 'ssh_url') String sshUrl,@JsonKey(name: 'stargazers_url') String stargazersUrl,@JsonKey(name: 'statuses_url') String statusesUrl,@JsonKey(name: 'subscribers_url') String subscribersUrl,@JsonKey(name: 'subscription_url') String subscriptionUrl,@JsonKey(name: 'tags_url') String tagsUrl,@JsonKey(name: 'teams_url') String teamsUrl,@JsonKey(name: 'trees_url') String treesUrl,@JsonKey(name: 'clone_url') String cloneUrl,@JsonKey(name: 'mirror_url') String? mirrorUrl,@JsonKey(name: 'hooks_url') String hooksUrl,@JsonKey(name: 'svn_url') String svnUrl, String? homepage,@JsonKey(name: 'Language') String? language,@JsonKey(name: 'forks_count') int forksCount,@JsonKey(name: 'stargazers_count') int stargazersCount,@JsonKey(name: 'watchers_count') int watchersCount, int size,@JsonKey(name: 'default_branch') String defaultBranch,@JsonKey(name: 'open_issues_count') int openIssuesCount, int watchers,@JsonKey(name: 'open_issues') int openIssues,@JsonKey(name: 'has_issues') bool hasIssues,@JsonKey(name: 'has_projects') bool hasProjects,@JsonKey(name: 'has_wiki') bool hasWiki,@JsonKey(name: 'has_pages') bool hasPages, int forks,@JsonKey(name: 'has_discussions') bool hasDiscussions,@JsonKey(name: 'License') NullableLicenseSimple? license,@JsonKey(name: 'network_count') int networkCount,@JsonKey(name: 'subscribers_count') int subscribersCount, bool disabled,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'pushed_at') DateTime pushedAt,@JsonKey(name: 'created_at') DateTime createdAt, bool archived,@JsonKey(name: 'anonymous_access_enabled') bool anonymousAccessEnabled, Permissions11? permissions,@JsonKey(name: 'allow_rebase_merge') bool? allowRebaseMerge,@JsonKey(name: 'template_repository') NullableRepository? templateRepository,@JsonKey(name: 'temp_clone_token') String? tempCloneToken,@JsonKey(name: 'allow_squash_merge') bool? allowSquashMerge,@JsonKey(name: 'allow_auto_merge') bool? allowAutoMerge,@JsonKey(name: 'delete_branch_on_merge') bool? deleteBranchOnMerge,@JsonKey(name: 'allow_merge_commit') bool? allowMergeCommit,@JsonKey(name: 'allow_update_branch') bool? allowUpdateBranch,@JsonKey(name: 'use_squash_pr_title_as_default') bool? useSquashPrTitleAsDefault,@JsonKey(name: 'squash_merge_commit_title') FullRepositorySquashMergeCommitTitle? squashMergeCommitTitle,@JsonKey(name: 'squash_merge_commit_message') FullRepositorySquashMergeCommitMessage? squashMergeCommitMessage,@JsonKey(name: 'merge_commit_title') FullRepositoryMergeCommitTitle? mergeCommitTitle,@JsonKey(name: 'merge_commit_message') FullRepositoryMergeCommitMessage? mergeCommitMessage,@JsonKey(name: 'allow_forking') bool? allowForking,@JsonKey(name: 'web_commit_signoff_required') bool? webCommitSignoffRequired,@JsonKey(name: 'custom_properties') dynamic customProperties,@JsonKey(name: 'pull_request_creation_policy') FullRepositoryPullRequestCreationPolicy? pullRequestCreationPolicy,@JsonKey(name: 'has_pull_requests') bool? hasPullRequests, NullableSimpleUser? organization, Repository? parent, Repository? source,@JsonKey(name: 'has_downloads') bool? hasDownloads,@JsonKey(name: 'master_branch') String? masterBranch, List<String>? topics,@JsonKey(name: 'is_template') bool? isTemplate,@JsonKey(name: 'code_of_conduct') CodeOfConductSimple? codeOfConduct,@JsonKey(name: 'security_and_analysis') SecurityAndAnalysis? securityAndAnalysis, String? visibility
});


$SimpleUserCopyWith<$Res> get owner;$NullableLicenseSimpleCopyWith<$Res>? get license;$Permissions11CopyWith<$Res>? get permissions;$NullableRepositoryCopyWith<$Res>? get templateRepository;$NullableSimpleUserCopyWith<$Res>? get organization;$RepositoryCopyWith<$Res>? get parent;$RepositoryCopyWith<$Res>? get source;$CodeOfConductSimpleCopyWith<$Res>? get codeOfConduct;$SecurityAndAnalysisCopyWith<$Res>? get securityAndAnalysis;

}
/// @nodoc
class _$FullRepositoryCopyWithImpl<$Res>
    implements $FullRepositoryCopyWith<$Res> {
  _$FullRepositoryCopyWithImpl(this._self, this._then);

  final FullRepository _self;
  final $Res Function(FullRepository) _then;

/// Create a copy of FullRepository
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? milestonesUrl = null,Object? nodeId = null,Object? name = null,Object? fullName = null,Object? owner = null,Object? private = null,Object? htmlUrl = null,Object? description = freezed,Object? fork = null,Object? url = null,Object? archiveUrl = null,Object? assigneesUrl = null,Object? blobsUrl = null,Object? branchesUrl = null,Object? collaboratorsUrl = null,Object? commentsUrl = null,Object? commitsUrl = null,Object? compareUrl = null,Object? contentsUrl = null,Object? contributorsUrl = null,Object? deploymentsUrl = null,Object? downloadsUrl = null,Object? eventsUrl = null,Object? forksUrl = null,Object? gitCommitsUrl = null,Object? gitRefsUrl = null,Object? gitTagsUrl = null,Object? gitUrl = null,Object? issueCommentUrl = null,Object? issueEventsUrl = null,Object? issuesUrl = null,Object? keysUrl = null,Object? labelsUrl = null,Object? languagesUrl = null,Object? mergesUrl = null,Object? id = null,Object? notificationsUrl = null,Object? pullsUrl = null,Object? releasesUrl = null,Object? sshUrl = null,Object? stargazersUrl = null,Object? statusesUrl = null,Object? subscribersUrl = null,Object? subscriptionUrl = null,Object? tagsUrl = null,Object? teamsUrl = null,Object? treesUrl = null,Object? cloneUrl = null,Object? mirrorUrl = freezed,Object? hooksUrl = null,Object? svnUrl = null,Object? homepage = freezed,Object? language = freezed,Object? forksCount = null,Object? stargazersCount = null,Object? watchersCount = null,Object? size = null,Object? defaultBranch = null,Object? openIssuesCount = null,Object? watchers = null,Object? openIssues = null,Object? hasIssues = null,Object? hasProjects = null,Object? hasWiki = null,Object? hasPages = null,Object? forks = null,Object? hasDiscussions = null,Object? license = freezed,Object? networkCount = null,Object? subscribersCount = null,Object? disabled = null,Object? updatedAt = null,Object? pushedAt = null,Object? createdAt = null,Object? archived = null,Object? anonymousAccessEnabled = null,Object? permissions = freezed,Object? allowRebaseMerge = freezed,Object? templateRepository = freezed,Object? tempCloneToken = freezed,Object? allowSquashMerge = freezed,Object? allowAutoMerge = freezed,Object? deleteBranchOnMerge = freezed,Object? allowMergeCommit = freezed,Object? allowUpdateBranch = freezed,Object? useSquashPrTitleAsDefault = freezed,Object? squashMergeCommitTitle = freezed,Object? squashMergeCommitMessage = freezed,Object? mergeCommitTitle = freezed,Object? mergeCommitMessage = freezed,Object? allowForking = freezed,Object? webCommitSignoffRequired = freezed,Object? customProperties = freezed,Object? pullRequestCreationPolicy = freezed,Object? hasPullRequests = freezed,Object? organization = freezed,Object? parent = freezed,Object? source = freezed,Object? hasDownloads = freezed,Object? masterBranch = freezed,Object? topics = freezed,Object? isTemplate = freezed,Object? codeOfConduct = freezed,Object? securityAndAnalysis = freezed,Object? visibility = freezed,}) {
  return _then(_self.copyWith(
milestonesUrl: null == milestonesUrl ? _self.milestonesUrl : milestonesUrl // ignore: cast_nullable_to_non_nullable
as String,nodeId: null == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as SimpleUser,private: null == private ? _self.private : private // ignore: cast_nullable_to_non_nullable
as bool,htmlUrl: null == htmlUrl ? _self.htmlUrl : htmlUrl // ignore: cast_nullable_to_non_nullable
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
as String,issueEventsUrl: null == issueEventsUrl ? _self.issueEventsUrl : issueEventsUrl // ignore: cast_nullable_to_non_nullable
as String,issuesUrl: null == issuesUrl ? _self.issuesUrl : issuesUrl // ignore: cast_nullable_to_non_nullable
as String,keysUrl: null == keysUrl ? _self.keysUrl : keysUrl // ignore: cast_nullable_to_non_nullable
as String,labelsUrl: null == labelsUrl ? _self.labelsUrl : labelsUrl // ignore: cast_nullable_to_non_nullable
as String,languagesUrl: null == languagesUrl ? _self.languagesUrl : languagesUrl // ignore: cast_nullable_to_non_nullable
as String,mergesUrl: null == mergesUrl ? _self.mergesUrl : mergesUrl // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,notificationsUrl: null == notificationsUrl ? _self.notificationsUrl : notificationsUrl // ignore: cast_nullable_to_non_nullable
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
as int,watchers: null == watchers ? _self.watchers : watchers // ignore: cast_nullable_to_non_nullable
as int,openIssues: null == openIssues ? _self.openIssues : openIssues // ignore: cast_nullable_to_non_nullable
as int,hasIssues: null == hasIssues ? _self.hasIssues : hasIssues // ignore: cast_nullable_to_non_nullable
as bool,hasProjects: null == hasProjects ? _self.hasProjects : hasProjects // ignore: cast_nullable_to_non_nullable
as bool,hasWiki: null == hasWiki ? _self.hasWiki : hasWiki // ignore: cast_nullable_to_non_nullable
as bool,hasPages: null == hasPages ? _self.hasPages : hasPages // ignore: cast_nullable_to_non_nullable
as bool,forks: null == forks ? _self.forks : forks // ignore: cast_nullable_to_non_nullable
as int,hasDiscussions: null == hasDiscussions ? _self.hasDiscussions : hasDiscussions // ignore: cast_nullable_to_non_nullable
as bool,license: freezed == license ? _self.license : license // ignore: cast_nullable_to_non_nullable
as NullableLicenseSimple?,networkCount: null == networkCount ? _self.networkCount : networkCount // ignore: cast_nullable_to_non_nullable
as int,subscribersCount: null == subscribersCount ? _self.subscribersCount : subscribersCount // ignore: cast_nullable_to_non_nullable
as int,disabled: null == disabled ? _self.disabled : disabled // ignore: cast_nullable_to_non_nullable
as bool,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,pushedAt: null == pushedAt ? _self.pushedAt : pushedAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,archived: null == archived ? _self.archived : archived // ignore: cast_nullable_to_non_nullable
as bool,anonymousAccessEnabled: null == anonymousAccessEnabled ? _self.anonymousAccessEnabled : anonymousAccessEnabled // ignore: cast_nullable_to_non_nullable
as bool,permissions: freezed == permissions ? _self.permissions : permissions // ignore: cast_nullable_to_non_nullable
as Permissions11?,allowRebaseMerge: freezed == allowRebaseMerge ? _self.allowRebaseMerge : allowRebaseMerge // ignore: cast_nullable_to_non_nullable
as bool?,templateRepository: freezed == templateRepository ? _self.templateRepository : templateRepository // ignore: cast_nullable_to_non_nullable
as NullableRepository?,tempCloneToken: freezed == tempCloneToken ? _self.tempCloneToken : tempCloneToken // ignore: cast_nullable_to_non_nullable
as String?,allowSquashMerge: freezed == allowSquashMerge ? _self.allowSquashMerge : allowSquashMerge // ignore: cast_nullable_to_non_nullable
as bool?,allowAutoMerge: freezed == allowAutoMerge ? _self.allowAutoMerge : allowAutoMerge // ignore: cast_nullable_to_non_nullable
as bool?,deleteBranchOnMerge: freezed == deleteBranchOnMerge ? _self.deleteBranchOnMerge : deleteBranchOnMerge // ignore: cast_nullable_to_non_nullable
as bool?,allowMergeCommit: freezed == allowMergeCommit ? _self.allowMergeCommit : allowMergeCommit // ignore: cast_nullable_to_non_nullable
as bool?,allowUpdateBranch: freezed == allowUpdateBranch ? _self.allowUpdateBranch : allowUpdateBranch // ignore: cast_nullable_to_non_nullable
as bool?,useSquashPrTitleAsDefault: freezed == useSquashPrTitleAsDefault ? _self.useSquashPrTitleAsDefault : useSquashPrTitleAsDefault // ignore: cast_nullable_to_non_nullable
as bool?,squashMergeCommitTitle: freezed == squashMergeCommitTitle ? _self.squashMergeCommitTitle : squashMergeCommitTitle // ignore: cast_nullable_to_non_nullable
as FullRepositorySquashMergeCommitTitle?,squashMergeCommitMessage: freezed == squashMergeCommitMessage ? _self.squashMergeCommitMessage : squashMergeCommitMessage // ignore: cast_nullable_to_non_nullable
as FullRepositorySquashMergeCommitMessage?,mergeCommitTitle: freezed == mergeCommitTitle ? _self.mergeCommitTitle : mergeCommitTitle // ignore: cast_nullable_to_non_nullable
as FullRepositoryMergeCommitTitle?,mergeCommitMessage: freezed == mergeCommitMessage ? _self.mergeCommitMessage : mergeCommitMessage // ignore: cast_nullable_to_non_nullable
as FullRepositoryMergeCommitMessage?,allowForking: freezed == allowForking ? _self.allowForking : allowForking // ignore: cast_nullable_to_non_nullable
as bool?,webCommitSignoffRequired: freezed == webCommitSignoffRequired ? _self.webCommitSignoffRequired : webCommitSignoffRequired // ignore: cast_nullable_to_non_nullable
as bool?,customProperties: freezed == customProperties ? _self.customProperties : customProperties // ignore: cast_nullable_to_non_nullable
as dynamic,pullRequestCreationPolicy: freezed == pullRequestCreationPolicy ? _self.pullRequestCreationPolicy : pullRequestCreationPolicy // ignore: cast_nullable_to_non_nullable
as FullRepositoryPullRequestCreationPolicy?,hasPullRequests: freezed == hasPullRequests ? _self.hasPullRequests : hasPullRequests // ignore: cast_nullable_to_non_nullable
as bool?,organization: freezed == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as NullableSimpleUser?,parent: freezed == parent ? _self.parent : parent // ignore: cast_nullable_to_non_nullable
as Repository?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as Repository?,hasDownloads: freezed == hasDownloads ? _self.hasDownloads : hasDownloads // ignore: cast_nullable_to_non_nullable
as bool?,masterBranch: freezed == masterBranch ? _self.masterBranch : masterBranch // ignore: cast_nullable_to_non_nullable
as String?,topics: freezed == topics ? _self.topics : topics // ignore: cast_nullable_to_non_nullable
as List<String>?,isTemplate: freezed == isTemplate ? _self.isTemplate : isTemplate // ignore: cast_nullable_to_non_nullable
as bool?,codeOfConduct: freezed == codeOfConduct ? _self.codeOfConduct : codeOfConduct // ignore: cast_nullable_to_non_nullable
as CodeOfConductSimple?,securityAndAnalysis: freezed == securityAndAnalysis ? _self.securityAndAnalysis : securityAndAnalysis // ignore: cast_nullable_to_non_nullable
as SecurityAndAnalysis?,visibility: freezed == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of FullRepository
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SimpleUserCopyWith<$Res> get owner {
  
  return $SimpleUserCopyWith<$Res>(_self.owner, (value) {
    return _then(_self.copyWith(owner: value));
  });
}/// Create a copy of FullRepository
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
}/// Create a copy of FullRepository
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Permissions11CopyWith<$Res>? get permissions {
    if (_self.permissions == null) {
    return null;
  }

  return $Permissions11CopyWith<$Res>(_self.permissions!, (value) {
    return _then(_self.copyWith(permissions: value));
  });
}/// Create a copy of FullRepository
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NullableRepositoryCopyWith<$Res>? get templateRepository {
    if (_self.templateRepository == null) {
    return null;
  }

  return $NullableRepositoryCopyWith<$Res>(_self.templateRepository!, (value) {
    return _then(_self.copyWith(templateRepository: value));
  });
}/// Create a copy of FullRepository
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NullableSimpleUserCopyWith<$Res>? get organization {
    if (_self.organization == null) {
    return null;
  }

  return $NullableSimpleUserCopyWith<$Res>(_self.organization!, (value) {
    return _then(_self.copyWith(organization: value));
  });
}/// Create a copy of FullRepository
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RepositoryCopyWith<$Res>? get parent {
    if (_self.parent == null) {
    return null;
  }

  return $RepositoryCopyWith<$Res>(_self.parent!, (value) {
    return _then(_self.copyWith(parent: value));
  });
}/// Create a copy of FullRepository
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RepositoryCopyWith<$Res>? get source {
    if (_self.source == null) {
    return null;
  }

  return $RepositoryCopyWith<$Res>(_self.source!, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of FullRepository
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CodeOfConductSimpleCopyWith<$Res>? get codeOfConduct {
    if (_self.codeOfConduct == null) {
    return null;
  }

  return $CodeOfConductSimpleCopyWith<$Res>(_self.codeOfConduct!, (value) {
    return _then(_self.copyWith(codeOfConduct: value));
  });
}/// Create a copy of FullRepository
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SecurityAndAnalysisCopyWith<$Res>? get securityAndAnalysis {
    if (_self.securityAndAnalysis == null) {
    return null;
  }

  return $SecurityAndAnalysisCopyWith<$Res>(_self.securityAndAnalysis!, (value) {
    return _then(_self.copyWith(securityAndAnalysis: value));
  });
}
}


/// Adds pattern-matching-related methods to [FullRepository].
extension FullRepositoryPatterns on FullRepository {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FullRepository value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FullRepository() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FullRepository value)  $default,){
final _that = this;
switch (_that) {
case _FullRepository():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FullRepository value)?  $default,){
final _that = this;
switch (_that) {
case _FullRepository() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'milestones_url')  String milestonesUrl, @JsonKey(name: 'node_id')  String nodeId,  String name, @JsonKey(name: 'full_name')  String fullName,  SimpleUser owner,  bool private, @JsonKey(name: 'html_url')  String htmlUrl,  String? description,  bool fork,  String url, @JsonKey(name: 'archive_url')  String archiveUrl, @JsonKey(name: 'assignees_url')  String assigneesUrl, @JsonKey(name: 'blobs_url')  String blobsUrl, @JsonKey(name: 'branches_url')  String branchesUrl, @JsonKey(name: 'collaborators_url')  String collaboratorsUrl, @JsonKey(name: 'comments_url')  String commentsUrl, @JsonKey(name: 'commits_url')  String commitsUrl, @JsonKey(name: 'compare_url')  String compareUrl, @JsonKey(name: 'contents_url')  String contentsUrl, @JsonKey(name: 'contributors_url')  String contributorsUrl, @JsonKey(name: 'deployments_url')  String deploymentsUrl, @JsonKey(name: 'downloads_url')  String downloadsUrl, @JsonKey(name: 'events_url')  String eventsUrl, @JsonKey(name: 'forks_url')  String forksUrl, @JsonKey(name: 'git_commits_url')  String gitCommitsUrl, @JsonKey(name: 'git_refs_url')  String gitRefsUrl, @JsonKey(name: 'git_tags_url')  String gitTagsUrl, @JsonKey(name: 'git_url')  String gitUrl, @JsonKey(name: 'issue_comment_url')  String issueCommentUrl, @JsonKey(name: 'issue_events_url')  String issueEventsUrl, @JsonKey(name: 'issues_url')  String issuesUrl, @JsonKey(name: 'keys_url')  String keysUrl, @JsonKey(name: 'labels_url')  String labelsUrl, @JsonKey(name: 'languages_url')  String languagesUrl, @JsonKey(name: 'merges_url')  String mergesUrl,  int id, @JsonKey(name: 'notifications_url')  String notificationsUrl, @JsonKey(name: 'pulls_url')  String pullsUrl, @JsonKey(name: 'releases_url')  String releasesUrl, @JsonKey(name: 'ssh_url')  String sshUrl, @JsonKey(name: 'stargazers_url')  String stargazersUrl, @JsonKey(name: 'statuses_url')  String statusesUrl, @JsonKey(name: 'subscribers_url')  String subscribersUrl, @JsonKey(name: 'subscription_url')  String subscriptionUrl, @JsonKey(name: 'tags_url')  String tagsUrl, @JsonKey(name: 'teams_url')  String teamsUrl, @JsonKey(name: 'trees_url')  String treesUrl, @JsonKey(name: 'clone_url')  String cloneUrl, @JsonKey(name: 'mirror_url')  String? mirrorUrl, @JsonKey(name: 'hooks_url')  String hooksUrl, @JsonKey(name: 'svn_url')  String svnUrl,  String? homepage, @JsonKey(name: 'Language')  String? language, @JsonKey(name: 'forks_count')  int forksCount, @JsonKey(name: 'stargazers_count')  int stargazersCount, @JsonKey(name: 'watchers_count')  int watchersCount,  int size, @JsonKey(name: 'default_branch')  String defaultBranch, @JsonKey(name: 'open_issues_count')  int openIssuesCount,  int watchers, @JsonKey(name: 'open_issues')  int openIssues, @JsonKey(name: 'has_issues')  bool hasIssues, @JsonKey(name: 'has_projects')  bool hasProjects, @JsonKey(name: 'has_wiki')  bool hasWiki, @JsonKey(name: 'has_pages')  bool hasPages,  int forks, @JsonKey(name: 'has_discussions')  bool hasDiscussions, @JsonKey(name: 'License')  NullableLicenseSimple? license, @JsonKey(name: 'network_count')  int networkCount, @JsonKey(name: 'subscribers_count')  int subscribersCount,  bool disabled, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'pushed_at')  DateTime pushedAt, @JsonKey(name: 'created_at')  DateTime createdAt,  bool archived, @JsonKey(name: 'anonymous_access_enabled')  bool anonymousAccessEnabled,  Permissions11? permissions, @JsonKey(name: 'allow_rebase_merge')  bool? allowRebaseMerge, @JsonKey(name: 'template_repository')  NullableRepository? templateRepository, @JsonKey(name: 'temp_clone_token')  String? tempCloneToken, @JsonKey(name: 'allow_squash_merge')  bool? allowSquashMerge, @JsonKey(name: 'allow_auto_merge')  bool? allowAutoMerge, @JsonKey(name: 'delete_branch_on_merge')  bool? deleteBranchOnMerge, @JsonKey(name: 'allow_merge_commit')  bool? allowMergeCommit, @JsonKey(name: 'allow_update_branch')  bool? allowUpdateBranch, @JsonKey(name: 'use_squash_pr_title_as_default')  bool? useSquashPrTitleAsDefault, @JsonKey(name: 'squash_merge_commit_title')  FullRepositorySquashMergeCommitTitle? squashMergeCommitTitle, @JsonKey(name: 'squash_merge_commit_message')  FullRepositorySquashMergeCommitMessage? squashMergeCommitMessage, @JsonKey(name: 'merge_commit_title')  FullRepositoryMergeCommitTitle? mergeCommitTitle, @JsonKey(name: 'merge_commit_message')  FullRepositoryMergeCommitMessage? mergeCommitMessage, @JsonKey(name: 'allow_forking')  bool? allowForking, @JsonKey(name: 'web_commit_signoff_required')  bool? webCommitSignoffRequired, @JsonKey(name: 'custom_properties')  dynamic customProperties, @JsonKey(name: 'pull_request_creation_policy')  FullRepositoryPullRequestCreationPolicy? pullRequestCreationPolicy, @JsonKey(name: 'has_pull_requests')  bool? hasPullRequests,  NullableSimpleUser? organization,  Repository? parent,  Repository? source, @JsonKey(name: 'has_downloads')  bool? hasDownloads, @JsonKey(name: 'master_branch')  String? masterBranch,  List<String>? topics, @JsonKey(name: 'is_template')  bool? isTemplate, @JsonKey(name: 'code_of_conduct')  CodeOfConductSimple? codeOfConduct, @JsonKey(name: 'security_and_analysis')  SecurityAndAnalysis? securityAndAnalysis,  String? visibility)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FullRepository() when $default != null:
return $default(_that.milestonesUrl,_that.nodeId,_that.name,_that.fullName,_that.owner,_that.private,_that.htmlUrl,_that.description,_that.fork,_that.url,_that.archiveUrl,_that.assigneesUrl,_that.blobsUrl,_that.branchesUrl,_that.collaboratorsUrl,_that.commentsUrl,_that.commitsUrl,_that.compareUrl,_that.contentsUrl,_that.contributorsUrl,_that.deploymentsUrl,_that.downloadsUrl,_that.eventsUrl,_that.forksUrl,_that.gitCommitsUrl,_that.gitRefsUrl,_that.gitTagsUrl,_that.gitUrl,_that.issueCommentUrl,_that.issueEventsUrl,_that.issuesUrl,_that.keysUrl,_that.labelsUrl,_that.languagesUrl,_that.mergesUrl,_that.id,_that.notificationsUrl,_that.pullsUrl,_that.releasesUrl,_that.sshUrl,_that.stargazersUrl,_that.statusesUrl,_that.subscribersUrl,_that.subscriptionUrl,_that.tagsUrl,_that.teamsUrl,_that.treesUrl,_that.cloneUrl,_that.mirrorUrl,_that.hooksUrl,_that.svnUrl,_that.homepage,_that.language,_that.forksCount,_that.stargazersCount,_that.watchersCount,_that.size,_that.defaultBranch,_that.openIssuesCount,_that.watchers,_that.openIssues,_that.hasIssues,_that.hasProjects,_that.hasWiki,_that.hasPages,_that.forks,_that.hasDiscussions,_that.license,_that.networkCount,_that.subscribersCount,_that.disabled,_that.updatedAt,_that.pushedAt,_that.createdAt,_that.archived,_that.anonymousAccessEnabled,_that.permissions,_that.allowRebaseMerge,_that.templateRepository,_that.tempCloneToken,_that.allowSquashMerge,_that.allowAutoMerge,_that.deleteBranchOnMerge,_that.allowMergeCommit,_that.allowUpdateBranch,_that.useSquashPrTitleAsDefault,_that.squashMergeCommitTitle,_that.squashMergeCommitMessage,_that.mergeCommitTitle,_that.mergeCommitMessage,_that.allowForking,_that.webCommitSignoffRequired,_that.customProperties,_that.pullRequestCreationPolicy,_that.hasPullRequests,_that.organization,_that.parent,_that.source,_that.hasDownloads,_that.masterBranch,_that.topics,_that.isTemplate,_that.codeOfConduct,_that.securityAndAnalysis,_that.visibility);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'milestones_url')  String milestonesUrl, @JsonKey(name: 'node_id')  String nodeId,  String name, @JsonKey(name: 'full_name')  String fullName,  SimpleUser owner,  bool private, @JsonKey(name: 'html_url')  String htmlUrl,  String? description,  bool fork,  String url, @JsonKey(name: 'archive_url')  String archiveUrl, @JsonKey(name: 'assignees_url')  String assigneesUrl, @JsonKey(name: 'blobs_url')  String blobsUrl, @JsonKey(name: 'branches_url')  String branchesUrl, @JsonKey(name: 'collaborators_url')  String collaboratorsUrl, @JsonKey(name: 'comments_url')  String commentsUrl, @JsonKey(name: 'commits_url')  String commitsUrl, @JsonKey(name: 'compare_url')  String compareUrl, @JsonKey(name: 'contents_url')  String contentsUrl, @JsonKey(name: 'contributors_url')  String contributorsUrl, @JsonKey(name: 'deployments_url')  String deploymentsUrl, @JsonKey(name: 'downloads_url')  String downloadsUrl, @JsonKey(name: 'events_url')  String eventsUrl, @JsonKey(name: 'forks_url')  String forksUrl, @JsonKey(name: 'git_commits_url')  String gitCommitsUrl, @JsonKey(name: 'git_refs_url')  String gitRefsUrl, @JsonKey(name: 'git_tags_url')  String gitTagsUrl, @JsonKey(name: 'git_url')  String gitUrl, @JsonKey(name: 'issue_comment_url')  String issueCommentUrl, @JsonKey(name: 'issue_events_url')  String issueEventsUrl, @JsonKey(name: 'issues_url')  String issuesUrl, @JsonKey(name: 'keys_url')  String keysUrl, @JsonKey(name: 'labels_url')  String labelsUrl, @JsonKey(name: 'languages_url')  String languagesUrl, @JsonKey(name: 'merges_url')  String mergesUrl,  int id, @JsonKey(name: 'notifications_url')  String notificationsUrl, @JsonKey(name: 'pulls_url')  String pullsUrl, @JsonKey(name: 'releases_url')  String releasesUrl, @JsonKey(name: 'ssh_url')  String sshUrl, @JsonKey(name: 'stargazers_url')  String stargazersUrl, @JsonKey(name: 'statuses_url')  String statusesUrl, @JsonKey(name: 'subscribers_url')  String subscribersUrl, @JsonKey(name: 'subscription_url')  String subscriptionUrl, @JsonKey(name: 'tags_url')  String tagsUrl, @JsonKey(name: 'teams_url')  String teamsUrl, @JsonKey(name: 'trees_url')  String treesUrl, @JsonKey(name: 'clone_url')  String cloneUrl, @JsonKey(name: 'mirror_url')  String? mirrorUrl, @JsonKey(name: 'hooks_url')  String hooksUrl, @JsonKey(name: 'svn_url')  String svnUrl,  String? homepage, @JsonKey(name: 'Language')  String? language, @JsonKey(name: 'forks_count')  int forksCount, @JsonKey(name: 'stargazers_count')  int stargazersCount, @JsonKey(name: 'watchers_count')  int watchersCount,  int size, @JsonKey(name: 'default_branch')  String defaultBranch, @JsonKey(name: 'open_issues_count')  int openIssuesCount,  int watchers, @JsonKey(name: 'open_issues')  int openIssues, @JsonKey(name: 'has_issues')  bool hasIssues, @JsonKey(name: 'has_projects')  bool hasProjects, @JsonKey(name: 'has_wiki')  bool hasWiki, @JsonKey(name: 'has_pages')  bool hasPages,  int forks, @JsonKey(name: 'has_discussions')  bool hasDiscussions, @JsonKey(name: 'License')  NullableLicenseSimple? license, @JsonKey(name: 'network_count')  int networkCount, @JsonKey(name: 'subscribers_count')  int subscribersCount,  bool disabled, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'pushed_at')  DateTime pushedAt, @JsonKey(name: 'created_at')  DateTime createdAt,  bool archived, @JsonKey(name: 'anonymous_access_enabled')  bool anonymousAccessEnabled,  Permissions11? permissions, @JsonKey(name: 'allow_rebase_merge')  bool? allowRebaseMerge, @JsonKey(name: 'template_repository')  NullableRepository? templateRepository, @JsonKey(name: 'temp_clone_token')  String? tempCloneToken, @JsonKey(name: 'allow_squash_merge')  bool? allowSquashMerge, @JsonKey(name: 'allow_auto_merge')  bool? allowAutoMerge, @JsonKey(name: 'delete_branch_on_merge')  bool? deleteBranchOnMerge, @JsonKey(name: 'allow_merge_commit')  bool? allowMergeCommit, @JsonKey(name: 'allow_update_branch')  bool? allowUpdateBranch, @JsonKey(name: 'use_squash_pr_title_as_default')  bool? useSquashPrTitleAsDefault, @JsonKey(name: 'squash_merge_commit_title')  FullRepositorySquashMergeCommitTitle? squashMergeCommitTitle, @JsonKey(name: 'squash_merge_commit_message')  FullRepositorySquashMergeCommitMessage? squashMergeCommitMessage, @JsonKey(name: 'merge_commit_title')  FullRepositoryMergeCommitTitle? mergeCommitTitle, @JsonKey(name: 'merge_commit_message')  FullRepositoryMergeCommitMessage? mergeCommitMessage, @JsonKey(name: 'allow_forking')  bool? allowForking, @JsonKey(name: 'web_commit_signoff_required')  bool? webCommitSignoffRequired, @JsonKey(name: 'custom_properties')  dynamic customProperties, @JsonKey(name: 'pull_request_creation_policy')  FullRepositoryPullRequestCreationPolicy? pullRequestCreationPolicy, @JsonKey(name: 'has_pull_requests')  bool? hasPullRequests,  NullableSimpleUser? organization,  Repository? parent,  Repository? source, @JsonKey(name: 'has_downloads')  bool? hasDownloads, @JsonKey(name: 'master_branch')  String? masterBranch,  List<String>? topics, @JsonKey(name: 'is_template')  bool? isTemplate, @JsonKey(name: 'code_of_conduct')  CodeOfConductSimple? codeOfConduct, @JsonKey(name: 'security_and_analysis')  SecurityAndAnalysis? securityAndAnalysis,  String? visibility)  $default,) {final _that = this;
switch (_that) {
case _FullRepository():
return $default(_that.milestonesUrl,_that.nodeId,_that.name,_that.fullName,_that.owner,_that.private,_that.htmlUrl,_that.description,_that.fork,_that.url,_that.archiveUrl,_that.assigneesUrl,_that.blobsUrl,_that.branchesUrl,_that.collaboratorsUrl,_that.commentsUrl,_that.commitsUrl,_that.compareUrl,_that.contentsUrl,_that.contributorsUrl,_that.deploymentsUrl,_that.downloadsUrl,_that.eventsUrl,_that.forksUrl,_that.gitCommitsUrl,_that.gitRefsUrl,_that.gitTagsUrl,_that.gitUrl,_that.issueCommentUrl,_that.issueEventsUrl,_that.issuesUrl,_that.keysUrl,_that.labelsUrl,_that.languagesUrl,_that.mergesUrl,_that.id,_that.notificationsUrl,_that.pullsUrl,_that.releasesUrl,_that.sshUrl,_that.stargazersUrl,_that.statusesUrl,_that.subscribersUrl,_that.subscriptionUrl,_that.tagsUrl,_that.teamsUrl,_that.treesUrl,_that.cloneUrl,_that.mirrorUrl,_that.hooksUrl,_that.svnUrl,_that.homepage,_that.language,_that.forksCount,_that.stargazersCount,_that.watchersCount,_that.size,_that.defaultBranch,_that.openIssuesCount,_that.watchers,_that.openIssues,_that.hasIssues,_that.hasProjects,_that.hasWiki,_that.hasPages,_that.forks,_that.hasDiscussions,_that.license,_that.networkCount,_that.subscribersCount,_that.disabled,_that.updatedAt,_that.pushedAt,_that.createdAt,_that.archived,_that.anonymousAccessEnabled,_that.permissions,_that.allowRebaseMerge,_that.templateRepository,_that.tempCloneToken,_that.allowSquashMerge,_that.allowAutoMerge,_that.deleteBranchOnMerge,_that.allowMergeCommit,_that.allowUpdateBranch,_that.useSquashPrTitleAsDefault,_that.squashMergeCommitTitle,_that.squashMergeCommitMessage,_that.mergeCommitTitle,_that.mergeCommitMessage,_that.allowForking,_that.webCommitSignoffRequired,_that.customProperties,_that.pullRequestCreationPolicy,_that.hasPullRequests,_that.organization,_that.parent,_that.source,_that.hasDownloads,_that.masterBranch,_that.topics,_that.isTemplate,_that.codeOfConduct,_that.securityAndAnalysis,_that.visibility);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'milestones_url')  String milestonesUrl, @JsonKey(name: 'node_id')  String nodeId,  String name, @JsonKey(name: 'full_name')  String fullName,  SimpleUser owner,  bool private, @JsonKey(name: 'html_url')  String htmlUrl,  String? description,  bool fork,  String url, @JsonKey(name: 'archive_url')  String archiveUrl, @JsonKey(name: 'assignees_url')  String assigneesUrl, @JsonKey(name: 'blobs_url')  String blobsUrl, @JsonKey(name: 'branches_url')  String branchesUrl, @JsonKey(name: 'collaborators_url')  String collaboratorsUrl, @JsonKey(name: 'comments_url')  String commentsUrl, @JsonKey(name: 'commits_url')  String commitsUrl, @JsonKey(name: 'compare_url')  String compareUrl, @JsonKey(name: 'contents_url')  String contentsUrl, @JsonKey(name: 'contributors_url')  String contributorsUrl, @JsonKey(name: 'deployments_url')  String deploymentsUrl, @JsonKey(name: 'downloads_url')  String downloadsUrl, @JsonKey(name: 'events_url')  String eventsUrl, @JsonKey(name: 'forks_url')  String forksUrl, @JsonKey(name: 'git_commits_url')  String gitCommitsUrl, @JsonKey(name: 'git_refs_url')  String gitRefsUrl, @JsonKey(name: 'git_tags_url')  String gitTagsUrl, @JsonKey(name: 'git_url')  String gitUrl, @JsonKey(name: 'issue_comment_url')  String issueCommentUrl, @JsonKey(name: 'issue_events_url')  String issueEventsUrl, @JsonKey(name: 'issues_url')  String issuesUrl, @JsonKey(name: 'keys_url')  String keysUrl, @JsonKey(name: 'labels_url')  String labelsUrl, @JsonKey(name: 'languages_url')  String languagesUrl, @JsonKey(name: 'merges_url')  String mergesUrl,  int id, @JsonKey(name: 'notifications_url')  String notificationsUrl, @JsonKey(name: 'pulls_url')  String pullsUrl, @JsonKey(name: 'releases_url')  String releasesUrl, @JsonKey(name: 'ssh_url')  String sshUrl, @JsonKey(name: 'stargazers_url')  String stargazersUrl, @JsonKey(name: 'statuses_url')  String statusesUrl, @JsonKey(name: 'subscribers_url')  String subscribersUrl, @JsonKey(name: 'subscription_url')  String subscriptionUrl, @JsonKey(name: 'tags_url')  String tagsUrl, @JsonKey(name: 'teams_url')  String teamsUrl, @JsonKey(name: 'trees_url')  String treesUrl, @JsonKey(name: 'clone_url')  String cloneUrl, @JsonKey(name: 'mirror_url')  String? mirrorUrl, @JsonKey(name: 'hooks_url')  String hooksUrl, @JsonKey(name: 'svn_url')  String svnUrl,  String? homepage, @JsonKey(name: 'Language')  String? language, @JsonKey(name: 'forks_count')  int forksCount, @JsonKey(name: 'stargazers_count')  int stargazersCount, @JsonKey(name: 'watchers_count')  int watchersCount,  int size, @JsonKey(name: 'default_branch')  String defaultBranch, @JsonKey(name: 'open_issues_count')  int openIssuesCount,  int watchers, @JsonKey(name: 'open_issues')  int openIssues, @JsonKey(name: 'has_issues')  bool hasIssues, @JsonKey(name: 'has_projects')  bool hasProjects, @JsonKey(name: 'has_wiki')  bool hasWiki, @JsonKey(name: 'has_pages')  bool hasPages,  int forks, @JsonKey(name: 'has_discussions')  bool hasDiscussions, @JsonKey(name: 'License')  NullableLicenseSimple? license, @JsonKey(name: 'network_count')  int networkCount, @JsonKey(name: 'subscribers_count')  int subscribersCount,  bool disabled, @JsonKey(name: 'updated_at')  DateTime updatedAt, @JsonKey(name: 'pushed_at')  DateTime pushedAt, @JsonKey(name: 'created_at')  DateTime createdAt,  bool archived, @JsonKey(name: 'anonymous_access_enabled')  bool anonymousAccessEnabled,  Permissions11? permissions, @JsonKey(name: 'allow_rebase_merge')  bool? allowRebaseMerge, @JsonKey(name: 'template_repository')  NullableRepository? templateRepository, @JsonKey(name: 'temp_clone_token')  String? tempCloneToken, @JsonKey(name: 'allow_squash_merge')  bool? allowSquashMerge, @JsonKey(name: 'allow_auto_merge')  bool? allowAutoMerge, @JsonKey(name: 'delete_branch_on_merge')  bool? deleteBranchOnMerge, @JsonKey(name: 'allow_merge_commit')  bool? allowMergeCommit, @JsonKey(name: 'allow_update_branch')  bool? allowUpdateBranch, @JsonKey(name: 'use_squash_pr_title_as_default')  bool? useSquashPrTitleAsDefault, @JsonKey(name: 'squash_merge_commit_title')  FullRepositorySquashMergeCommitTitle? squashMergeCommitTitle, @JsonKey(name: 'squash_merge_commit_message')  FullRepositorySquashMergeCommitMessage? squashMergeCommitMessage, @JsonKey(name: 'merge_commit_title')  FullRepositoryMergeCommitTitle? mergeCommitTitle, @JsonKey(name: 'merge_commit_message')  FullRepositoryMergeCommitMessage? mergeCommitMessage, @JsonKey(name: 'allow_forking')  bool? allowForking, @JsonKey(name: 'web_commit_signoff_required')  bool? webCommitSignoffRequired, @JsonKey(name: 'custom_properties')  dynamic customProperties, @JsonKey(name: 'pull_request_creation_policy')  FullRepositoryPullRequestCreationPolicy? pullRequestCreationPolicy, @JsonKey(name: 'has_pull_requests')  bool? hasPullRequests,  NullableSimpleUser? organization,  Repository? parent,  Repository? source, @JsonKey(name: 'has_downloads')  bool? hasDownloads, @JsonKey(name: 'master_branch')  String? masterBranch,  List<String>? topics, @JsonKey(name: 'is_template')  bool? isTemplate, @JsonKey(name: 'code_of_conduct')  CodeOfConductSimple? codeOfConduct, @JsonKey(name: 'security_and_analysis')  SecurityAndAnalysis? securityAndAnalysis,  String? visibility)?  $default,) {final _that = this;
switch (_that) {
case _FullRepository() when $default != null:
return $default(_that.milestonesUrl,_that.nodeId,_that.name,_that.fullName,_that.owner,_that.private,_that.htmlUrl,_that.description,_that.fork,_that.url,_that.archiveUrl,_that.assigneesUrl,_that.blobsUrl,_that.branchesUrl,_that.collaboratorsUrl,_that.commentsUrl,_that.commitsUrl,_that.compareUrl,_that.contentsUrl,_that.contributorsUrl,_that.deploymentsUrl,_that.downloadsUrl,_that.eventsUrl,_that.forksUrl,_that.gitCommitsUrl,_that.gitRefsUrl,_that.gitTagsUrl,_that.gitUrl,_that.issueCommentUrl,_that.issueEventsUrl,_that.issuesUrl,_that.keysUrl,_that.labelsUrl,_that.languagesUrl,_that.mergesUrl,_that.id,_that.notificationsUrl,_that.pullsUrl,_that.releasesUrl,_that.sshUrl,_that.stargazersUrl,_that.statusesUrl,_that.subscribersUrl,_that.subscriptionUrl,_that.tagsUrl,_that.teamsUrl,_that.treesUrl,_that.cloneUrl,_that.mirrorUrl,_that.hooksUrl,_that.svnUrl,_that.homepage,_that.language,_that.forksCount,_that.stargazersCount,_that.watchersCount,_that.size,_that.defaultBranch,_that.openIssuesCount,_that.watchers,_that.openIssues,_that.hasIssues,_that.hasProjects,_that.hasWiki,_that.hasPages,_that.forks,_that.hasDiscussions,_that.license,_that.networkCount,_that.subscribersCount,_that.disabled,_that.updatedAt,_that.pushedAt,_that.createdAt,_that.archived,_that.anonymousAccessEnabled,_that.permissions,_that.allowRebaseMerge,_that.templateRepository,_that.tempCloneToken,_that.allowSquashMerge,_that.allowAutoMerge,_that.deleteBranchOnMerge,_that.allowMergeCommit,_that.allowUpdateBranch,_that.useSquashPrTitleAsDefault,_that.squashMergeCommitTitle,_that.squashMergeCommitMessage,_that.mergeCommitTitle,_that.mergeCommitMessage,_that.allowForking,_that.webCommitSignoffRequired,_that.customProperties,_that.pullRequestCreationPolicy,_that.hasPullRequests,_that.organization,_that.parent,_that.source,_that.hasDownloads,_that.masterBranch,_that.topics,_that.isTemplate,_that.codeOfConduct,_that.securityAndAnalysis,_that.visibility);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FullRepository implements FullRepository {
  const _FullRepository({@JsonKey(name: 'milestones_url') required this.milestonesUrl, @JsonKey(name: 'node_id') required this.nodeId, required this.name, @JsonKey(name: 'full_name') required this.fullName, required this.owner, required this.private, @JsonKey(name: 'html_url') required this.htmlUrl, required this.description, required this.fork, required this.url, @JsonKey(name: 'archive_url') required this.archiveUrl, @JsonKey(name: 'assignees_url') required this.assigneesUrl, @JsonKey(name: 'blobs_url') required this.blobsUrl, @JsonKey(name: 'branches_url') required this.branchesUrl, @JsonKey(name: 'collaborators_url') required this.collaboratorsUrl, @JsonKey(name: 'comments_url') required this.commentsUrl, @JsonKey(name: 'commits_url') required this.commitsUrl, @JsonKey(name: 'compare_url') required this.compareUrl, @JsonKey(name: 'contents_url') required this.contentsUrl, @JsonKey(name: 'contributors_url') required this.contributorsUrl, @JsonKey(name: 'deployments_url') required this.deploymentsUrl, @JsonKey(name: 'downloads_url') required this.downloadsUrl, @JsonKey(name: 'events_url') required this.eventsUrl, @JsonKey(name: 'forks_url') required this.forksUrl, @JsonKey(name: 'git_commits_url') required this.gitCommitsUrl, @JsonKey(name: 'git_refs_url') required this.gitRefsUrl, @JsonKey(name: 'git_tags_url') required this.gitTagsUrl, @JsonKey(name: 'git_url') required this.gitUrl, @JsonKey(name: 'issue_comment_url') required this.issueCommentUrl, @JsonKey(name: 'issue_events_url') required this.issueEventsUrl, @JsonKey(name: 'issues_url') required this.issuesUrl, @JsonKey(name: 'keys_url') required this.keysUrl, @JsonKey(name: 'labels_url') required this.labelsUrl, @JsonKey(name: 'languages_url') required this.languagesUrl, @JsonKey(name: 'merges_url') required this.mergesUrl, required this.id, @JsonKey(name: 'notifications_url') required this.notificationsUrl, @JsonKey(name: 'pulls_url') required this.pullsUrl, @JsonKey(name: 'releases_url') required this.releasesUrl, @JsonKey(name: 'ssh_url') required this.sshUrl, @JsonKey(name: 'stargazers_url') required this.stargazersUrl, @JsonKey(name: 'statuses_url') required this.statusesUrl, @JsonKey(name: 'subscribers_url') required this.subscribersUrl, @JsonKey(name: 'subscription_url') required this.subscriptionUrl, @JsonKey(name: 'tags_url') required this.tagsUrl, @JsonKey(name: 'teams_url') required this.teamsUrl, @JsonKey(name: 'trees_url') required this.treesUrl, @JsonKey(name: 'clone_url') required this.cloneUrl, @JsonKey(name: 'mirror_url') required this.mirrorUrl, @JsonKey(name: 'hooks_url') required this.hooksUrl, @JsonKey(name: 'svn_url') required this.svnUrl, required this.homepage, @JsonKey(name: 'Language') required this.language, @JsonKey(name: 'forks_count') required this.forksCount, @JsonKey(name: 'stargazers_count') required this.stargazersCount, @JsonKey(name: 'watchers_count') required this.watchersCount, required this.size, @JsonKey(name: 'default_branch') required this.defaultBranch, @JsonKey(name: 'open_issues_count') required this.openIssuesCount, required this.watchers, @JsonKey(name: 'open_issues') required this.openIssues, @JsonKey(name: 'has_issues') required this.hasIssues, @JsonKey(name: 'has_projects') required this.hasProjects, @JsonKey(name: 'has_wiki') required this.hasWiki, @JsonKey(name: 'has_pages') required this.hasPages, required this.forks, @JsonKey(name: 'has_discussions') required this.hasDiscussions, @JsonKey(name: 'License') required this.license, @JsonKey(name: 'network_count') required this.networkCount, @JsonKey(name: 'subscribers_count') required this.subscribersCount, required this.disabled, @JsonKey(name: 'updated_at') required this.updatedAt, @JsonKey(name: 'pushed_at') required this.pushedAt, @JsonKey(name: 'created_at') required this.createdAt, required this.archived, @JsonKey(name: 'anonymous_access_enabled') this.anonymousAccessEnabled = true, this.permissions, @JsonKey(name: 'allow_rebase_merge') this.allowRebaseMerge, @JsonKey(name: 'template_repository') this.templateRepository, @JsonKey(name: 'temp_clone_token') this.tempCloneToken, @JsonKey(name: 'allow_squash_merge') this.allowSquashMerge, @JsonKey(name: 'allow_auto_merge') this.allowAutoMerge, @JsonKey(name: 'delete_branch_on_merge') this.deleteBranchOnMerge, @JsonKey(name: 'allow_merge_commit') this.allowMergeCommit, @JsonKey(name: 'allow_update_branch') this.allowUpdateBranch, @JsonKey(name: 'use_squash_pr_title_as_default') this.useSquashPrTitleAsDefault, @JsonKey(name: 'squash_merge_commit_title') this.squashMergeCommitTitle, @JsonKey(name: 'squash_merge_commit_message') this.squashMergeCommitMessage, @JsonKey(name: 'merge_commit_title') this.mergeCommitTitle, @JsonKey(name: 'merge_commit_message') this.mergeCommitMessage, @JsonKey(name: 'allow_forking') this.allowForking, @JsonKey(name: 'web_commit_signoff_required') this.webCommitSignoffRequired, @JsonKey(name: 'custom_properties') this.customProperties, @JsonKey(name: 'pull_request_creation_policy') this.pullRequestCreationPolicy, @JsonKey(name: 'has_pull_requests') this.hasPullRequests, this.organization, this.parent, this.source, @JsonKey(name: 'has_downloads') this.hasDownloads, @JsonKey(name: 'master_branch') this.masterBranch, final  List<String>? topics, @JsonKey(name: 'is_template') this.isTemplate, @JsonKey(name: 'code_of_conduct') this.codeOfConduct, @JsonKey(name: 'security_and_analysis') this.securityAndAnalysis, this.visibility}): _topics = topics;
  factory _FullRepository.fromJson(Map<String, dynamic> json) => _$FullRepositoryFromJson(json);

@override@JsonKey(name: 'milestones_url') final  String milestonesUrl;
@override@JsonKey(name: 'node_id') final  String nodeId;
@override final  String name;
@override@JsonKey(name: 'full_name') final  String fullName;
@override final  SimpleUser owner;
@override final  bool private;
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
@override@JsonKey(name: 'issue_events_url') final  String issueEventsUrl;
@override@JsonKey(name: 'issues_url') final  String issuesUrl;
@override@JsonKey(name: 'keys_url') final  String keysUrl;
@override@JsonKey(name: 'labels_url') final  String labelsUrl;
@override@JsonKey(name: 'languages_url') final  String languagesUrl;
@override@JsonKey(name: 'merges_url') final  String mergesUrl;
@override final  int id;
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
@override@JsonKey(name: 'default_branch') final  String defaultBranch;
@override@JsonKey(name: 'open_issues_count') final  int openIssuesCount;
@override final  int watchers;
@override@JsonKey(name: 'open_issues') final  int openIssues;
@override@JsonKey(name: 'has_issues') final  bool hasIssues;
@override@JsonKey(name: 'has_projects') final  bool hasProjects;
@override@JsonKey(name: 'has_wiki') final  bool hasWiki;
@override@JsonKey(name: 'has_pages') final  bool hasPages;
@override final  int forks;
@override@JsonKey(name: 'has_discussions') final  bool hasDiscussions;
@override@JsonKey(name: 'License') final  NullableLicenseSimple? license;
@override@JsonKey(name: 'network_count') final  int networkCount;
@override@JsonKey(name: 'subscribers_count') final  int subscribersCount;
/// Returns whether or not this Repository disabled.
@override final  bool disabled;
@override@JsonKey(name: 'updated_at') final  DateTime updatedAt;
@override@JsonKey(name: 'pushed_at') final  DateTime pushedAt;
@override@JsonKey(name: 'created_at') final  DateTime createdAt;
@override final  bool archived;
/// Whether anonymous git access is allowed.
@override@JsonKey(name: 'anonymous_access_enabled') final  bool anonymousAccessEnabled;
@override final  Permissions11? permissions;
@override@JsonKey(name: 'allow_rebase_merge') final  bool? allowRebaseMerge;
@override@JsonKey(name: 'template_repository') final  NullableRepository? templateRepository;
@override@JsonKey(name: 'temp_clone_token') final  String? tempCloneToken;
@override@JsonKey(name: 'allow_squash_merge') final  bool? allowSquashMerge;
@override@JsonKey(name: 'allow_auto_merge') final  bool? allowAutoMerge;
@override@JsonKey(name: 'delete_branch_on_merge') final  bool? deleteBranchOnMerge;
@override@JsonKey(name: 'allow_merge_commit') final  bool? allowMergeCommit;
@override@JsonKey(name: 'allow_update_branch') final  bool? allowUpdateBranch;
@override@JsonKey(name: 'use_squash_pr_title_as_default') final  bool? useSquashPrTitleAsDefault;
/// The default value for a squash merge Commit title:.
///
/// - `PR_TITLE` - default to the pull request's title.
/// - `COMMIT_OR_PR_TITLE` - default to the Commit's title (if only one commit) or the pull request's title (when more than one commit).
@override@JsonKey(name: 'squash_merge_commit_title') final  FullRepositorySquashMergeCommitTitle? squashMergeCommitTitle;
/// The default value for a squash merge Commit message:.
///
/// - `PR_BODY` - default to the pull request's body.
/// - `COMMIT_MESSAGES` - default to the branch's Commit messages.
/// - `BLANK` - default to a blank Commit message.
@override@JsonKey(name: 'squash_merge_commit_message') final  FullRepositorySquashMergeCommitMessage? squashMergeCommitMessage;
/// The default value for a merge Commit title.
///
///   - `PR_TITLE` - default to the pull request's title.
///   - `MERGE_MESSAGE` - default to the classic title for a merge message (e.g., Merge pull request #123 from branch-name).
@override@JsonKey(name: 'merge_commit_title') final  FullRepositoryMergeCommitTitle? mergeCommitTitle;
/// The default value for a merge Commit message.
///
/// - `PR_TITLE` - default to the pull request's title.
/// - `PR_BODY` - default to the pull request's body.
/// - `BLANK` - default to a blank Commit message.
@override@JsonKey(name: 'merge_commit_message') final  FullRepositoryMergeCommitMessage? mergeCommitMessage;
@override@JsonKey(name: 'allow_forking') final  bool? allowForking;
@override@JsonKey(name: 'web_commit_signoff_required') final  bool? webCommitSignoffRequired;
/// The custom properties that were defined for the repository. The keys are the custom property names, and the values are the corresponding custom property values.
@override@JsonKey(name: 'custom_properties') final  dynamic customProperties;
/// The policy controlling who can create pull requests: all or collaborators_only.
@override@JsonKey(name: 'pull_request_creation_policy') final  FullRepositoryPullRequestCreationPolicy? pullRequestCreationPolicy;
@override@JsonKey(name: 'has_pull_requests') final  bool? hasPullRequests;
@override final  NullableSimpleUser? organization;
@override final  Repository? parent;
@override final  Repository? source;
@override@JsonKey(name: 'has_downloads') final  bool? hasDownloads;
@override@JsonKey(name: 'master_branch') final  String? masterBranch;
 final  List<String>? _topics;
@override List<String>? get topics {
  final value = _topics;
  if (value == null) return null;
  if (_topics is EqualUnmodifiableListView) return _topics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(name: 'is_template') final  bool? isTemplate;
@override@JsonKey(name: 'code_of_conduct') final  CodeOfConductSimple? codeOfConduct;
@override@JsonKey(name: 'security_and_analysis') final  SecurityAndAnalysis? securityAndAnalysis;
/// The Repository visibility: public, private, or internal.
@override final  String? visibility;

/// Create a copy of FullRepository
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FullRepositoryCopyWith<_FullRepository> get copyWith => __$FullRepositoryCopyWithImpl<_FullRepository>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FullRepositoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FullRepository&&(identical(other.milestonesUrl, milestonesUrl) || other.milestonesUrl == milestonesUrl)&&(identical(other.nodeId, nodeId) || other.nodeId == nodeId)&&(identical(other.name, name) || other.name == name)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.private, private) || other.private == private)&&(identical(other.htmlUrl, htmlUrl) || other.htmlUrl == htmlUrl)&&(identical(other.description, description) || other.description == description)&&(identical(other.fork, fork) || other.fork == fork)&&(identical(other.url, url) || other.url == url)&&(identical(other.archiveUrl, archiveUrl) || other.archiveUrl == archiveUrl)&&(identical(other.assigneesUrl, assigneesUrl) || other.assigneesUrl == assigneesUrl)&&(identical(other.blobsUrl, blobsUrl) || other.blobsUrl == blobsUrl)&&(identical(other.branchesUrl, branchesUrl) || other.branchesUrl == branchesUrl)&&(identical(other.collaboratorsUrl, collaboratorsUrl) || other.collaboratorsUrl == collaboratorsUrl)&&(identical(other.commentsUrl, commentsUrl) || other.commentsUrl == commentsUrl)&&(identical(other.commitsUrl, commitsUrl) || other.commitsUrl == commitsUrl)&&(identical(other.compareUrl, compareUrl) || other.compareUrl == compareUrl)&&(identical(other.contentsUrl, contentsUrl) || other.contentsUrl == contentsUrl)&&(identical(other.contributorsUrl, contributorsUrl) || other.contributorsUrl == contributorsUrl)&&(identical(other.deploymentsUrl, deploymentsUrl) || other.deploymentsUrl == deploymentsUrl)&&(identical(other.downloadsUrl, downloadsUrl) || other.downloadsUrl == downloadsUrl)&&(identical(other.eventsUrl, eventsUrl) || other.eventsUrl == eventsUrl)&&(identical(other.forksUrl, forksUrl) || other.forksUrl == forksUrl)&&(identical(other.gitCommitsUrl, gitCommitsUrl) || other.gitCommitsUrl == gitCommitsUrl)&&(identical(other.gitRefsUrl, gitRefsUrl) || other.gitRefsUrl == gitRefsUrl)&&(identical(other.gitTagsUrl, gitTagsUrl) || other.gitTagsUrl == gitTagsUrl)&&(identical(other.gitUrl, gitUrl) || other.gitUrl == gitUrl)&&(identical(other.issueCommentUrl, issueCommentUrl) || other.issueCommentUrl == issueCommentUrl)&&(identical(other.issueEventsUrl, issueEventsUrl) || other.issueEventsUrl == issueEventsUrl)&&(identical(other.issuesUrl, issuesUrl) || other.issuesUrl == issuesUrl)&&(identical(other.keysUrl, keysUrl) || other.keysUrl == keysUrl)&&(identical(other.labelsUrl, labelsUrl) || other.labelsUrl == labelsUrl)&&(identical(other.languagesUrl, languagesUrl) || other.languagesUrl == languagesUrl)&&(identical(other.mergesUrl, mergesUrl) || other.mergesUrl == mergesUrl)&&(identical(other.id, id) || other.id == id)&&(identical(other.notificationsUrl, notificationsUrl) || other.notificationsUrl == notificationsUrl)&&(identical(other.pullsUrl, pullsUrl) || other.pullsUrl == pullsUrl)&&(identical(other.releasesUrl, releasesUrl) || other.releasesUrl == releasesUrl)&&(identical(other.sshUrl, sshUrl) || other.sshUrl == sshUrl)&&(identical(other.stargazersUrl, stargazersUrl) || other.stargazersUrl == stargazersUrl)&&(identical(other.statusesUrl, statusesUrl) || other.statusesUrl == statusesUrl)&&(identical(other.subscribersUrl, subscribersUrl) || other.subscribersUrl == subscribersUrl)&&(identical(other.subscriptionUrl, subscriptionUrl) || other.subscriptionUrl == subscriptionUrl)&&(identical(other.tagsUrl, tagsUrl) || other.tagsUrl == tagsUrl)&&(identical(other.teamsUrl, teamsUrl) || other.teamsUrl == teamsUrl)&&(identical(other.treesUrl, treesUrl) || other.treesUrl == treesUrl)&&(identical(other.cloneUrl, cloneUrl) || other.cloneUrl == cloneUrl)&&(identical(other.mirrorUrl, mirrorUrl) || other.mirrorUrl == mirrorUrl)&&(identical(other.hooksUrl, hooksUrl) || other.hooksUrl == hooksUrl)&&(identical(other.svnUrl, svnUrl) || other.svnUrl == svnUrl)&&(identical(other.homepage, homepage) || other.homepage == homepage)&&(identical(other.language, language) || other.language == language)&&(identical(other.forksCount, forksCount) || other.forksCount == forksCount)&&(identical(other.stargazersCount, stargazersCount) || other.stargazersCount == stargazersCount)&&(identical(other.watchersCount, watchersCount) || other.watchersCount == watchersCount)&&(identical(other.size, size) || other.size == size)&&(identical(other.defaultBranch, defaultBranch) || other.defaultBranch == defaultBranch)&&(identical(other.openIssuesCount, openIssuesCount) || other.openIssuesCount == openIssuesCount)&&(identical(other.watchers, watchers) || other.watchers == watchers)&&(identical(other.openIssues, openIssues) || other.openIssues == openIssues)&&(identical(other.hasIssues, hasIssues) || other.hasIssues == hasIssues)&&(identical(other.hasProjects, hasProjects) || other.hasProjects == hasProjects)&&(identical(other.hasWiki, hasWiki) || other.hasWiki == hasWiki)&&(identical(other.hasPages, hasPages) || other.hasPages == hasPages)&&(identical(other.forks, forks) || other.forks == forks)&&(identical(other.hasDiscussions, hasDiscussions) || other.hasDiscussions == hasDiscussions)&&(identical(other.license, license) || other.license == license)&&(identical(other.networkCount, networkCount) || other.networkCount == networkCount)&&(identical(other.subscribersCount, subscribersCount) || other.subscribersCount == subscribersCount)&&(identical(other.disabled, disabled) || other.disabled == disabled)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.pushedAt, pushedAt) || other.pushedAt == pushedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.archived, archived) || other.archived == archived)&&(identical(other.anonymousAccessEnabled, anonymousAccessEnabled) || other.anonymousAccessEnabled == anonymousAccessEnabled)&&(identical(other.permissions, permissions) || other.permissions == permissions)&&(identical(other.allowRebaseMerge, allowRebaseMerge) || other.allowRebaseMerge == allowRebaseMerge)&&(identical(other.templateRepository, templateRepository) || other.templateRepository == templateRepository)&&(identical(other.tempCloneToken, tempCloneToken) || other.tempCloneToken == tempCloneToken)&&(identical(other.allowSquashMerge, allowSquashMerge) || other.allowSquashMerge == allowSquashMerge)&&(identical(other.allowAutoMerge, allowAutoMerge) || other.allowAutoMerge == allowAutoMerge)&&(identical(other.deleteBranchOnMerge, deleteBranchOnMerge) || other.deleteBranchOnMerge == deleteBranchOnMerge)&&(identical(other.allowMergeCommit, allowMergeCommit) || other.allowMergeCommit == allowMergeCommit)&&(identical(other.allowUpdateBranch, allowUpdateBranch) || other.allowUpdateBranch == allowUpdateBranch)&&(identical(other.useSquashPrTitleAsDefault, useSquashPrTitleAsDefault) || other.useSquashPrTitleAsDefault == useSquashPrTitleAsDefault)&&(identical(other.squashMergeCommitTitle, squashMergeCommitTitle) || other.squashMergeCommitTitle == squashMergeCommitTitle)&&(identical(other.squashMergeCommitMessage, squashMergeCommitMessage) || other.squashMergeCommitMessage == squashMergeCommitMessage)&&(identical(other.mergeCommitTitle, mergeCommitTitle) || other.mergeCommitTitle == mergeCommitTitle)&&(identical(other.mergeCommitMessage, mergeCommitMessage) || other.mergeCommitMessage == mergeCommitMessage)&&(identical(other.allowForking, allowForking) || other.allowForking == allowForking)&&(identical(other.webCommitSignoffRequired, webCommitSignoffRequired) || other.webCommitSignoffRequired == webCommitSignoffRequired)&&const DeepCollectionEquality().equals(other.customProperties, customProperties)&&(identical(other.pullRequestCreationPolicy, pullRequestCreationPolicy) || other.pullRequestCreationPolicy == pullRequestCreationPolicy)&&(identical(other.hasPullRequests, hasPullRequests) || other.hasPullRequests == hasPullRequests)&&(identical(other.organization, organization) || other.organization == organization)&&(identical(other.parent, parent) || other.parent == parent)&&(identical(other.source, source) || other.source == source)&&(identical(other.hasDownloads, hasDownloads) || other.hasDownloads == hasDownloads)&&(identical(other.masterBranch, masterBranch) || other.masterBranch == masterBranch)&&const DeepCollectionEquality().equals(other._topics, _topics)&&(identical(other.isTemplate, isTemplate) || other.isTemplate == isTemplate)&&(identical(other.codeOfConduct, codeOfConduct) || other.codeOfConduct == codeOfConduct)&&(identical(other.securityAndAnalysis, securityAndAnalysis) || other.securityAndAnalysis == securityAndAnalysis)&&(identical(other.visibility, visibility) || other.visibility == visibility));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,milestonesUrl,nodeId,name,fullName,owner,private,htmlUrl,description,fork,url,archiveUrl,assigneesUrl,blobsUrl,branchesUrl,collaboratorsUrl,commentsUrl,commitsUrl,compareUrl,contentsUrl,contributorsUrl,deploymentsUrl,downloadsUrl,eventsUrl,forksUrl,gitCommitsUrl,gitRefsUrl,gitTagsUrl,gitUrl,issueCommentUrl,issueEventsUrl,issuesUrl,keysUrl,labelsUrl,languagesUrl,mergesUrl,id,notificationsUrl,pullsUrl,releasesUrl,sshUrl,stargazersUrl,statusesUrl,subscribersUrl,subscriptionUrl,tagsUrl,teamsUrl,treesUrl,cloneUrl,mirrorUrl,hooksUrl,svnUrl,homepage,language,forksCount,stargazersCount,watchersCount,size,defaultBranch,openIssuesCount,watchers,openIssues,hasIssues,hasProjects,hasWiki,hasPages,forks,hasDiscussions,license,networkCount,subscribersCount,disabled,updatedAt,pushedAt,createdAt,archived,anonymousAccessEnabled,permissions,allowRebaseMerge,templateRepository,tempCloneToken,allowSquashMerge,allowAutoMerge,deleteBranchOnMerge,allowMergeCommit,allowUpdateBranch,useSquashPrTitleAsDefault,squashMergeCommitTitle,squashMergeCommitMessage,mergeCommitTitle,mergeCommitMessage,allowForking,webCommitSignoffRequired,const DeepCollectionEquality().hash(customProperties),pullRequestCreationPolicy,hasPullRequests,organization,parent,source,hasDownloads,masterBranch,const DeepCollectionEquality().hash(_topics),isTemplate,codeOfConduct,securityAndAnalysis,visibility]);

@override
String toString() {
  return 'FullRepository(milestonesUrl: $milestonesUrl, nodeId: $nodeId, name: $name, fullName: $fullName, owner: $owner, private: $private, htmlUrl: $htmlUrl, description: $description, fork: $fork, url: $url, archiveUrl: $archiveUrl, assigneesUrl: $assigneesUrl, blobsUrl: $blobsUrl, branchesUrl: $branchesUrl, collaboratorsUrl: $collaboratorsUrl, commentsUrl: $commentsUrl, commitsUrl: $commitsUrl, compareUrl: $compareUrl, contentsUrl: $contentsUrl, contributorsUrl: $contributorsUrl, deploymentsUrl: $deploymentsUrl, downloadsUrl: $downloadsUrl, eventsUrl: $eventsUrl, forksUrl: $forksUrl, gitCommitsUrl: $gitCommitsUrl, gitRefsUrl: $gitRefsUrl, gitTagsUrl: $gitTagsUrl, gitUrl: $gitUrl, issueCommentUrl: $issueCommentUrl, issueEventsUrl: $issueEventsUrl, issuesUrl: $issuesUrl, keysUrl: $keysUrl, labelsUrl: $labelsUrl, languagesUrl: $languagesUrl, mergesUrl: $mergesUrl, id: $id, notificationsUrl: $notificationsUrl, pullsUrl: $pullsUrl, releasesUrl: $releasesUrl, sshUrl: $sshUrl, stargazersUrl: $stargazersUrl, statusesUrl: $statusesUrl, subscribersUrl: $subscribersUrl, subscriptionUrl: $subscriptionUrl, tagsUrl: $tagsUrl, teamsUrl: $teamsUrl, treesUrl: $treesUrl, cloneUrl: $cloneUrl, mirrorUrl: $mirrorUrl, hooksUrl: $hooksUrl, svnUrl: $svnUrl, homepage: $homepage, language: $language, forksCount: $forksCount, stargazersCount: $stargazersCount, watchersCount: $watchersCount, size: $size, defaultBranch: $defaultBranch, openIssuesCount: $openIssuesCount, watchers: $watchers, openIssues: $openIssues, hasIssues: $hasIssues, hasProjects: $hasProjects, hasWiki: $hasWiki, hasPages: $hasPages, forks: $forks, hasDiscussions: $hasDiscussions, license: $license, networkCount: $networkCount, subscribersCount: $subscribersCount, disabled: $disabled, updatedAt: $updatedAt, pushedAt: $pushedAt, createdAt: $createdAt, archived: $archived, anonymousAccessEnabled: $anonymousAccessEnabled, permissions: $permissions, allowRebaseMerge: $allowRebaseMerge, templateRepository: $templateRepository, tempCloneToken: $tempCloneToken, allowSquashMerge: $allowSquashMerge, allowAutoMerge: $allowAutoMerge, deleteBranchOnMerge: $deleteBranchOnMerge, allowMergeCommit: $allowMergeCommit, allowUpdateBranch: $allowUpdateBranch, useSquashPrTitleAsDefault: $useSquashPrTitleAsDefault, squashMergeCommitTitle: $squashMergeCommitTitle, squashMergeCommitMessage: $squashMergeCommitMessage, mergeCommitTitle: $mergeCommitTitle, mergeCommitMessage: $mergeCommitMessage, allowForking: $allowForking, webCommitSignoffRequired: $webCommitSignoffRequired, customProperties: $customProperties, pullRequestCreationPolicy: $pullRequestCreationPolicy, hasPullRequests: $hasPullRequests, organization: $organization, parent: $parent, source: $source, hasDownloads: $hasDownloads, masterBranch: $masterBranch, topics: $topics, isTemplate: $isTemplate, codeOfConduct: $codeOfConduct, securityAndAnalysis: $securityAndAnalysis, visibility: $visibility)';
}


}

/// @nodoc
abstract mixin class _$FullRepositoryCopyWith<$Res> implements $FullRepositoryCopyWith<$Res> {
  factory _$FullRepositoryCopyWith(_FullRepository value, $Res Function(_FullRepository) _then) = __$FullRepositoryCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'milestones_url') String milestonesUrl,@JsonKey(name: 'node_id') String nodeId, String name,@JsonKey(name: 'full_name') String fullName, SimpleUser owner, bool private,@JsonKey(name: 'html_url') String htmlUrl, String? description, bool fork, String url,@JsonKey(name: 'archive_url') String archiveUrl,@JsonKey(name: 'assignees_url') String assigneesUrl,@JsonKey(name: 'blobs_url') String blobsUrl,@JsonKey(name: 'branches_url') String branchesUrl,@JsonKey(name: 'collaborators_url') String collaboratorsUrl,@JsonKey(name: 'comments_url') String commentsUrl,@JsonKey(name: 'commits_url') String commitsUrl,@JsonKey(name: 'compare_url') String compareUrl,@JsonKey(name: 'contents_url') String contentsUrl,@JsonKey(name: 'contributors_url') String contributorsUrl,@JsonKey(name: 'deployments_url') String deploymentsUrl,@JsonKey(name: 'downloads_url') String downloadsUrl,@JsonKey(name: 'events_url') String eventsUrl,@JsonKey(name: 'forks_url') String forksUrl,@JsonKey(name: 'git_commits_url') String gitCommitsUrl,@JsonKey(name: 'git_refs_url') String gitRefsUrl,@JsonKey(name: 'git_tags_url') String gitTagsUrl,@JsonKey(name: 'git_url') String gitUrl,@JsonKey(name: 'issue_comment_url') String issueCommentUrl,@JsonKey(name: 'issue_events_url') String issueEventsUrl,@JsonKey(name: 'issues_url') String issuesUrl,@JsonKey(name: 'keys_url') String keysUrl,@JsonKey(name: 'labels_url') String labelsUrl,@JsonKey(name: 'languages_url') String languagesUrl,@JsonKey(name: 'merges_url') String mergesUrl, int id,@JsonKey(name: 'notifications_url') String notificationsUrl,@JsonKey(name: 'pulls_url') String pullsUrl,@JsonKey(name: 'releases_url') String releasesUrl,@JsonKey(name: 'ssh_url') String sshUrl,@JsonKey(name: 'stargazers_url') String stargazersUrl,@JsonKey(name: 'statuses_url') String statusesUrl,@JsonKey(name: 'subscribers_url') String subscribersUrl,@JsonKey(name: 'subscription_url') String subscriptionUrl,@JsonKey(name: 'tags_url') String tagsUrl,@JsonKey(name: 'teams_url') String teamsUrl,@JsonKey(name: 'trees_url') String treesUrl,@JsonKey(name: 'clone_url') String cloneUrl,@JsonKey(name: 'mirror_url') String? mirrorUrl,@JsonKey(name: 'hooks_url') String hooksUrl,@JsonKey(name: 'svn_url') String svnUrl, String? homepage,@JsonKey(name: 'Language') String? language,@JsonKey(name: 'forks_count') int forksCount,@JsonKey(name: 'stargazers_count') int stargazersCount,@JsonKey(name: 'watchers_count') int watchersCount, int size,@JsonKey(name: 'default_branch') String defaultBranch,@JsonKey(name: 'open_issues_count') int openIssuesCount, int watchers,@JsonKey(name: 'open_issues') int openIssues,@JsonKey(name: 'has_issues') bool hasIssues,@JsonKey(name: 'has_projects') bool hasProjects,@JsonKey(name: 'has_wiki') bool hasWiki,@JsonKey(name: 'has_pages') bool hasPages, int forks,@JsonKey(name: 'has_discussions') bool hasDiscussions,@JsonKey(name: 'License') NullableLicenseSimple? license,@JsonKey(name: 'network_count') int networkCount,@JsonKey(name: 'subscribers_count') int subscribersCount, bool disabled,@JsonKey(name: 'updated_at') DateTime updatedAt,@JsonKey(name: 'pushed_at') DateTime pushedAt,@JsonKey(name: 'created_at') DateTime createdAt, bool archived,@JsonKey(name: 'anonymous_access_enabled') bool anonymousAccessEnabled, Permissions11? permissions,@JsonKey(name: 'allow_rebase_merge') bool? allowRebaseMerge,@JsonKey(name: 'template_repository') NullableRepository? templateRepository,@JsonKey(name: 'temp_clone_token') String? tempCloneToken,@JsonKey(name: 'allow_squash_merge') bool? allowSquashMerge,@JsonKey(name: 'allow_auto_merge') bool? allowAutoMerge,@JsonKey(name: 'delete_branch_on_merge') bool? deleteBranchOnMerge,@JsonKey(name: 'allow_merge_commit') bool? allowMergeCommit,@JsonKey(name: 'allow_update_branch') bool? allowUpdateBranch,@JsonKey(name: 'use_squash_pr_title_as_default') bool? useSquashPrTitleAsDefault,@JsonKey(name: 'squash_merge_commit_title') FullRepositorySquashMergeCommitTitle? squashMergeCommitTitle,@JsonKey(name: 'squash_merge_commit_message') FullRepositorySquashMergeCommitMessage? squashMergeCommitMessage,@JsonKey(name: 'merge_commit_title') FullRepositoryMergeCommitTitle? mergeCommitTitle,@JsonKey(name: 'merge_commit_message') FullRepositoryMergeCommitMessage? mergeCommitMessage,@JsonKey(name: 'allow_forking') bool? allowForking,@JsonKey(name: 'web_commit_signoff_required') bool? webCommitSignoffRequired,@JsonKey(name: 'custom_properties') dynamic customProperties,@JsonKey(name: 'pull_request_creation_policy') FullRepositoryPullRequestCreationPolicy? pullRequestCreationPolicy,@JsonKey(name: 'has_pull_requests') bool? hasPullRequests, NullableSimpleUser? organization, Repository? parent, Repository? source,@JsonKey(name: 'has_downloads') bool? hasDownloads,@JsonKey(name: 'master_branch') String? masterBranch, List<String>? topics,@JsonKey(name: 'is_template') bool? isTemplate,@JsonKey(name: 'code_of_conduct') CodeOfConductSimple? codeOfConduct,@JsonKey(name: 'security_and_analysis') SecurityAndAnalysis? securityAndAnalysis, String? visibility
});


@override $SimpleUserCopyWith<$Res> get owner;@override $NullableLicenseSimpleCopyWith<$Res>? get license;@override $Permissions11CopyWith<$Res>? get permissions;@override $NullableRepositoryCopyWith<$Res>? get templateRepository;@override $NullableSimpleUserCopyWith<$Res>? get organization;@override $RepositoryCopyWith<$Res>? get parent;@override $RepositoryCopyWith<$Res>? get source;@override $CodeOfConductSimpleCopyWith<$Res>? get codeOfConduct;@override $SecurityAndAnalysisCopyWith<$Res>? get securityAndAnalysis;

}
/// @nodoc
class __$FullRepositoryCopyWithImpl<$Res>
    implements _$FullRepositoryCopyWith<$Res> {
  __$FullRepositoryCopyWithImpl(this._self, this._then);

  final _FullRepository _self;
  final $Res Function(_FullRepository) _then;

/// Create a copy of FullRepository
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? milestonesUrl = null,Object? nodeId = null,Object? name = null,Object? fullName = null,Object? owner = null,Object? private = null,Object? htmlUrl = null,Object? description = freezed,Object? fork = null,Object? url = null,Object? archiveUrl = null,Object? assigneesUrl = null,Object? blobsUrl = null,Object? branchesUrl = null,Object? collaboratorsUrl = null,Object? commentsUrl = null,Object? commitsUrl = null,Object? compareUrl = null,Object? contentsUrl = null,Object? contributorsUrl = null,Object? deploymentsUrl = null,Object? downloadsUrl = null,Object? eventsUrl = null,Object? forksUrl = null,Object? gitCommitsUrl = null,Object? gitRefsUrl = null,Object? gitTagsUrl = null,Object? gitUrl = null,Object? issueCommentUrl = null,Object? issueEventsUrl = null,Object? issuesUrl = null,Object? keysUrl = null,Object? labelsUrl = null,Object? languagesUrl = null,Object? mergesUrl = null,Object? id = null,Object? notificationsUrl = null,Object? pullsUrl = null,Object? releasesUrl = null,Object? sshUrl = null,Object? stargazersUrl = null,Object? statusesUrl = null,Object? subscribersUrl = null,Object? subscriptionUrl = null,Object? tagsUrl = null,Object? teamsUrl = null,Object? treesUrl = null,Object? cloneUrl = null,Object? mirrorUrl = freezed,Object? hooksUrl = null,Object? svnUrl = null,Object? homepage = freezed,Object? language = freezed,Object? forksCount = null,Object? stargazersCount = null,Object? watchersCount = null,Object? size = null,Object? defaultBranch = null,Object? openIssuesCount = null,Object? watchers = null,Object? openIssues = null,Object? hasIssues = null,Object? hasProjects = null,Object? hasWiki = null,Object? hasPages = null,Object? forks = null,Object? hasDiscussions = null,Object? license = freezed,Object? networkCount = null,Object? subscribersCount = null,Object? disabled = null,Object? updatedAt = null,Object? pushedAt = null,Object? createdAt = null,Object? archived = null,Object? anonymousAccessEnabled = null,Object? permissions = freezed,Object? allowRebaseMerge = freezed,Object? templateRepository = freezed,Object? tempCloneToken = freezed,Object? allowSquashMerge = freezed,Object? allowAutoMerge = freezed,Object? deleteBranchOnMerge = freezed,Object? allowMergeCommit = freezed,Object? allowUpdateBranch = freezed,Object? useSquashPrTitleAsDefault = freezed,Object? squashMergeCommitTitle = freezed,Object? squashMergeCommitMessage = freezed,Object? mergeCommitTitle = freezed,Object? mergeCommitMessage = freezed,Object? allowForking = freezed,Object? webCommitSignoffRequired = freezed,Object? customProperties = freezed,Object? pullRequestCreationPolicy = freezed,Object? hasPullRequests = freezed,Object? organization = freezed,Object? parent = freezed,Object? source = freezed,Object? hasDownloads = freezed,Object? masterBranch = freezed,Object? topics = freezed,Object? isTemplate = freezed,Object? codeOfConduct = freezed,Object? securityAndAnalysis = freezed,Object? visibility = freezed,}) {
  return _then(_FullRepository(
milestonesUrl: null == milestonesUrl ? _self.milestonesUrl : milestonesUrl // ignore: cast_nullable_to_non_nullable
as String,nodeId: null == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as SimpleUser,private: null == private ? _self.private : private // ignore: cast_nullable_to_non_nullable
as bool,htmlUrl: null == htmlUrl ? _self.htmlUrl : htmlUrl // ignore: cast_nullable_to_non_nullable
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
as String,issueEventsUrl: null == issueEventsUrl ? _self.issueEventsUrl : issueEventsUrl // ignore: cast_nullable_to_non_nullable
as String,issuesUrl: null == issuesUrl ? _self.issuesUrl : issuesUrl // ignore: cast_nullable_to_non_nullable
as String,keysUrl: null == keysUrl ? _self.keysUrl : keysUrl // ignore: cast_nullable_to_non_nullable
as String,labelsUrl: null == labelsUrl ? _self.labelsUrl : labelsUrl // ignore: cast_nullable_to_non_nullable
as String,languagesUrl: null == languagesUrl ? _self.languagesUrl : languagesUrl // ignore: cast_nullable_to_non_nullable
as String,mergesUrl: null == mergesUrl ? _self.mergesUrl : mergesUrl // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,notificationsUrl: null == notificationsUrl ? _self.notificationsUrl : notificationsUrl // ignore: cast_nullable_to_non_nullable
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
as int,watchers: null == watchers ? _self.watchers : watchers // ignore: cast_nullable_to_non_nullable
as int,openIssues: null == openIssues ? _self.openIssues : openIssues // ignore: cast_nullable_to_non_nullable
as int,hasIssues: null == hasIssues ? _self.hasIssues : hasIssues // ignore: cast_nullable_to_non_nullable
as bool,hasProjects: null == hasProjects ? _self.hasProjects : hasProjects // ignore: cast_nullable_to_non_nullable
as bool,hasWiki: null == hasWiki ? _self.hasWiki : hasWiki // ignore: cast_nullable_to_non_nullable
as bool,hasPages: null == hasPages ? _self.hasPages : hasPages // ignore: cast_nullable_to_non_nullable
as bool,forks: null == forks ? _self.forks : forks // ignore: cast_nullable_to_non_nullable
as int,hasDiscussions: null == hasDiscussions ? _self.hasDiscussions : hasDiscussions // ignore: cast_nullable_to_non_nullable
as bool,license: freezed == license ? _self.license : license // ignore: cast_nullable_to_non_nullable
as NullableLicenseSimple?,networkCount: null == networkCount ? _self.networkCount : networkCount // ignore: cast_nullable_to_non_nullable
as int,subscribersCount: null == subscribersCount ? _self.subscribersCount : subscribersCount // ignore: cast_nullable_to_non_nullable
as int,disabled: null == disabled ? _self.disabled : disabled // ignore: cast_nullable_to_non_nullable
as bool,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,pushedAt: null == pushedAt ? _self.pushedAt : pushedAt // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,archived: null == archived ? _self.archived : archived // ignore: cast_nullable_to_non_nullable
as bool,anonymousAccessEnabled: null == anonymousAccessEnabled ? _self.anonymousAccessEnabled : anonymousAccessEnabled // ignore: cast_nullable_to_non_nullable
as bool,permissions: freezed == permissions ? _self.permissions : permissions // ignore: cast_nullable_to_non_nullable
as Permissions11?,allowRebaseMerge: freezed == allowRebaseMerge ? _self.allowRebaseMerge : allowRebaseMerge // ignore: cast_nullable_to_non_nullable
as bool?,templateRepository: freezed == templateRepository ? _self.templateRepository : templateRepository // ignore: cast_nullable_to_non_nullable
as NullableRepository?,tempCloneToken: freezed == tempCloneToken ? _self.tempCloneToken : tempCloneToken // ignore: cast_nullable_to_non_nullable
as String?,allowSquashMerge: freezed == allowSquashMerge ? _self.allowSquashMerge : allowSquashMerge // ignore: cast_nullable_to_non_nullable
as bool?,allowAutoMerge: freezed == allowAutoMerge ? _self.allowAutoMerge : allowAutoMerge // ignore: cast_nullable_to_non_nullable
as bool?,deleteBranchOnMerge: freezed == deleteBranchOnMerge ? _self.deleteBranchOnMerge : deleteBranchOnMerge // ignore: cast_nullable_to_non_nullable
as bool?,allowMergeCommit: freezed == allowMergeCommit ? _self.allowMergeCommit : allowMergeCommit // ignore: cast_nullable_to_non_nullable
as bool?,allowUpdateBranch: freezed == allowUpdateBranch ? _self.allowUpdateBranch : allowUpdateBranch // ignore: cast_nullable_to_non_nullable
as bool?,useSquashPrTitleAsDefault: freezed == useSquashPrTitleAsDefault ? _self.useSquashPrTitleAsDefault : useSquashPrTitleAsDefault // ignore: cast_nullable_to_non_nullable
as bool?,squashMergeCommitTitle: freezed == squashMergeCommitTitle ? _self.squashMergeCommitTitle : squashMergeCommitTitle // ignore: cast_nullable_to_non_nullable
as FullRepositorySquashMergeCommitTitle?,squashMergeCommitMessage: freezed == squashMergeCommitMessage ? _self.squashMergeCommitMessage : squashMergeCommitMessage // ignore: cast_nullable_to_non_nullable
as FullRepositorySquashMergeCommitMessage?,mergeCommitTitle: freezed == mergeCommitTitle ? _self.mergeCommitTitle : mergeCommitTitle // ignore: cast_nullable_to_non_nullable
as FullRepositoryMergeCommitTitle?,mergeCommitMessage: freezed == mergeCommitMessage ? _self.mergeCommitMessage : mergeCommitMessage // ignore: cast_nullable_to_non_nullable
as FullRepositoryMergeCommitMessage?,allowForking: freezed == allowForking ? _self.allowForking : allowForking // ignore: cast_nullable_to_non_nullable
as bool?,webCommitSignoffRequired: freezed == webCommitSignoffRequired ? _self.webCommitSignoffRequired : webCommitSignoffRequired // ignore: cast_nullable_to_non_nullable
as bool?,customProperties: freezed == customProperties ? _self.customProperties : customProperties // ignore: cast_nullable_to_non_nullable
as dynamic,pullRequestCreationPolicy: freezed == pullRequestCreationPolicy ? _self.pullRequestCreationPolicy : pullRequestCreationPolicy // ignore: cast_nullable_to_non_nullable
as FullRepositoryPullRequestCreationPolicy?,hasPullRequests: freezed == hasPullRequests ? _self.hasPullRequests : hasPullRequests // ignore: cast_nullable_to_non_nullable
as bool?,organization: freezed == organization ? _self.organization : organization // ignore: cast_nullable_to_non_nullable
as NullableSimpleUser?,parent: freezed == parent ? _self.parent : parent // ignore: cast_nullable_to_non_nullable
as Repository?,source: freezed == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as Repository?,hasDownloads: freezed == hasDownloads ? _self.hasDownloads : hasDownloads // ignore: cast_nullable_to_non_nullable
as bool?,masterBranch: freezed == masterBranch ? _self.masterBranch : masterBranch // ignore: cast_nullable_to_non_nullable
as String?,topics: freezed == topics ? _self._topics : topics // ignore: cast_nullable_to_non_nullable
as List<String>?,isTemplate: freezed == isTemplate ? _self.isTemplate : isTemplate // ignore: cast_nullable_to_non_nullable
as bool?,codeOfConduct: freezed == codeOfConduct ? _self.codeOfConduct : codeOfConduct // ignore: cast_nullable_to_non_nullable
as CodeOfConductSimple?,securityAndAnalysis: freezed == securityAndAnalysis ? _self.securityAndAnalysis : securityAndAnalysis // ignore: cast_nullable_to_non_nullable
as SecurityAndAnalysis?,visibility: freezed == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of FullRepository
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SimpleUserCopyWith<$Res> get owner {
  
  return $SimpleUserCopyWith<$Res>(_self.owner, (value) {
    return _then(_self.copyWith(owner: value));
  });
}/// Create a copy of FullRepository
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
}/// Create a copy of FullRepository
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Permissions11CopyWith<$Res>? get permissions {
    if (_self.permissions == null) {
    return null;
  }

  return $Permissions11CopyWith<$Res>(_self.permissions!, (value) {
    return _then(_self.copyWith(permissions: value));
  });
}/// Create a copy of FullRepository
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NullableRepositoryCopyWith<$Res>? get templateRepository {
    if (_self.templateRepository == null) {
    return null;
  }

  return $NullableRepositoryCopyWith<$Res>(_self.templateRepository!, (value) {
    return _then(_self.copyWith(templateRepository: value));
  });
}/// Create a copy of FullRepository
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NullableSimpleUserCopyWith<$Res>? get organization {
    if (_self.organization == null) {
    return null;
  }

  return $NullableSimpleUserCopyWith<$Res>(_self.organization!, (value) {
    return _then(_self.copyWith(organization: value));
  });
}/// Create a copy of FullRepository
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RepositoryCopyWith<$Res>? get parent {
    if (_self.parent == null) {
    return null;
  }

  return $RepositoryCopyWith<$Res>(_self.parent!, (value) {
    return _then(_self.copyWith(parent: value));
  });
}/// Create a copy of FullRepository
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RepositoryCopyWith<$Res>? get source {
    if (_self.source == null) {
    return null;
  }

  return $RepositoryCopyWith<$Res>(_self.source!, (value) {
    return _then(_self.copyWith(source: value));
  });
}/// Create a copy of FullRepository
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CodeOfConductSimpleCopyWith<$Res>? get codeOfConduct {
    if (_self.codeOfConduct == null) {
    return null;
  }

  return $CodeOfConductSimpleCopyWith<$Res>(_self.codeOfConduct!, (value) {
    return _then(_self.copyWith(codeOfConduct: value));
  });
}/// Create a copy of FullRepository
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SecurityAndAnalysisCopyWith<$Res>? get securityAndAnalysis {
    if (_self.securityAndAnalysis == null) {
    return null;
  }

  return $SecurityAndAnalysisCopyWith<$Res>(_self.securityAndAnalysis!, (value) {
    return _then(_self.copyWith(securityAndAnalysis: value));
  });
}
}

// dart format on
