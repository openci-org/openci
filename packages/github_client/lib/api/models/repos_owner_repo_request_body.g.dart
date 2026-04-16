// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repos_owner_repo_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReposOwnerRepoRequestBody _$ReposOwnerRepoRequestBodyFromJson(
  Map<String, dynamic> json,
) => _ReposOwnerRepoRequestBody(
  private: json['private'] as bool? ?? false,
  hasIssues: json['has_issues'] as bool? ?? true,
  hasProjects: json['has_projects'] as bool? ?? true,
  hasWiki: json['has_wiki'] as bool? ?? true,
  isTemplate: json['is_template'] as bool? ?? false,
  allowSquashMerge: json['allow_squash_merge'] as bool? ?? true,
  allowMergeCommit: json['allow_merge_commit'] as bool? ?? true,
  allowRebaseMerge: json['allow_rebase_merge'] as bool? ?? true,
  allowAutoMerge: json['allow_auto_merge'] as bool? ?? false,
  deleteBranchOnMerge: json['delete_branch_on_merge'] as bool? ?? false,
  allowUpdateBranch: json['allow_update_branch'] as bool? ?? false,
  useSquashPrTitleAsDefault:
      json['use_squash_pr_title_as_default'] as bool? ?? false,
  archived: json['archived'] as bool? ?? false,
  allowForking: json['allow_forking'] as bool? ?? false,
  webCommitSignoffRequired:
      json['web_commit_signoff_required'] as bool? ?? false,
  name: json['name'] as String?,
  description: json['description'] as String?,
  homepage: json['homepage'] as String?,
  visibility: json['visibility'] == null
      ? null
      : Visibility.fromJson(json['visibility'] as String),
  securityAndAnalysis: json['security_and_analysis'] == null
      ? null
      : SecurityAndAnalysis.fromJson(
          json['security_and_analysis'] as Map<String, dynamic>,
        ),
  defaultBranch: json['default_branch'] as String?,
  squashMergeCommitTitle: json['squash_merge_commit_title'] == null
      ? null
      : SquashMergeCommitTitle.fromJson(
          json['squash_merge_commit_title'] as String,
        ),
  squashMergeCommitMessage: json['squash_merge_commit_message'] == null
      ? null
      : SquashMergeCommitMessage.fromJson(
          json['squash_merge_commit_message'] as String,
        ),
  mergeCommitTitle: json['merge_commit_title'] == null
      ? null
      : MergeCommitTitle.fromJson(json['merge_commit_title'] as String),
  mergeCommitMessage: json['merge_commit_message'] == null
      ? null
      : MergeCommitMessage.fromJson(json['merge_commit_message'] as String),
);

Map<String, dynamic> _$ReposOwnerRepoRequestBodyToJson(
  _ReposOwnerRepoRequestBody instance,
) => <String, dynamic>{
  'private': instance.private,
  'has_issues': instance.hasIssues,
  'has_projects': instance.hasProjects,
  'has_wiki': instance.hasWiki,
  'is_template': instance.isTemplate,
  'allow_squash_merge': instance.allowSquashMerge,
  'allow_merge_commit': instance.allowMergeCommit,
  'allow_rebase_merge': instance.allowRebaseMerge,
  'allow_auto_merge': instance.allowAutoMerge,
  'delete_branch_on_merge': instance.deleteBranchOnMerge,
  'allow_update_branch': instance.allowUpdateBranch,
  'use_squash_pr_title_as_default': instance.useSquashPrTitleAsDefault,
  'archived': instance.archived,
  'allow_forking': instance.allowForking,
  'web_commit_signoff_required': instance.webCommitSignoffRequired,
  'name': instance.name,
  'description': instance.description,
  'homepage': instance.homepage,
  'visibility': _$VisibilityEnumMap[instance.visibility],
  'security_and_analysis': instance.securityAndAnalysis,
  'default_branch': instance.defaultBranch,
  'squash_merge_commit_title':
      _$SquashMergeCommitTitleEnumMap[instance.squashMergeCommitTitle],
  'squash_merge_commit_message':
      _$SquashMergeCommitMessageEnumMap[instance.squashMergeCommitMessage],
  'merge_commit_title': _$MergeCommitTitleEnumMap[instance.mergeCommitTitle],
  'merge_commit_message':
      _$MergeCommitMessageEnumMap[instance.mergeCommitMessage],
};

const _$VisibilityEnumMap = {
  Visibility.public: 'public',
  Visibility.private: 'private',
  Visibility.$unknown: r'$unknown',
};

const _$SquashMergeCommitTitleEnumMap = {
  SquashMergeCommitTitle.prTitle: 'PR_TITLE',
  SquashMergeCommitTitle.commitOrPrTitle: 'COMMIT_OR_PR_TITLE',
  SquashMergeCommitTitle.$unknown: r'$unknown',
};

const _$SquashMergeCommitMessageEnumMap = {
  SquashMergeCommitMessage.prBody: 'PR_BODY',
  SquashMergeCommitMessage.commitMessages: 'COMMIT_MESSAGES',
  SquashMergeCommitMessage.blank: 'BLANK',
  SquashMergeCommitMessage.$unknown: r'$unknown',
};

const _$MergeCommitTitleEnumMap = {
  MergeCommitTitle.prTitle: 'PR_TITLE',
  MergeCommitTitle.mergeMessage: 'MERGE_MESSAGE',
  MergeCommitTitle.$unknown: r'$unknown',
};

const _$MergeCommitMessageEnumMap = {
  MergeCommitMessage.prBody: 'PR_BODY',
  MergeCommitMessage.prTitle: 'PR_TITLE',
  MergeCommitMessage.blank: 'BLANK',
  MergeCommitMessage.$unknown: r'$unknown',
};
