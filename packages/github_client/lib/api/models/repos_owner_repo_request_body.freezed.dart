// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'repos_owner_repo_request_body.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReposOwnerRepoRequestBody {

/// Either `true` to make the Repository private or `false` to make it public. Default: `false`.  .
/// **Note**: You will get a `422` error if the organization restricts [changing Repository visibility](https://docs.github.com/articles/repository-permission-levels-for-an-organization#changing-the-visibility-of-repositories) to organization owners and a non-owner tries to change the value of private.
 bool get private;/// Either `true` to enable issues for this Repository or `false` to disable them.
@JsonKey(name: 'has_issues') bool get hasIssues;/// Either `true` to enable projects for this Repository or `false` to disable them. **Note:** If you're creating a Repository in an organization that has disabled Repository projects, the default is `false`, and if you pass `true`, the API returns an error.
@JsonKey(name: 'has_projects') bool get hasProjects;/// Either `true` to enable the wiki for this Repository or `false` to disable it.
@JsonKey(name: 'has_wiki') bool get hasWiki;/// Either `true` to make this repo available as a template Repository or `false` to prevent it.
@JsonKey(name: 'is_template') bool get isTemplate;/// Either `true` to allow squash-merging pull requests, or `false` to prevent squash-merging.
@JsonKey(name: 'allow_squash_merge') bool get allowSquashMerge;/// Either `true` to allow merging pull requests with a merge commit, or `false` to prevent merging pull requests with merge commits.
@JsonKey(name: 'allow_merge_commit') bool get allowMergeCommit;/// Either `true` to allow rebase-merging pull requests, or `false` to prevent rebase-merging.
@JsonKey(name: 'allow_rebase_merge') bool get allowRebaseMerge;/// Either `true` to allow AutoMerge on pull requests, or `false` to disallow auto-merge.
@JsonKey(name: 'allow_auto_merge') bool get allowAutoMerge;/// Either `true` to allow automatically deleting head branches when pull requests are merged, or `false` to prevent automatic deletion.
@JsonKey(name: 'delete_branch_on_merge') bool get deleteBranchOnMerge;/// Either `true` to always allow a pull request head branch that is behind its base branch to be updated even if it is not required to be up to date before merging, or false otherwise.
@JsonKey(name: 'allow_update_branch') bool get allowUpdateBranch;/// Either `true` to allow squash-merge commits to use pull request title, or `false` to use Commit message. **This property is closing down. Please use `squash_merge_commit_title` instead.
@JsonKey(name: 'use_squash_pr_title_as_default')@Deprecated('This is marked as deprecated') bool get useSquashPrTitleAsDefault;/// Whether to archive this repository. `false` will unarchive a previously archived repository.
 bool get archived;/// Either `true` to allow private forks, or `false` to prevent private forks.
@JsonKey(name: 'allow_forking') bool get allowForking;/// Either `true` to require contributors to sign off on web-based commits, or `false` to not require contributors to sign off on web-based commits.
@JsonKey(name: 'web_commit_signoff_required') bool get webCommitSignoffRequired;/// The name of the repository.
 String? get name;/// A short description of the repository.
 String? get description;/// A URL with more information about the repository.
 String? get homepage;/// The visibility of the repository.
 Visibility? get visibility;/// Specify which security and analysis features to enable or disable for the repository.
