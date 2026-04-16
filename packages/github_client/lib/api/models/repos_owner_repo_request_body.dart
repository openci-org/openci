// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'visibility.dart';
import 'security_and_analysis.dart';
import 'squash_merge_commit_title.dart';
import 'squash_merge_commit_message.dart';
import 'merge_commit_title.dart';
import 'merge_commit_message.dart';

part 'repos_owner_repo_request_body.freezed.dart';
part 'repos_owner_repo_request_body.g.dart';

@Freezed()
abstract class ReposOwnerRepoRequestBody with _$ReposOwnerRepoRequestBody {
  const factory ReposOwnerRepoRequestBody({
    /// Either `true` to make the Repository private or `false` to make it public. Default: `false`.  .
    /// **Note**: You will get a `422` error if the organization restricts [changing Repository visibility](https://docs.github.com/articles/repository-permission-levels-for-an-organization#changing-the-visibility-of-repositories) to organization owners and a non-owner tries to change the value of private.
    @Default(false) bool private,

    /// Either `true` to enable issues for this Repository or `false` to disable them.
    @JsonKey(name: 'has_issues') @Default(true) bool hasIssues,

    /// Either `true` to enable projects for this Repository or `false` to disable them. **Note:** If you're creating a Repository in an organization that has disabled Repository projects, the default is `false`, and if you pass `true`, the API returns an error.
    @JsonKey(name: 'has_projects') @Default(true) bool hasProjects,

    /// Either `true` to enable the wiki for this Repository or `false` to disable it.
    @JsonKey(name: 'has_wiki') @Default(true) bool hasWiki,

    /// Either `true` to make this repo available as a template Repository or `false` to prevent it.
    @JsonKey(name: 'is_template') @Default(false) bool isTemplate,

    /// Either `true` to allow squash-merging pull requests, or `false` to prevent squash-merging.
    @JsonKey(name: 'allow_squash_merge') @Default(true) bool allowSquashMerge,

    /// Either `true` to allow merging pull requests with a merge commit, or `false` to prevent merging pull requests with merge commits.
    @JsonKey(name: 'allow_merge_commit') @Default(true) bool allowMergeCommit,

    /// Either `true` to allow rebase-merging pull requests, or `false` to prevent rebase-merging.
    @JsonKey(name: 'allow_rebase_merge') @Default(true) bool allowRebaseMerge,

    /// Either `true` to allow AutoMerge on pull requests, or `false` to disallow auto-merge.
    @JsonKey(name: 'allow_auto_merge') @Default(false) bool allowAutoMerge,

    /// Either `true` to allow automatically deleting head branches when pull requests are merged, or `false` to prevent automatic deletion.
    @JsonKey(name: 'delete_branch_on_merge')
    @Default(false)
    bool deleteBranchOnMerge,

    /// Either `true` to always allow a pull request head branch that is behind its base branch to be updated even if it is not required to be up to date before merging, or false otherwise.
    @JsonKey(name: 'allow_update_branch')
    @Default(false)
    bool allowUpdateBranch,

    /// Either `true` to allow squash-merge commits to use pull request title, or `false` to use Commit message. **This property is closing down. Please use `squash_merge_commit_title` instead.
    @JsonKey(name: 'use_squash_pr_title_as_default')
    @Default(false)
    @Deprecated('This is marked as deprecated')
    bool useSquashPrTitleAsDefault,

    /// Whether to archive this repository. `false` will unarchive a previously archived repository.
    @Default(false) bool archived,

    /// Either `true` to allow private forks, or `false` to prevent private forks.
    @JsonKey(name: 'allow_forking') @Default(false) bool allowForking,

    /// Either `true` to require contributors to sign off on web-based commits, or `false` to not require contributors to sign off on web-based commits.
    @JsonKey(name: 'web_commit_signoff_required')
    @Default(false)
    bool webCommitSignoffRequired,

    /// The name of the repository.
    String? name,

    /// A short description of the repository.
    String? description,

    /// A URL with more information about the repository.
    String? homepage,

    /// The visibility of the repository.
    Visibility? visibility,

    /// Specify which security and analysis features to enable or disable for the repository.
    ///
    /// To use this parameter, you must have admin permissions for the Repository or be an owner or security manager for the organization that owns the repository. For more information, see "[Managing security managers in your organization](https://docs.github.com/organizations/managing-peoples-access-to-your-organization-with-roles/managing-security-managers-in-your-organization).".
    ///
    /// For example, to enable GitHub Advanced Security, use this data in the body of the `PATCH` request:.
    /// `{ "security_and_analysis": {"advanced_security": { "status": "enabled" } } }`.
    ///
    /// You can check which security and analysis features are currently enabled by using a `GET /repos/{owner}/{repo}` request.
    @JsonKey(name: 'security_and_analysis')
    SecurityAndAnalysis? securityAndAnalysis,

    /// Updates the default branch for this repository.
    @JsonKey(name: 'default_branch') String? defaultBranch,

    /// Required when using `squash_merge_commit_message`.
    ///
    /// The default value for a squash merge Commit title:.
    ///
    /// - `PR_TITLE` - default to the pull request's title.
    /// - `COMMIT_OR_PR_TITLE` - default to the Commit's title (if only one commit) or the pull request's title (when more than one commit).
    @JsonKey(name: 'squash_merge_commit_title')
    SquashMergeCommitTitle? squashMergeCommitTitle,

    /// The default value for a squash merge Commit message:.
    ///
    /// - `PR_BODY` - default to the pull request's body.
    /// - `COMMIT_MESSAGES` - default to the branch's Commit messages.
    /// - `BLANK` - default to a blank Commit message.
    @JsonKey(name: 'squash_merge_commit_message')
    SquashMergeCommitMessage? squashMergeCommitMessage,

    /// Required when using `merge_commit_message`.
    ///
    /// The default value for a merge Commit title.
    ///
    /// - `PR_TITLE` - default to the pull request's title.
    /// - `MERGE_MESSAGE` - default to the classic title for a merge message (e.g., Merge pull request #123 from branch-name).
    @JsonKey(name: 'merge_commit_title') MergeCommitTitle? mergeCommitTitle,

    /// The default value for a merge Commit message.
    ///
    /// - `PR_TITLE` - default to the pull request's title.
    /// - `PR_BODY` - default to the pull request's body.
    /// - `BLANK` - default to a blank Commit message.
    @JsonKey(name: 'merge_commit_message')
    MergeCommitMessage? mergeCommitMessage,
  }) = _ReposOwnerRepoRequestBody;

  factory ReposOwnerRepoRequestBody.fromJson(Map<String, Object?> json) =>
      _$ReposOwnerRepoRequestBodyFromJson(json);
}
