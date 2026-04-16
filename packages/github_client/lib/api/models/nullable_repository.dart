// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'code_search_index_status2.dart';
import 'nullable_license_simple.dart';
import 'nullable_repository_merge_commit_message.dart';
import 'nullable_repository_merge_commit_title.dart';
import 'nullable_repository_pull_request_creation_policy.dart';
import 'nullable_repository_squash_merge_commit_message.dart';
import 'nullable_repository_squash_merge_commit_title.dart';
import 'permissions10.dart';
import 'simple_user.dart';

part 'nullable_repository.freezed.dart';
part 'nullable_repository.g.dart';

/// A Repository on GitHub.
@Freezed()
abstract class NullableRepository with _$NullableRepository {
  const factory NullableRepository({
    @JsonKey(name: 'issue_events_url') required String issueEventsUrl,
    @JsonKey(name: 'node_id') required String nodeId,

    /// The name of the repository.
    required String name,
    @JsonKey(name: 'full_name') required String fullName,
    @JsonKey(name: 'License') required NullableLicenseSimple? license,
    required int forks,
    required int watchers,
    required SimpleUser owner,
    @JsonKey(name: 'html_url') required String htmlUrl,
    required String? description,
    required bool fork,
    required String url,
    @JsonKey(name: 'archive_url') required String archiveUrl,
    @JsonKey(name: 'assignees_url') required String assigneesUrl,
    @JsonKey(name: 'blobs_url') required String blobsUrl,
    @JsonKey(name: 'branches_url') required String branchesUrl,
    @JsonKey(name: 'collaborators_url') required String collaboratorsUrl,
    @JsonKey(name: 'comments_url') required String commentsUrl,
    @JsonKey(name: 'commits_url') required String commitsUrl,
    @JsonKey(name: 'compare_url') required String compareUrl,
    @JsonKey(name: 'contents_url') required String contentsUrl,
    @JsonKey(name: 'contributors_url') required String contributorsUrl,
    @JsonKey(name: 'deployments_url') required String deploymentsUrl,
    @JsonKey(name: 'downloads_url') required String downloadsUrl,
    @JsonKey(name: 'events_url') required String eventsUrl,
    @JsonKey(name: 'forks_url') required String forksUrl,
    @JsonKey(name: 'git_commits_url') required String gitCommitsUrl,
    @JsonKey(name: 'git_refs_url') required String gitRefsUrl,
    @JsonKey(name: 'git_tags_url') required String gitTagsUrl,
    @JsonKey(name: 'git_url') required String gitUrl,
    @JsonKey(name: 'issue_comment_url') required String issueCommentUrl,

    /// Unique identifier of the Repository
    required int id,
    @JsonKey(name: 'issues_url') required String issuesUrl,
    @JsonKey(name: 'keys_url') required String keysUrl,
    @JsonKey(name: 'labels_url') required String labelsUrl,
    @JsonKey(name: 'languages_url') required String languagesUrl,
    @JsonKey(name: 'merges_url') required String mergesUrl,
    @JsonKey(name: 'milestones_url') required String milestonesUrl,
    @JsonKey(name: 'notifications_url') required String notificationsUrl,
    @JsonKey(name: 'pulls_url') required String pullsUrl,
    @JsonKey(name: 'releases_url') required String releasesUrl,
    @JsonKey(name: 'ssh_url') required String sshUrl,
    @JsonKey(name: 'stargazers_url') required String stargazersUrl,
    @JsonKey(name: 'statuses_url') required String statusesUrl,
    @JsonKey(name: 'subscribers_url') required String subscribersUrl,
    @JsonKey(name: 'subscription_url') required String subscriptionUrl,
    @JsonKey(name: 'tags_url') required String tagsUrl,
    @JsonKey(name: 'teams_url') required String teamsUrl,
    @JsonKey(name: 'trees_url') required String treesUrl,
    @JsonKey(name: 'clone_url') required String cloneUrl,
    @JsonKey(name: 'mirror_url') required String? mirrorUrl,
    @JsonKey(name: 'hooks_url') required String hooksUrl,
    @JsonKey(name: 'svn_url') required String svnUrl,
    required String? homepage,
    @JsonKey(name: 'Language') required String? language,
    @JsonKey(name: 'forks_count') required int forksCount,
    @JsonKey(name: 'stargazers_count') required int stargazersCount,
    @JsonKey(name: 'watchers_count') required int watchersCount,

    /// The size of the repository, in kilobytes. Size is calculated hourly. When a Repository is initially created, the size is 0.
    required int size,

    /// The default branch of the repository.
    @JsonKey(name: 'default_branch') required String defaultBranch,
    @JsonKey(name: 'open_issues_count') required int openIssuesCount,
    @JsonKey(name: 'open_issues') required int openIssues,
    @JsonKey(name: 'created_at') required DateTime? createdAt,
    @JsonKey(name: 'updated_at') required DateTime? updatedAt,
    @JsonKey(name: 'pushed_at') required DateTime? pushedAt,

    /// Returns whether or not this Repository disabled.
    required bool disabled,
    @JsonKey(name: 'has_pages') required bool hasPages,

    /// Whether the wiki is enabled.
    @JsonKey(name: 'has_wiki') @Default(true) bool hasWiki,

    /// Whether downloads are enabled.
    @JsonKey(name: 'has_downloads')
    @Default(true)
    @Deprecated('This is marked as deprecated')
    bool hasDownloads,

    /// Whether discussions are enabled.
    @JsonKey(name: 'has_discussions') @Default(false) bool hasDiscussions,

    /// Whether pull requests are enabled.
    @JsonKey(name: 'has_pull_requests') @Default(true) bool hasPullRequests,

    /// Whether to allow merge commits for pull requests.
    @JsonKey(name: 'allow_merge_commit') @Default(true) bool allowMergeCommit,

    /// Whether the Repository is archived.
    @Default(false) bool archived,

    /// Whether projects are enabled.
    @JsonKey(name: 'has_projects') @Default(true) bool hasProjects,

    /// The Repository visibility: public, private, or internal.
    @Default('public') String visibility,

    /// Whether to require contributors to sign off on web-based commits
    @JsonKey(name: 'web_commit_signoff_required')
    @Default(false)
    bool webCommitSignoffRequired,

    /// Whether this Repository acts as a template that can be used to generate new repositories.
    @JsonKey(name: 'is_template') @Default(false) bool isTemplate,

    /// Whether the Repository is private or public.
    @Default(false) bool private,

    /// Whether to allow rebase merges for pull requests.
    @JsonKey(name: 'allow_rebase_merge') @Default(true) bool allowRebaseMerge,

    /// Whether a squash merge Commit can use the pull request title as default. **This property is closing down. Please use `squash_merge_commit_title` instead.
    @JsonKey(name: 'use_squash_pr_title_as_default')
    @Default(false)
    @Deprecated('This is marked as deprecated')
    bool useSquashPrTitleAsDefault,

    /// Whether to allow squash merges for pull requests.
    @JsonKey(name: 'allow_squash_merge') @Default(true) bool allowSquashMerge,

    /// Whether to allow Auto-merge to be used on pull requests.
    @JsonKey(name: 'allow_auto_merge') @Default(false) bool allowAutoMerge,

    /// Whether to delete head branches when pull requests are merged
    @JsonKey(name: 'delete_branch_on_merge')
    @Default(false)
    bool deleteBranchOnMerge,

    /// Whether or not a pull request head branch that is behind its base branch can always be updated even if it is not required to be up to date before merging.
    @JsonKey(name: 'allow_update_branch')
    @Default(false)
    bool allowUpdateBranch,

    /// Whether issues are enabled.
    @JsonKey(name: 'has_issues') @Default(true) bool hasIssues,

    /// The default value for a squash merge Commit title:.
    ///
    /// - `PR_TITLE` - default to the pull request's title.
    /// - `COMMIT_OR_PR_TITLE` - default to the Commit's title (if only one commit) or the pull request's title (when more than one commit).
    @JsonKey(name: 'squash_merge_commit_title')
    NullableRepositorySquashMergeCommitTitle? squashMergeCommitTitle,

    /// The default value for a squash merge Commit message:.
    ///
    /// - `PR_BODY` - default to the pull request's body.
    /// - `COMMIT_MESSAGES` - default to the branch's Commit messages.
    /// - `BLANK` - default to a blank Commit message.
    @JsonKey(name: 'squash_merge_commit_message')
    NullableRepositorySquashMergeCommitMessage? squashMergeCommitMessage,

    /// The default value for a merge Commit title.
    ///
    /// - `PR_TITLE` - default to the pull request's title.
    /// - `MERGE_MESSAGE` - default to the classic title for a merge message (e.g., Merge pull request #123 from branch-name).
    @JsonKey(name: 'merge_commit_title')
    NullableRepositoryMergeCommitTitle? mergeCommitTitle,

    /// The default value for a merge Commit message.
    ///
    /// - `PR_TITLE` - default to the pull request's title.
    /// - `PR_BODY` - default to the pull request's body.
    /// - `BLANK` - default to a blank Commit message.
    @JsonKey(name: 'merge_commit_message')
    NullableRepositoryMergeCommitMessage? mergeCommitMessage,

    /// The policy controlling who can create pull requests: all or collaborators_only.
    @JsonKey(name: 'pull_request_creation_policy')
    NullableRepositoryPullRequestCreationPolicy? pullRequestCreationPolicy,

    /// Whether to allow forking this repo
    @JsonKey(name: 'allow_forking') bool? allowForking,

    /// The Status of the code search index for this Repository
    @JsonKey(name: 'code_search_index_status')
    CodeSearchIndexStatus2? codeSearchIndexStatus,
    List<String>? topics,
    Permissions10? permissions,
    @JsonKey(name: 'master_branch') String? masterBranch,
    @JsonKey(name: 'starred_at') String? starredAt,

    /// Whether anonymous git access is enabled for this Repository
    @JsonKey(name: 'anonymous_access_enabled') bool? anonymousAccessEnabled,
    @JsonKey(name: 'temp_clone_token') String? tempCloneToken,
  }) = _NullableRepository;

  factory NullableRepository.fromJson(Map<String, Object?> json) =>
      _$NullableRepositoryFromJson(json);
}