///
/// To use this parameter, you must have admin permissions for the Repository or be an owner or security manager for the organization that owns the repository. For more information, see "[Managing security managers in your organization](https://docs.github.com/organizations/managing-peoples-access-to-your-organization-with-roles/managing-security-managers-in-your-organization).".
///
/// For example, to enable GitHub Advanced Security, use this data in the body of the `PATCH` request:.
/// `{ "security_and_analysis": {"advanced_security": { "status": "enabled" } } }`.
///
/// You can check which security and analysis features are currently enabled by using a `GET /repos/{owner}/{repo}` request.
@JsonKey(name: 'security_and_analysis') SecurityAndAnalysis? get securityAndAnalysis;/// Updates the default branch for this repository.
@JsonKey(name: 'default_branch') String? get defaultBranch;/// Required when using `squash_merge_commit_message`.
///
/// The default value for a squash merge Commit title:.
///
/// - `PR_TITLE` - default to the pull request's title.
/// - `COMMIT_OR_PR_TITLE` - default to the Commit's title (if only one commit) or the pull request's title (when more than one commit).
@JsonKey(name: 'squash_merge_commit_title') SquashMergeCommitTitle? get squashMergeCommitTitle;/// The default value for a squash merge Commit message:.
///
/// - `PR_BODY` - default to the pull request's body.
/// - `COMMIT_MESSAGES` - default to the branch's Commit messages.
/// - `BLANK` - default to a blank Commit message.
@JsonKey(name: 'squash_merge_commit_message') SquashMergeCommitMessage? get squashMergeCommitMessage;/// Required when using `merge_commit_message`.
///
/// The default value for a merge Commit title.
///
/// - `PR_TITLE` - default to the pull request's title.
/// - `MERGE_MESSAGE` - default to the classic title for a merge message (e.g., Merge pull request #123 from branch-name).
@JsonKey(name: 'merge_commit_title') MergeCommitTitle? get mergeCommitTitle;/// The default value for a merge Commit message.
///
/// - `PR_TITLE` - default to the pull request's title.
/// - `PR_BODY` - default to the pull request's body.
/// - `BLANK` - default to a blank Commit message.
@JsonKey(name: 'merge_commit_message') MergeCommitMessage? get mergeCommitMessage;
/// Create a copy of ReposOwnerRepoRequestBody
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReposOwnerRepoRequestBodyCopyWith<ReposOwnerRepoRequestBody> get copyWith => _$ReposOwnerRepoRequestBodyCopyWithImpl<ReposOwnerRepoRequestBody>(this as ReposOwnerRepoRequestBody, _$identity);

  /// Serializes this ReposOwnerRepoRequestBody to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReposOwnerRepoRequestBody&&(identical(other.private, private) || other.private == private)&&(identical(other.hasIssues, hasIssues) || other.hasIssues == hasIssues)&&(identical(other.hasProjects, hasProjects) || other.hasProjects == hasProjects)&&(identical(other.hasWiki, hasWiki) || other.hasWiki == hasWiki)&&(identical(other.isTemplate, isTemplate) || other.isTemplate == isTemplate)&&(identical(other.allowSquashMerge, allowSquashMerge) || other.allowSquashMerge == allowSquashMerge)&&(identical(other.allowMergeCommit, allowMergeCommit) || other.allowMergeCommit == allowMergeCommit)&&(identical(other.allowRebaseMerge, allowRebaseMerge) || other.allowRebaseMerge == allowRebaseMerge)&&(identical(other.allowAutoMerge, allowAutoMerge) || other.allowAutoMerge == allowAutoMerge)&&(identical(other.deleteBranchOnMerge, deleteBranchOnMerge) || other.deleteBranchOnMerge == deleteBranchOnMerge)&&(identical(other.allowUpdateBranch, allowUpdateBranch) || other.allowUpdateBranch == allowUpdateBranch)&&(identical(other.useSquashPrTitleAsDefault, useSquashPrTitleAsDefault) || other.useSquashPrTitleAsDefault == useSquashPrTitleAsDefault)&&(identical(other.archived, archived) || other.archived == archived)&&(identical(other.allowForking, allowForking) || other.allowForking == allowForking)&&(identical(other.webCommitSignoffRequired, webCommitSignoffRequired) || other.webCommitSignoffRequired == webCommitSignoffRequired)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.homepage, homepage) || other.homepage == homepage)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.securityAndAnalysis, securityAndAnalysis) || other.securityAndAnalysis == securityAndAnalysis)&&(identical(other.defaultBranch, defaultBranch) || other.defaultBranch == defaultBranch)&&(identical(other.squashMergeCommitTitle, squashMergeCommitTitle) || other.squashMergeCommitTitle == squashMergeCommitTitle)&&(identical(other.squashMergeCommitMessage, squashMergeCommitMessage) || other.squashMergeCommitMessage == squashMergeCommitMessage)&&(identical(other.mergeCommitTitle, mergeCommitTitle) || other.mergeCommitTitle == mergeCommitTitle)&&(identical(other.mergeCommitMessage, mergeCommitMessage) || other.mergeCommitMessage == mergeCommitMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,private,hasIssues,hasProjects,hasWiki,isTemplate,allowSquashMerge,allowMergeCommit,allowRebaseMerge,allowAutoMerge,deleteBranchOnMerge,allowUpdateBranch,useSquashPrTitleAsDefault,archived,allowForking,webCommitSignoffRequired,name,description,homepage,visibility,securityAndAnalysis,defaultBranch,squashMergeCommitTitle,squashMergeCommitMessage,mergeCommitTitle,mergeCommitMessage]);

@override
String toString() {
  return 'ReposOwnerRepoRequestBody(private: $private, hasIssues: $hasIssues, hasProjects: $hasProjects, hasWiki: $hasWiki, isTemplate: $isTemplate, allowSquashMerge: $allowSquashMerge, allowMergeCommit: $allowMergeCommit, allowRebaseMerge: $allowRebaseMerge, allowAutoMerge: $allowAutoMerge, deleteBranchOnMerge: $deleteBranchOnMerge, allowUpdateBranch: $allowUpdateBranch, useSquashPrTitleAsDefault: $useSquashPrTitleAsDefault, archived: $archived, allowForking: $allowForking, webCommitSignoffRequired: $webCommitSignoffRequired, name: $name, description: $description, homepage: $homepage, visibility: $visibility, securityAndAnalysis: $securityAndAnalysis, defaultBranch: $defaultBranch, squashMergeCommitTitle: $squashMergeCommitTitle, squashMergeCommitMessage: $squashMergeCommitMessage, mergeCommitTitle: $mergeCommitTitle, mergeCommitMessage: $mergeCommitMessage)';
}


}

