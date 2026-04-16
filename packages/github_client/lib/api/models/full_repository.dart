// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'code_of_conduct_simple.dart';
import 'full_repository_merge_commit_message.dart';
import 'full_repository_merge_commit_title.dart';
import 'full_repository_pull_request_creation_policy.dart';
import 'full_repository_squash_merge_commit_message.dart';
import 'full_repository_squash_merge_commit_title.dart';
import 'nullable_license_simple.dart';
import 'nullable_repository.dart';
import 'nullable_simple_user.dart';
import 'permissions11.dart';
import 'repository.dart';
import 'security_and_analysis.dart';
import 'simple_user.dart';

part 'full_repository.freezed.dart';
part 'full_repository.g.dart';

/// Full Repository
@Freezed()
abstract class FullRepository with _$FullRepository {
  const factory FullRepository({
    @JsonKey(name: 'milestones_url') required String milestonesUrl,
    @JsonKey(name: 'node_id') required String nodeId,
    required String name,
    @JsonKey(name: 'full_name') required String fullName,
    required SimpleUser owner,
    required bool private,
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
    @JsonKey(name: 'issue_events_url') required String issueEventsUrl,
    @JsonKey(name: 'issues_url') required String issuesUrl,
    @JsonKey(name: 'keys_url') required String keysUrl,
    @JsonKey(name: 'labels_url') required String labelsUrl,
    @JsonKey(name: 'languages_url') required String languagesUrl,
    @JsonKey(name: 'merges_url') required String mergesUrl,
    required int id,
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
    @JsonKey(name: 'default_branch') required String defaultBranch,
    @JsonKey(name: 'open_issues_count') required int openIssuesCount,
    required int watchers,
    @JsonKey(name: 'open_issues') required int openIssues,
    @JsonKey(name: 'has_issues') required bool hasIssues,
    @JsonKey(name: 'has_projects') required bool hasProjects,
    @JsonKey(name: 'has_wiki') required bool hasWiki,
    @JsonKey(name: 'has_pages') required bool hasPages,
    required int forks,
    @JsonKey(name: 'has_discussions') required bool hasDiscussions,
    @JsonKey(name: 'License') required NullableLicenseSimple? license,
    @JsonKey(name: 'network_count') required int networkCount,
    @JsonKey(name: 'subscribers_count') required int subscribersCount,

    /// Returns whether or not this Repository disabled.
    required bool disabled,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'pushed_at') required DateTime pushedAt,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    required bool archived,

    /// Whether anonymous git access is allowed.
    @JsonKey(name: 'anonymous_access_enabled')
    @Default(true)
    bool anonymousAccessEnabled,
    Permissions11? permissions,
    @JsonKey(name: 'allow_rebase_merge') bool? allowRebaseMerge,
    @JsonKey(name: 'template_repository')
    NullableRepository? templateRepository,
    @JsonKey(name: 'temp_clone_token') String? tempCloneToken,
    @JsonKey(name: 'allow_squash_merge') bool? allowSquashMerge,
    @JsonKey(name: 'allow_auto_merge') bool? allowAutoMerge,
    @JsonKey(name: 'delete_branch_on_merge') bool? deleteBranchOnMerge,
    @JsonKey(name: 'allow_merge_commit') bool? allowMergeCommit,
    @JsonKey(name: 'allow_update_branch') bool? allowUpdateBranch,
    @JsonKey(name: 'use_squash_pr_title_as_default')
    bool? useSquashPrTitleAsDefault,

    /// The default value for a squash merge Commit title:.
    ///
    /// - `PR_TITLE` - default to the pull request's title.
    /// - `COMMIT_OR_PR_TITLE` - default to the Commit's title (if only one commit) or the pull request's title (when more than one commit).
    @JsonKey(name: 'squash_merge_commit_title')
    FullRepositorySquashMergeCommitTitle? squashMergeCommitTitle,

    /// The default value for a squash merge Commit message:.
    ///
    /// - `PR_BODY` - default to the pull request's body.
    /// - `COMMIT_MESSAGES` - default to the branch's Commit messages.
    /// - `BLANK` - default to a blank Commit message.
    @JsonKey(name: 'squash_merge_commit_message')
    FullRepositorySquashMergeCommitMessage? squashMergeCommitMessage,

    /// The default value for a merge Commit title.
    ///
    ///   - `PR_TITLE` - default to the pull request's title.
    ///   - `MERGE_MESSAGE` - default to the classic title for a merge message (e.g., Merge pull request #123 from branch-name).
    @JsonKey(name: 'merge_commit_title')
    FullRepositoryMergeCommitTitle? mergeCommitTitle,

    /// The default value for a merge Commit message.
    ///
    /// - `PR_TITLE` - default to the pull request's title.
    /// - `PR_BODY` - default to the pull request's body.
    /// - `BLANK` - default to a blank Commit message.
    @JsonKey(name: 'merge_commit_message')
    FullRepositoryMergeCommitMessage? mergeCommitMessage,
    @JsonKey(name: 'allow_forking') bool? allowForking,
    @JsonKey(name: 'web_commit_signoff_required')
    bool? webCommitSignoffRequired,

    /// The custom properties that were defined for the repository. The keys are the custom property names, and the values are the corresponding custom property values.
    @JsonKey(name: 'custom_properties') dynamic customProperties,

    /// The policy controlling who can create pull requests: all or collaborators_only.
    @JsonKey(name: 'pull_request_creation_policy')
    FullRepositoryPullRequestCreationPolicy? pullRequestCreationPolicy,
    @JsonKey(name: 'has_pull_requests') bool? hasPullRequests,
    NullableSimpleUser? organization,
    Repository? parent,
    Repository? source,
    @JsonKey(name: 'has_downloads') bool? hasDownloads,
    @JsonKey(name: 'master_branch') String? masterBranch,
    List<String>? topics,
    @JsonKey(name: 'is_template') bool? isTemplate,
    @JsonKey(name: 'code_of_conduct') CodeOfConductSimple? codeOfConduct,
    @JsonKey(name: 'security_and_analysis')
    SecurityAndAnalysis? securityAndAnalysis,

    /// The Repository visibility: public, private, or internal.
    String? visibility,
  }) = _FullRepository;

  factory FullRepository.fromJson(Map<String, Object?> json) =>
      _$FullRepositoryFromJson(json);
}