/// @nodoc
abstract mixin class $ReposOwnerRepoRequestBodyCopyWith<$Res>  {
  factory $ReposOwnerRepoRequestBodyCopyWith(ReposOwnerRepoRequestBody value, $Res Function(ReposOwnerRepoRequestBody) _then) = _$ReposOwnerRepoRequestBodyCopyWithImpl;
@useResult
$Res call({
 bool private,@JsonKey(name: 'has_issues') bool hasIssues,@JsonKey(name: 'has_projects') bool hasProjects,@JsonKey(name: 'has_wiki') bool hasWiki,@JsonKey(name: 'is_template') bool isTemplate,@JsonKey(name: 'allow_squash_merge') bool allowSquashMerge,@JsonKey(name: 'allow_merge_commit') bool allowMergeCommit,@JsonKey(name: 'allow_rebase_merge') bool allowRebaseMerge,@JsonKey(name: 'allow_auto_merge') bool allowAutoMerge,@JsonKey(name: 'delete_branch_on_merge') bool deleteBranchOnMerge,@JsonKey(name: 'allow_update_branch') bool allowUpdateBranch,@JsonKey(name: 'use_squash_pr_title_as_default')@Deprecated('This is marked as deprecated') bool useSquashPrTitleAsDefault, bool archived,@JsonKey(name: 'allow_forking') bool allowForking,@JsonKey(name: 'web_commit_signoff_required') bool webCommitSignoffRequired, String? name, String? description, String? homepage, Visibility? visibility,@JsonKey(name: 'security_and_analysis') SecurityAndAnalysis? securityAndAnalysis,@JsonKey(name: 'default_branch') String? defaultBranch,@JsonKey(name: 'squash_merge_commit_title') SquashMergeCommitTitle? squashMergeCommitTitle,@JsonKey(name: 'squash_merge_commit_message') SquashMergeCommitMessage? squashMergeCommitMessage,@JsonKey(name: 'merge_commit_title') MergeCommitTitle? mergeCommitTitle,@JsonKey(name: 'merge_commit_message') MergeCommitMessage? mergeCommitMessage
});


$SecurityAndAnalysisCopyWith<$Res>? get securityAndAnalysis;

}
/// @nodoc
class _$ReposOwnerRepoRequestBodyCopyWithImpl<$Res>
    implements $ReposOwnerRepoRequestBodyCopyWith<$Res> {
  _$ReposOwnerRepoRequestBodyCopyWithImpl(this._self, this._then);

  final ReposOwnerRepoRequestBody _self;
  final $Res Function(ReposOwnerRepoRequestBody) _then;

/// Create a copy of ReposOwnerRepoRequestBody
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? private = null,Object? hasIssues = null,Object? hasProjects = null,Object? hasWiki = null,Object? isTemplate = null,Object? allowSquashMerge = null,Object? allowMergeCommit = null,Object? allowRebaseMerge = null,Object? allowAutoMerge = null,Object? deleteBranchOnMerge = null,Object? allowUpdateBranch = null,Object? useSquashPrTitleAsDefault = null,Object? archived = null,Object? allowForking = null,Object? webCommitSignoffRequired = null,Object? name = freezed,Object? description = freezed,Object? homepage = freezed,Object? visibility = freezed,Object? securityAndAnalysis = freezed,Object? defaultBranch = freezed,Object? squashMergeCommitTitle = freezed,Object? squashMergeCommitMessage = freezed,Object? mergeCommitTitle = freezed,Object? mergeCommitMessage = freezed,}) {
  return _then(_self.copyWith(
private: null == private ? _self.private : private // ignore: cast_nullable_to_non_nullable
as bool,hasIssues: null == hasIssues ? _self.hasIssues : hasIssues // ignore: cast_nullable_to_non_nullable
as bool,hasProjects: null == hasProjects ? _self.hasProjects : hasProjects // ignore: cast_nullable_to_non_nullable
as bool,hasWiki: null == hasWiki ? _self.hasWiki : hasWiki // ignore: cast_nullable_to_non_nullable
as bool,isTemplate: null == isTemplate ? _self.isTemplate : isTemplate // ignore: cast_nullable_to_non_nullable
as bool,allowSquashMerge: null == allowSquashMerge ? _self.allowSquashMerge : allowSquashMerge // ignore: cast_nullable_to_non_nullable
as bool,allowMergeCommit: null == allowMergeCommit ? _self.allowMergeCommit : allowMergeCommit // ignore: cast_nullable_to_non_nullable
as bool,allowRebaseMerge: null == allowRebaseMerge ? _self.allowRebaseMerge : allowRebaseMerge // ignore: cast_nullable_to_non_nullable
as bool,allowAutoMerge: null == allowAutoMerge ? _self.allowAutoMerge : allowAutoMerge // ignore: cast_nullable_to_non_nullable
as bool,deleteBranchOnMerge: null == deleteBranchOnMerge ? _self.deleteBranchOnMerge : deleteBranchOnMerge // ignore: cast_nullable_to_non_nullable
as bool,allowUpdateBranch: null == allowUpdateBranch ? _self.allowUpdateBranch : allowUpdateBranch // ignore: cast_nullable_to_non_nullable
as bool,useSquashPrTitleAsDefault: null == useSquashPrTitleAsDefault ? _self.useSquashPrTitleAsDefault : useSquashPrTitleAsDefault // ignore: cast_nullable_to_non_nullable
as bool,archived: null == archived ? _self.archived : archived // ignore: cast_nullable_to_non_nullable
as bool,allowForking: null == allowForking ? _self.allowForking : allowForking // ignore: cast_nullable_to_non_nullable
as bool,webCommitSignoffRequired: null == webCommitSignoffRequired ? _self.webCommitSignoffRequired : webCommitSignoffRequired // ignore: cast_nullable_to_non_nullable
as bool,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,homepage: freezed == homepage ? _self.homepage : homepage // ignore: cast_nullable_to_non_nullable
as String?,visibility: freezed == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as Visibility?,securityAndAnalysis: freezed == securityAndAnalysis ? _self.securityAndAnalysis : securityAndAnalysis // ignore: cast_nullable_to_non_nullable
as SecurityAndAnalysis?,defaultBranch: freezed == defaultBranch ? _self.defaultBranch : defaultBranch // ignore: cast_nullable_to_non_nullable
as String?,squashMergeCommitTitle: freezed == squashMergeCommitTitle ? _self.squashMergeCommitTitle : squashMergeCommitTitle // ignore: cast_nullable_to_non_nullable
as SquashMergeCommitTitle?,squashMergeCommitMessage: freezed == squashMergeCommitMessage ? _self.squashMergeCommitMessage : squashMergeCommitMessage // ignore: cast_nullable_to_non_nullable
as SquashMergeCommitMessage?,mergeCommitTitle: freezed == mergeCommitTitle ? _self.mergeCommitTitle : mergeCommitTitle // ignore: cast_nullable_to_non_nullable
as MergeCommitTitle?,mergeCommitMessage: freezed == mergeCommitMessage ? _self.mergeCommitMessage : mergeCommitMessage // ignore: cast_nullable_to_non_nullable
as MergeCommitMessage?,
  ));
}
/// Create a copy of ReposOwnerRepoRequestBody
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


/// Adds pattern-matching-related methods to [ReposOwnerRepoRequestBody].
extension ReposOwnerRepoRequestBodyPatterns on ReposOwnerRepoRequestBody {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReposOwnerRepoRequestBody value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReposOwnerRepoRequestBody() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReposOwnerRepoRequestBody value)  $default,){
final _that = this;
switch (_that) {
case _ReposOwnerRepoRequestBody():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReposOwnerRepoRequestBody value)?  $default,){
final _that = this;
switch (_that) {
case _ReposOwnerRepoRequestBody() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool private, @JsonKey(name: 'has_issues')  bool hasIssues, @JsonKey(name: 'has_projects')  bool hasProjects, @JsonKey(name: 'has_wiki')  bool hasWiki, @JsonKey(name: 'is_template')  bool isTemplate, @JsonKey(name: 'allow_squash_merge')  bool allowSquashMerge, @JsonKey(name: 'allow_merge_commit')  bool allowMergeCommit, @JsonKey(name: 'allow_rebase_merge')  bool allowRebaseMerge, @JsonKey(name: 'allow_auto_merge')  bool allowAutoMerge, @JsonKey(name: 'delete_branch_on_merge')  bool deleteBranchOnMerge, @JsonKey(name: 'allow_update_branch')  bool allowUpdateBranch, @JsonKey(name: 'use_squash_pr_title_as_default')@Deprecated('This is marked as deprecated')  bool useSquashPrTitleAsDefault,  bool archived, @JsonKey(name: 'allow_forking')  bool allowForking, @JsonKey(name: 'web_commit_signoff_required')  bool webCommitSignoffRequired,  String? name,  String? description,  String? homepage,  Visibility? visibility, @JsonKey(name: 'security_and_analysis')  SecurityAndAnalysis? securityAndAnalysis, @JsonKey(name: 'default_branch')  String? defaultBranch, @JsonKey(name: 'squash_merge_commit_title')  SquashMergeCommitTitle? squashMergeCommitTitle, @JsonKey(name: 'squash_merge_commit_message')  SquashMergeCommitMessage? squashMergeCommitMessage, @JsonKey(name: 'merge_commit_title')  MergeCommitTitle? mergeCommitTitle, @JsonKey(name: 'merge_commit_message')  MergeCommitMessage? mergeCommitMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReposOwnerRepoRequestBody() when $default != null:
return $default(_that.private,_that.hasIssues,_that.hasProjects,_that.hasWiki,_that.isTemplate,_that.allowSquashMerge,_that.allowMergeCommit,_that.allowRebaseMerge,_that.allowAutoMerge,_that.deleteBranchOnMerge,_that.allowUpdateBranch,_that.useSquashPrTitleAsDefault,_that.archived,_that.allowForking,_that.webCommitSignoffRequired,_that.name,_that.description,_that.homepage,_that.visibility,_that.securityAndAnalysis,_that.defaultBranch,_that.squashMergeCommitTitle,_that.squashMergeCommitMessage,_that.mergeCommitTitle,_that.mergeCommitMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool private, @JsonKey(name: 'has_issues')  bool hasIssues, @JsonKey(name: 'has_projects')  bool hasProjects, @JsonKey(name: 'has_wiki')  bool hasWiki, @JsonKey(name: 'is_template')  bool isTemplate, @JsonKey(name: 'allow_squash_merge')  bool allowSquashMerge, @JsonKey(name: 'allow_merge_commit')  bool allowMergeCommit, @JsonKey(name: 'allow_rebase_merge')  bool allowRebaseMerge, @JsonKey(name: 'allow_auto_merge')  bool allowAutoMerge, @JsonKey(name: 'delete_branch_on_merge')  bool deleteBranchOnMerge, @JsonKey(name: 'allow_update_branch')  bool allowUpdateBranch, @JsonKey(name: 'use_squash_pr_title_as_default')@Deprecated('This is marked as deprecated')  bool useSquashPrTitleAsDefault,  bool archived, @JsonKey(name: 'allow_forking')  bool allowForking, @JsonKey(name: 'web_commit_signoff_required')  bool webCommitSignoffRequired,  String? name,  String? description,  String? homepage,  Visibility? visibility, @JsonKey(name: 'security_and_analysis')  SecurityAndAnalysis? securityAndAnalysis, @JsonKey(name: 'default_branch')  String? defaultBranch, @JsonKey(name: 'squash_merge_commit_title')  SquashMergeCommitTitle? squashMergeCommitTitle, @JsonKey(name: 'squash_merge_commit_message')  SquashMergeCommitMessage? squashMergeCommitMessage, @JsonKey(name: 'merge_commit_title')  MergeCommitTitle? mergeCommitTitle, @JsonKey(name: 'merge_commit_message')  MergeCommitMessage? mergeCommitMessage)  $default,) {final _that = this;
switch (_that) {
case _ReposOwnerRepoRequestBody():
return $default(_that.private,_that.hasIssues,_that.hasProjects,_that.hasWiki,_that.isTemplate,_that.allowSquashMerge,_that.allowMergeCommit,_that.allowRebaseMerge,_that.allowAutoMerge,_that.deleteBranchOnMerge,_that.allowUpdateBranch,_that.useSquashPrTitleAsDefault,_that.archived,_that.allowForking,_that.webCommitSignoffRequired,_that.name,_that.description,_that.homepage,_that.visibility,_that.securityAndAnalysis,_that.defaultBranch,_that.squashMergeCommitTitle,_that.squashMergeCommitMessage,_that.mergeCommitTitle,_that.mergeCommitMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool private, @JsonKey(name: 'has_issues')  bool hasIssues, @JsonKey(name: 'has_projects')  bool hasProjects, @JsonKey(name: 'has_wiki')  bool hasWiki, @JsonKey(name: 'is_template')  bool isTemplate, @JsonKey(name: 'allow_squash_merge')  bool allowSquashMerge, @JsonKey(name: 'allow_merge_commit')  bool allowMergeCommit, @JsonKey(name: 'allow_rebase_merge')  bool allowRebaseMerge, @JsonKey(name: 'allow_auto_merge')  bool allowAutoMerge, @JsonKey(name: 'delete_branch_on_merge')  bool deleteBranchOnMerge, @JsonKey(name: 'allow_update_branch')  bool allowUpdateBranch, @JsonKey(name: 'use_squash_pr_title_as_default')@Deprecated('This is marked as deprecated')  bool useSquashPrTitleAsDefault,  bool archived, @JsonKey(name: 'allow_forking')  bool allowForking, @JsonKey(name: 'web_commit_signoff_required')  bool webCommitSignoffRequired,  String? name,  String? description,  String? homepage,  Visibility? visibility, @JsonKey(name: 'security_and_analysis')  SecurityAndAnalysis? securityAndAnalysis, @JsonKey(name: 'default_branch')  String? defaultBranch, @JsonKey(name: 'squash_merge_commit_title')  SquashMergeCommitTitle? squashMergeCommitTitle, @JsonKey(name: 'squash_merge_commit_message')  SquashMergeCommitMessage? squashMergeCommitMessage, @JsonKey(name: 'merge_commit_title')  MergeCommitTitle? mergeCommitTitle, @JsonKey(name: 'merge_commit_message')  MergeCommitMessage? mergeCommitMessage)?  $default,) {final _that = this;
switch (_that) {
case _ReposOwnerRepoRequestBody() when $default != null:
return $default(_that.private,_that.hasIssues,_that.hasProjects,_that.hasWiki,_that.isTemplate,_that.allowSquashMerge,_that.allowMergeCommit,_that.allowRebaseMerge,_that.allowAutoMerge,_that.deleteBranchOnMerge,_that.allowUpdateBranch,_that.useSquashPrTitleAsDefault,_that.archived,_that.allowForking,_that.webCommitSignoffRequired,_that.name,_that.description,_that.homepage,_that.visibility,_that.securityAndAnalysis,_that.defaultBranch,_that.squashMergeCommitTitle,_that.squashMergeCommitMessage,_that.mergeCommitTitle,_that.mergeCommitMessage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReposOwnerRepoRequestBody implements ReposOwnerRepoRequestBody {
  const _ReposOwnerRepoRequestBody({this.private = false, @JsonKey(name: 'has_issues') this.hasIssues = true, @JsonKey(name: 'has_projects') this.hasProjects = true, @JsonKey(name: 'has_wiki') this.hasWiki = true, @JsonKey(name: 'is_template') this.isTemplate = false, @JsonKey(name: 'allow_squash_merge') this.allowSquashMerge = true, @JsonKey(name: 'allow_merge_commit') this.allowMergeCommit = true, @JsonKey(name: 'allow_rebase_merge') this.allowRebaseMerge = true, @JsonKey(name: 'allow_auto_merge') this.allowAutoMerge = false, @JsonKey(name: 'delete_branch_on_merge') this.deleteBranchOnMerge = false, @JsonKey(name: 'allow_update_branch') this.allowUpdateBranch = false, @JsonKey(name: 'use_squash_pr_title_as_default')@Deprecated('This is marked as deprecated') this.useSquashPrTitleAsDefault = false, this.archived = false, @JsonKey(name: 'allow_forking') this.allowForking = false, @JsonKey(name: 'web_commit_signoff_required') this.webCommitSignoffRequired = false, this.name, this.description, this.homepage, this.visibility, @JsonKey(name: 'security_and_analysis') this.securityAndAnalysis, @JsonKey(name: 'default_branch') this.defaultBranch, @JsonKey(name: 'squash_merge_commit_title') this.squashMergeCommitTitle, @JsonKey(name: 'squash_merge_commit_message') this.squashMergeCommitMessage, @JsonKey(name: 'merge_commit_title') this.mergeCommitTitle, @JsonKey(name: 'merge_commit_message') this.mergeCommitMessage});
  factory _ReposOwnerRepoRequestBody.fromJson(Map<String, dynamic> json) => _$ReposOwnerRepoRequestBodyFromJson(json);

/// Either `true` to make the Repository private or `false` to make it public. Default: `false`.  .
/// **Note**: You will get a `422` error if the organization restricts [changing Repository visibility](https://docs.github.com/articles/repository-permission-levels-for-an-organization#changing-the-visibility-of-repositories) to organization owners and a non-owner tries to change the value of private.
@override@JsonKey() final  bool private;
/// Either `true` to enable issues for this Repository or `false` to disable them.
@override@JsonKey(name: 'has_issues') final  bool hasIssues;
/// Either `true` to enable projects for this Repository or `false` to disable them. **Note:** If you're creating a Repository in an organization that has disabled Repository projects, the default is `false`, and if you pass `true`, the API returns an error.
@override@JsonKey(name: 'has_projects') final  bool hasProjects;
/// Either `true` to enable the wiki for this Repository or `false` to disable it.
@override@JsonKey(name: 'has_wiki') final  bool hasWiki;
/// Either `true` to make this repo available as a template Repository or `false` to prevent it.
@override@JsonKey(name: 'is_template') final  bool isTemplate;
/// Either `true` to allow squash-merging pull requests, or `false` to prevent squash-merging.
@override@JsonKey(name: 'allow_squash_merge') final  bool allowSquashMerge;
/// Either `true` to allow merging pull requests with a merge commit, or `false` to prevent merging pull requests with merge commits.
@override@JsonKey(name: 'allow_merge_commit') final  bool allowMergeCommit;
/// Either `true` to allow rebase-merging pull requests, or `false` to prevent rebase-merging.
@override@JsonKey(name: 'allow_rebase_merge') final  bool allowRebaseMerge;
/// Either `true` to allow AutoMerge on pull requests, or `false` to disallow auto-merge.
@override@JsonKey(name: 'allow_auto_merge') final  bool allowAutoMerge;
/// Either `true` to allow automatically deleting head branches when pull requests are merged, or `false` to prevent automatic deletion.
@override@JsonKey(name: 'delete_branch_on_merge') final  bool deleteBranchOnMerge;
/// Either `true` to always allow a pull request head branch that is behind its base branch to be updated even if it is not required to be up to date before merging, or false otherwise.
@override@JsonKey(name: 'allow_update_branch') final  bool allowUpdateBranch;
/// Either `true` to allow squash-merge commits to use pull request title, or `false` to use Commit message. **This property is closing down. Please use `squash_merge_commit_title` instead.
@override@JsonKey(name: 'use_squash_pr_title_as_default')@Deprecated('This is marked as deprecated') final  bool useSquashPrTitleAsDefault;
/// Whether to archive this repository. `false` will unarchive a previously archived repository.
@override@JsonKey() final  bool archived;
/// Either `true` to allow private forks, or `false` to prevent private forks.
@override@JsonKey(name: 'allow_forking') final  bool allowForking;
/// Either `true` to require contributors to sign off on web-based commits, or `false` to not require contributors to sign off on web-based commits.
@override@JsonKey(name: 'web_commit_signoff_required') final  bool webCommitSignoffRequired;
/// The name of the repository.
@override final  String? name;
/// A short description of the repository.
@override final  String? description;
/// A URL with more information about the repository.
@override final  String? homepage;
/// The visibility of the repository.
@override final  Visibility? visibility;
/// Specify which security and analysis features to enable or disable for the repository.
///
/// To use this parameter, you must have admin permissions for the Repository or be an owner or security manager for the organization that owns the repository. For more information, see "[Managing security managers in your organization](https://docs.github.com/organizations/managing-peoples-access-to-your-organization-with-roles/managing-security-managers-in-your-organization).".
///
/// For example, to enable GitHub Advanced Security, use this data in the body of the `PATCH` request:.
/// `{ "security_and_analysis": {"advanced_security": { "status": "enabled" } } }`.
///
/// You can check which security and analysis features are currently enabled by using a `GET /repos/{owner}/{repo}` request.
@override@JsonKey(name: 'security_and_analysis') final  SecurityAndAnalysis? securityAndAnalysis;
/// Updates the default branch for this repository.
@override@JsonKey(name: 'default_branch') final  String? defaultBranch;
/// Required when using `squash_merge_commit_message`.
///
/// The default value for a squash merge Commit title:.
///
/// - `PR_TITLE` - default to the pull request's title.
/// - `COMMIT_OR_PR_TITLE` - default to the Commit's title (if only one commit) or the pull request's title (when more than one commit).
@override@JsonKey(name: 'squash_merge_commit_title') final  SquashMergeCommitTitle? squashMergeCommitTitle;
/// The default value for a squash merge Commit message:.
///
/// - `PR_BODY` - default to the pull request's body.
/// - `COMMIT_MESSAGES` - default to the branch's Commit messages.
/// - `BLANK` - default to a blank Commit message.
@override@JsonKey(name: 'squash_merge_commit_message') final  SquashMergeCommitMessage? squashMergeCommitMessage;
/// Required when using `merge_commit_message`.
///
/// The default value for a merge Commit title.
///
/// - `PR_TITLE` - default to the pull request's title.
/// - `MERGE_MESSAGE` - default to the classic title for a merge message (e.g., Merge pull request #123 from branch-name).
@override@JsonKey(name: 'merge_commit_title') final  MergeCommitTitle? mergeCommitTitle;
/// The default value for a merge Commit message.
///
/// - `PR_TITLE` - default to the pull request's title.
/// - `PR_BODY` - default to the pull request's body.
/// - `BLANK` - default to a blank Commit message.
@override@JsonKey(name: 'merge_commit_message') final  MergeCommitMessage? mergeCommitMessage;

/// Create a copy of ReposOwnerRepoRequestBody
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReposOwnerRepoRequestBodyCopyWith<_ReposOwnerRepoRequestBody> get copyWith => __$ReposOwnerRepoRequestBodyCopyWithImpl<_ReposOwnerRepoRequestBody>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReposOwnerRepoRequestBodyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReposOwnerRepoRequestBody&&(identical(other.private, private) || other.private == private)&&(identical(other.hasIssues, hasIssues) || other.hasIssues == hasIssues)&&(identical(other.hasProjects, hasProjects) || other.hasProjects == hasProjects)&&(identical(other.hasWiki, hasWiki) || other.hasWiki == hasWiki)&&(identical(other.isTemplate, isTemplate) || other.isTemplate == isTemplate)&&(identical(other.allowSquashMerge, allowSquashMerge) || other.allowSquashMerge == allowSquashMerge)&&(identical(other.allowMergeCommit, allowMergeCommit) || other.allowMergeCommit == allowMergeCommit)&&(identical(other.allowRebaseMerge, allowRebaseMerge) || other.allowRebaseMerge == allowRebaseMerge)&&(identical(other.allowAutoMerge, allowAutoMerge) || other.allowAutoMerge == allowAutoMerge)&&(identical(other.deleteBranchOnMerge, deleteBranchOnMerge) || other.deleteBranchOnMerge == deleteBranchOnMerge)&&(identical(other.allowUpdateBranch, allowUpdateBranch) || other.allowUpdateBranch == allowUpdateBranch)&&(identical(other.useSquashPrTitleAsDefault, useSquashPrTitleAsDefault) || other.useSquashPrTitleAsDefault == useSquashPrTitleAsDefault)&&(identical(other.archived, archived) || other.archived == archived)&&(identical(other.allowForking, allowForking) || other.allowForking == allowForking)&&(identical(other.webCommitSignoffRequired, webCommitSignoffRequired) || other.webCommitSignoffRequired == webCommitSignoffRequired)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.homepage, homepage) || other.homepage == homepage)&&(identical(other.visibility, visibility) || other.visibility == visibility)&&(identical(other.securityAndAnalysis, securityAndAnalysis) || other.securityAndAnalysis == securityAndAnalysis)&&(identical(other.defaultBranch, defaultBranch) || other.defaultBranch == defaultBranch)&&(identical(other.squashMergeCommitTitle, squashMergeCommitTitle) || other.squashMergeCommitTitle == squashMergeCommitTitle)&&(identical(other.squashMergeCommitMessage, squashMergeCommitMessage) || other.squashMergeCommitMessage == squashMergeCommitMessage)&&(identical(other.mergeCommitTitle, mergeCommitTitle) || other.mergeCommitTitle == mergeCommitTitle)&&(identical(other.mergeCommitMessage, mergeCommitMessage) || other.mergeCommitMessage == mergeCommitMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,private,hasIssues,hasProjects,hasWiki,isTemplate,allowSquashMerge,allowMergeCommit,allowRebaseMerge,allowAutoMerge,deleteBranchOnMerge,allowUpdateBranch,useSquashPrTitleAsDefault,archived,allowForking,webCommitSignoffRequired,name,description,homepage,visibility,securityAndAnalysis,defaultBranch,squashMergeCommitTitle,squashMergeCommitMessage,mergeCommitTitle,mergeCommitMessage]);

@override
String toString() {
  return 'ReposOwnerRepoRequestBody(private: $private, hasIssues: $hasIssues, hasProjects: $hasProjects, hasWiki: $hasWiki, isTemplate: $isTemplate, allowSquashMerge: $allowSquashMerge, allowMergeCommit: $allowMergeCommit, allowRebaseMerge: $allowRebaseMerge, allowAutoMerge: $allowAutoMerge, deleteBranchOnMerge: $deleteBranchOnMerge, allowUpdateBranch: $allowUpdateBranch, useSquashPrTitleAsDefault: $useSquashPrTitleAsDefault, archived: $archived, allowForking: $allowForking, webCommitSignoffRequired: $webCommitSignoffRequired, name: $name, description: $description, homepage: $homepage, visibility: $visibility, securityAndAnalysis: $securityAndAnalysis, defaultBranch: $defaultBranch, squashMergeCommitTitle: $squashMergeCommitTitle, squashMergeCommitMessage: $squashMergeCommitMessage, mergeCommitTitle: $mergeCommitTitle, mergeCommitMessage: $mergeCommitMessage)';
}


}

/// @nodoc
abstract mixin class _$ReposOwnerRepoRequestBodyCopyWith<$Res> implements $ReposOwnerRepoRequestBodyCopyWith<$Res> {
  factory _$ReposOwnerRepoRequestBodyCopyWith(_ReposOwnerRepoRequestBody value, $Res Function(_ReposOwnerRepoRequestBody) _then) = __$ReposOwnerRepoRequestBodyCopyWithImpl;
@override @useResult
$Res call({
 bool private,@JsonKey(name: 'has_issues') bool hasIssues,@JsonKey(name: 'has_projects') bool hasProjects,@JsonKey(name: 'has_wiki') bool hasWiki,@JsonKey(name: 'is_template') bool isTemplate,@JsonKey(name: 'allow_squash_merge') bool allowSquashMerge,@JsonKey(name: 'allow_merge_commit') bool allowMergeCommit,@JsonKey(name: 'allow_rebase_merge') bool allowRebaseMerge,@JsonKey(name: 'allow_auto_merge') bool allowAutoMerge,@JsonKey(name: 'delete_branch_on_merge') bool deleteBranchOnMerge,@JsonKey(name: 'allow_update_branch') bool allowUpdateBranch,@JsonKey(name: 'use_squash_pr_title_as_default')@Deprecated('This is marked as deprecated') bool useSquashPrTitleAsDefault, bool archived,@JsonKey(name: 'allow_forking') bool allowForking,@JsonKey(name: 'web_commit_signoff_required') bool webCommitSignoffRequired, String? name, String? description, String? homepage, Visibility? visibility,@JsonKey(name: 'security_and_analysis') SecurityAndAnalysis? securityAndAnalysis,@JsonKey(name: 'default_branch') String? defaultBranch,@JsonKey(name: 'squash_merge_commit_title') SquashMergeCommitTitle? squashMergeCommitTitle,@JsonKey(name: 'squash_merge_commit_message') SquashMergeCommitMessage? squashMergeCommitMessage,@JsonKey(name: 'merge_commit_title') MergeCommitTitle? mergeCommitTitle,@JsonKey(name: 'merge_commit_message') MergeCommitMessage? mergeCommitMessage
});


@override $SecurityAndAnalysisCopyWith<$Res>? get securityAndAnalysis;

}
/// @nodoc
class __$ReposOwnerRepoRequestBodyCopyWithImpl<$Res>
    implements _$ReposOwnerRepoRequestBodyCopyWith<$Res> {
  __$ReposOwnerRepoRequestBodyCopyWithImpl(this._self, this._then);

  final _ReposOwnerRepoRequestBody _self;
  final $Res Function(_ReposOwnerRepoRequestBody) _then;

/// Create a copy of ReposOwnerRepoRequestBody
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? private = null,Object? hasIssues = null,Object? hasProjects = null,Object? hasWiki = null,Object? isTemplate = null,Object? allowSquashMerge = null,Object? allowMergeCommit = null,Object? allowRebaseMerge = null,Object? allowAutoMerge = null,Object? deleteBranchOnMerge = null,Object? allowUpdateBranch = null,Object? useSquashPrTitleAsDefault = null,Object? archived = null,Object? allowForking = null,Object? webCommitSignoffRequired = null,Object? name = freezed,Object? description = freezed,Object? homepage = freezed,Object? visibility = freezed,Object? securityAndAnalysis = freezed,Object? defaultBranch = freezed,Object? squashMergeCommitTitle = freezed,Object? squashMergeCommitMessage = freezed,Object? mergeCommitTitle = freezed,Object? mergeCommitMessage = freezed,}) {
  return _then(_ReposOwnerRepoRequestBody(
private: null == private ? _self.private : private // ignore: cast_nullable_to_non_nullable
as bool,hasIssues: null == hasIssues ? _self.hasIssues : hasIssues // ignore: cast_nullable_to_non_nullable
as bool,hasProjects: null == hasProjects ? _self.hasProjects : hasProjects // ignore: cast_nullable_to_non_nullable
as bool,hasWiki: null == hasWiki ? _self.hasWiki : hasWiki // ignore: cast_nullable_to_non_nullable
as bool,isTemplate: null == isTemplate ? _self.isTemplate : isTemplate // ignore: cast_nullable_to_non_nullable
as bool,allowSquashMerge: null == allowSquashMerge ? _self.allowSquashMerge : allowSquashMerge // ignore: cast_nullable_to_non_nullable
as bool,allowMergeCommit: null == allowMergeCommit ? _self.allowMergeCommit : allowMergeCommit // ignore: cast_nullable_to_non_nullable
as bool,allowRebaseMerge: null == allowRebaseMerge ? _self.allowRebaseMerge : allowRebaseMerge // ignore: cast_nullable_to_non_nullable
as bool,allowAutoMerge: null == allowAutoMerge ? _self.allowAutoMerge : allowAutoMerge // ignore: cast_nullable_to_non_nullable
as bool,deleteBranchOnMerge: null == deleteBranchOnMerge ? _self.deleteBranchOnMerge : deleteBranchOnMerge // ignore: cast_nullable_to_non_nullable
as bool,allowUpdateBranch: null == allowUpdateBranch ? _self.allowUpdateBranch : allowUpdateBranch // ignore: cast_nullable_to_non_nullable
as bool,useSquashPrTitleAsDefault: null == useSquashPrTitleAsDefault ? _self.useSquashPrTitleAsDefault : useSquashPrTitleAsDefault // ignore: cast_nullable_to_non_nullable
as bool,archived: null == archived ? _self.archived : archived // ignore: cast_nullable_to_non_nullable
as bool,allowForking: null == allowForking ? _self.allowForking : allowForking // ignore: cast_nullable_to_non_nullable
as bool,webCommitSignoffRequired: null == webCommitSignoffRequired ? _self.webCommitSignoffRequired : webCommitSignoffRequired // ignore: cast_nullable_to_non_nullable
as bool,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,homepage: freezed == homepage ? _self.homepage : homepage // ignore: cast_nullable_to_non_nullable
as String?,visibility: freezed == visibility ? _self.visibility : visibility // ignore: cast_nullable_to_non_nullable
as Visibility?,securityAndAnalysis: freezed == securityAndAnalysis ? _self.securityAndAnalysis : securityAndAnalysis // ignore: cast_nullable_to_non_nullable
as SecurityAndAnalysis?,defaultBranch: freezed == defaultBranch ? _self.defaultBranch : defaultBranch // ignore: cast_nullable_to_non_nullable
as String?,squashMergeCommitTitle: freezed == squashMergeCommitTitle ? _self.squashMergeCommitTitle : squashMergeCommitTitle // ignore: cast_nullable_to_non_nullable
as SquashMergeCommitTitle?,squashMergeCommitMessage: freezed == squashMergeCommitMessage ? _self.squashMergeCommitMessage : squashMergeCommitMessage // ignore: cast_nullable_to_non_nullable
as SquashMergeCommitMessage?,mergeCommitTitle: freezed == mergeCommitTitle ? _self.mergeCommitTitle : mergeCommitTitle // ignore: cast_nullable_to_non_nullable
as MergeCommitTitle?,mergeCommitMessage: freezed == mergeCommitMessage ? _self.mergeCommitMessage : mergeCommitMessage // ignore: cast_nullable_to_non_nullable
as MergeCommitMessage?,
  ));
}

/// Create a copy of ReposOwnerRepoRequestBody
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
