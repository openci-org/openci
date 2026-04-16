// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'repository.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Repository {

@JsonKey(name: 'forks_url') String? get forksUrl;@JsonKey(name: 'assignees_url') String? get assigneesUrl;@JsonKey(name: 'blobs_url') String? get blobsUrl;@JsonKey(name: 'branches_url') String? get branchesUrl;@JsonKey(name: 'collaborators_url') String? get collaboratorsUrl;@JsonKey(name: 'comments_url') String? get commentsUrl;@JsonKey(name: 'commits_url') String? get commitsUrl;@JsonKey(name: 'compare_url') String? get compareUrl;@JsonKey(name: 'contents_url') String? get contentsUrl;@JsonKey(name: 'contributors_url') String? get contributorsUrl;@JsonKey(name: 'deployments_url') String? get deploymentsUrl; dynamic get description;@JsonKey(name: 'downloads_url') String? get downloadsUrl;@JsonKey(name: 'events_url') String? get eventsUrl; bool? get fork;@JsonKey(name: 'archive_url') String? get archiveUrl;@JsonKey(name: 'full_name') String? get fullName;@JsonKey(name: 'git_commits_url') String? get gitCommitsUrl;@JsonKey(name: 'git_refs_url') String? get gitRefsUrl;@JsonKey(name: 'git_tags_url') String? get gitTagsUrl;@JsonKey(name: 'hooks_url') String? get hooksUrl;@JsonKey(name: 'html_url') String? get htmlUrl; int? get id;@JsonKey(name: 'issue_comment_url') String? get issueCommentUrl;@JsonKey(name: 'issue_events_url') String? get issueEventsUrl;@JsonKey(name: 'issues_url') String? get issuesUrl;@JsonKey(name: 'keys_url') String? get keysUrl;@JsonKey(name: 'labels_url') String? get labelsUrl;@JsonKey(name: 'languages_url') String? get languagesUrl; String? get url;@JsonKey(name: 'milestones_url') String? get milestonesUrl; String? get name;@JsonKey(name: 'node_id') String? get nodeId;@JsonKey(name: 'notifications_url') String? get notificationsUrl; Owner13? get owner; bool? get private;@JsonKey(name: 'pulls_url') String? get pullsUrl;@JsonKey(name: 'releases_url') String? get releasesUrl;@JsonKey(name: 'stargazers_url') String? get stargazersUrl;@JsonKey(name: 'statuses_url') String? get statusesUrl;@JsonKey(name: 'subscribers_url') String? get subscribersUrl;@JsonKey(name: 'subscription_url') String? get subscriptionUrl;@JsonKey(name: 'tags_url') String? get tagsUrl;@JsonKey(name: 'teams_url') String? get teamsUrl;@JsonKey(name: 'trees_url') String? get treesUrl;@JsonKey(name: 'merges_url') String? get mergesUrl;
/// Create a copy of Repository
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RepositoryCopyWith<Repository> get copyWith => _$RepositoryCopyWithImpl<Repository>(this as Repository, _$identity);

  /// Serializes this Repository to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Repository&&(identical(other.forksUrl, forksUrl) || other.forksUrl == forksUrl)&&(identical(other.assigneesUrl, assigneesUrl) || other.assigneesUrl == assigneesUrl)&&(identical(other.blobsUrl, blobsUrl) || other.blobsUrl == blobsUrl)&&(identical(other.branchesUrl, branchesUrl) || other.branchesUrl == branchesUrl)&&(identical(other.collaboratorsUrl, collaboratorsUrl) || other.collaboratorsUrl == collaboratorsUrl)&&(identical(other.commentsUrl, commentsUrl) || other.commentsUrl == commentsUrl)&&(identical(other.commitsUrl, commitsUrl) || other.commitsUrl == commitsUrl)&&(identical(other.compareUrl, compareUrl) || other.compareUrl == compareUrl)&&(identical(other.contentsUrl, contentsUrl) || other.contentsUrl == contentsUrl)&&(identical(other.contributorsUrl, contributorsUrl) || other.contributorsUrl == contributorsUrl)&&(identical(other.deploymentsUrl, deploymentsUrl) || other.deploymentsUrl == deploymentsUrl)&&const DeepCollectionEquality().equals(other.description, description)&&(identical(other.downloadsUrl, downloadsUrl) || other.downloadsUrl == downloadsUrl)&&(identical(other.eventsUrl, eventsUrl) || other.eventsUrl == eventsUrl)&&(identical(other.fork, fork) || other.fork == fork)&&(identical(other.archiveUrl, archiveUrl) || other.archiveUrl == archiveUrl)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.gitCommitsUrl, gitCommitsUrl) || other.gitCommitsUrl == gitCommitsUrl)&&(identical(other.gitRefsUrl, gitRefsUrl) || other.gitRefsUrl == gitRefsUrl)&&(identical(other.gitTagsUrl, gitTagsUrl) || other.gitTagsUrl == gitTagsUrl)&&(identical(other.hooksUrl, hooksUrl) || other.hooksUrl == hooksUrl)&&(identical(other.htmlUrl, htmlUrl) || other.htmlUrl == htmlUrl)&&(identical(other.id, id) || other.id == id)&&(identical(other.issueCommentUrl, issueCommentUrl) || other.issueCommentUrl == issueCommentUrl)&&(identical(other.issueEventsUrl, issueEventsUrl) || other.issueEventsUrl == issueEventsUrl)&&(identical(other.issuesUrl, issuesUrl) || other.issuesUrl == issuesUrl)&&(identical(other.keysUrl, keysUrl) || other.keysUrl == keysUrl)&&(identical(other.labelsUrl, labelsUrl) || other.labelsUrl == labelsUrl)&&(identical(other.languagesUrl, languagesUrl) || other.languagesUrl == languagesUrl)&&(identical(other.url, url) || other.url == url)&&(identical(other.milestonesUrl, milestonesUrl) || other.milestonesUrl == milestonesUrl)&&(identical(other.name, name) || other.name == name)&&(identical(other.nodeId, nodeId) || other.nodeId == nodeId)&&(identical(other.notificationsUrl, notificationsUrl) || other.notificationsUrl == notificationsUrl)&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.private, private) || other.private == private)&&(identical(other.pullsUrl, pullsUrl) || other.pullsUrl == pullsUrl)&&(identical(other.releasesUrl, releasesUrl) || other.releasesUrl == releasesUrl)&&(identical(other.stargazersUrl, stargazersUrl) || other.stargazersUrl == stargazersUrl)&&(identical(other.statusesUrl, statusesUrl) || other.statusesUrl == statusesUrl)&&(identical(other.subscribersUrl, subscribersUrl) || other.subscribersUrl == subscribersUrl)&&(identical(other.subscriptionUrl, subscriptionUrl) || other.subscriptionUrl == subscriptionUrl)&&(identical(other.tagsUrl, tagsUrl) || other.tagsUrl == tagsUrl)&&(identical(other.teamsUrl, teamsUrl) || other.teamsUrl == teamsUrl)&&(identical(other.treesUrl, treesUrl) || other.treesUrl == treesUrl)&&(identical(other.mergesUrl, mergesUrl) || other.mergesUrl == mergesUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,forksUrl,assigneesUrl,blobsUrl,branchesUrl,collaboratorsUrl,commentsUrl,commitsUrl,compareUrl,contentsUrl,contributorsUrl,deploymentsUrl,const DeepCollectionEquality().hash(description),downloadsUrl,eventsUrl,fork,archiveUrl,fullName,gitCommitsUrl,gitRefsUrl,gitTagsUrl,hooksUrl,htmlUrl,id,issueCommentUrl,issueEventsUrl,issuesUrl,keysUrl,labelsUrl,languagesUrl,url,milestonesUrl,name,nodeId,notificationsUrl,owner,private,pullsUrl,releasesUrl,stargazersUrl,statusesUrl,subscribersUrl,subscriptionUrl,tagsUrl,teamsUrl,treesUrl,mergesUrl]);

@override
String toString() {
  return 'Repository(forksUrl: $forksUrl, assigneesUrl: $assigneesUrl, blobsUrl: $blobsUrl, branchesUrl: $branchesUrl, collaboratorsUrl: $collaboratorsUrl, commentsUrl: $commentsUrl, commitsUrl: $commitsUrl, compareUrl: $compareUrl, contentsUrl: $contentsUrl, contributorsUrl: $contributorsUrl, deploymentsUrl: $deploymentsUrl, description: $description, downloadsUrl: $downloadsUrl, eventsUrl: $eventsUrl, fork: $fork, archiveUrl: $archiveUrl, fullName: $fullName, gitCommitsUrl: $gitCommitsUrl, gitRefsUrl: $gitRefsUrl, gitTagsUrl: $gitTagsUrl, hooksUrl: $hooksUrl, htmlUrl: $htmlUrl, id: $id, issueCommentUrl: $issueCommentUrl, issueEventsUrl: $issueEventsUrl, issuesUrl: $issuesUrl, keysUrl: $keysUrl, labelsUrl: $labelsUrl, languagesUrl: $languagesUrl, url: $url, milestonesUrl: $milestonesUrl, name: $name, nodeId: $nodeId, notificationsUrl: $notificationsUrl, owner: $owner, private: $private, pullsUrl: $pullsUrl, releasesUrl: $releasesUrl, stargazersUrl: $stargazersUrl, statusesUrl: $statusesUrl, subscribersUrl: $subscribersUrl, subscriptionUrl: $subscriptionUrl, tagsUrl: $tagsUrl, teamsUrl: $teamsUrl, treesUrl: $treesUrl, mergesUrl: $mergesUrl)';
}


}

/// @nodoc
abstract mixin class $RepositoryCopyWith<$Res>  {
  factory $RepositoryCopyWith(Repository value, $Res Function(Repository) _then) = _$RepositoryCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'forks_url') String? forksUrl,@JsonKey(name: 'assignees_url') String? assigneesUrl,@JsonKey(name: 'blobs_url') String? blobsUrl,@JsonKey(name: 'branches_url') String? branchesUrl,@JsonKey(name: 'collaborators_url') String? collaboratorsUrl,@JsonKey(name: 'comments_url') String? commentsUrl,@JsonKey(name: 'commits_url') String? commitsUrl,@JsonKey(name: 'compare_url') String? compareUrl,@JsonKey(name: 'contents_url') String? contentsUrl,@JsonKey(name: 'contributors_url') String? contributorsUrl,@JsonKey(name: 'deployments_url') String? deploymentsUrl, dynamic description,@JsonKey(name: 'downloads_url') String? downloadsUrl,@JsonKey(name: 'events_url') String? eventsUrl, bool? fork,@JsonKey(name: 'archive_url') String? archiveUrl,@JsonKey(name: 'full_name') String? fullName,@JsonKey(name: 'git_commits_url') String? gitCommitsUrl,@JsonKey(name: 'git_refs_url') String? gitRefsUrl,@JsonKey(name: 'git_tags_url') String? gitTagsUrl,@JsonKey(name: 'hooks_url') String? hooksUrl,@JsonKey(name: 'html_url') String? htmlUrl, int? id,@JsonKey(name: 'issue_comment_url') String? issueCommentUrl,@JsonKey(name: 'issue_events_url') String? issueEventsUrl,@JsonKey(name: 'issues_url') String? issuesUrl,@JsonKey(name: 'keys_url') String? keysUrl,@JsonKey(name: 'labels_url') String? labelsUrl,@JsonKey(name: 'languages_url') String? languagesUrl, String? url,@JsonKey(name: 'milestones_url') String? milestonesUrl, String? name,@JsonKey(name: 'node_id') String? nodeId,@JsonKey(name: 'notifications_url') String? notificationsUrl, Owner13? owner, bool? private,@JsonKey(name: 'pulls_url') String? pullsUrl,@JsonKey(name: 'releases_url') String? releasesUrl,@JsonKey(name: 'stargazers_url') String? stargazersUrl,@JsonKey(name: 'statuses_url') String? statusesUrl,@JsonKey(name: 'subscribers_url') String? subscribersUrl,@JsonKey(name: 'subscription_url') String? subscriptionUrl,@JsonKey(name: 'tags_url') String? tagsUrl,@JsonKey(name: 'teams_url') String? teamsUrl,@JsonKey(name: 'trees_url') String? treesUrl,@JsonKey(name: 'merges_url') String? mergesUrl
});


$Owner13CopyWith<$Res>? get owner;

}
/// @nodoc
class _$RepositoryCopyWithImpl<$Res>
    implements $RepositoryCopyWith<$Res> {
  _$RepositoryCopyWithImpl(this._self, this._then);

  final Repository _self;
  final $Res Function(Repository) _then;

/// Create a copy of Repository
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? forksUrl = freezed,Object? assigneesUrl = freezed,Object? blobsUrl = freezed,Object? branchesUrl = freezed,Object? collaboratorsUrl = freezed,Object? commentsUrl = freezed,Object? commitsUrl = freezed,Object? compareUrl = freezed,Object? contentsUrl = freezed,Object? contributorsUrl = freezed,Object? deploymentsUrl = freezed,Object? description = freezed,Object? downloadsUrl = freezed,Object? eventsUrl = freezed,Object? fork = freezed,Object? archiveUrl = freezed,Object? fullName = freezed,Object? gitCommitsUrl = freezed,Object? gitRefsUrl = freezed,Object? gitTagsUrl = freezed,Object? hooksUrl = freezed,Object? htmlUrl = freezed,Object? id = freezed,Object? issueCommentUrl = freezed,Object? issueEventsUrl = freezed,Object? issuesUrl = freezed,Object? keysUrl = freezed,Object? labelsUrl = freezed,Object? languagesUrl = freezed,Object? url = freezed,Object? milestonesUrl = freezed,Object? name = freezed,Object? nodeId = freezed,Object? notificationsUrl = freezed,Object? owner = freezed,Object? private = freezed,Object? pullsUrl = freezed,Object? releasesUrl = freezed,Object? stargazersUrl = freezed,Object? statusesUrl = freezed,Object? subscribersUrl = freezed,Object? subscriptionUrl = freezed,Object? tagsUrl = freezed,Object? teamsUrl = freezed,Object? treesUrl = freezed,Object? mergesUrl = freezed,}) {
  return _then(_self.copyWith(
forksUrl: freezed == forksUrl ? _self.forksUrl : forksUrl // ignore: cast_nullable_to_non_nullable
as String?,assigneesUrl: freezed == assigneesUrl ? _self.assigneesUrl : assigneesUrl // ignore: cast_nullable_to_non_nullable
as String?,blobsUrl: freezed == blobsUrl ? _self.blobsUrl : blobsUrl // ignore: cast_nullable_to_non_nullable
as String?,branchesUrl: freezed == branchesUrl ? _self.branchesUrl : branchesUrl // ignore: cast_nullable_to_non_nullable
as String?,collaboratorsUrl: freezed == collaboratorsUrl ? _self.collaboratorsUrl : collaboratorsUrl // ignore: cast_nullable_to_non_nullable
as String?,commentsUrl: freezed == commentsUrl ? _self.commentsUrl : commentsUrl // ignore: cast_nullable_to_non_nullable
as String?,commitsUrl: freezed == commitsUrl ? _self.commitsUrl : commitsUrl // ignore: cast_nullable_to_non_nullable
as String?,compareUrl: freezed == compareUrl ? _self.compareUrl : compareUrl // ignore: cast_nullable_to_non_nullable
as String?,contentsUrl: freezed == contentsUrl ? _self.contentsUrl : contentsUrl // ignore: cast_nullable_to_non_nullable
as String?,contributorsUrl: freezed == contributorsUrl ? _self.contributorsUrl : contributorsUrl // ignore: cast_nullable_to_non_nullable
as String?,deploymentsUrl: freezed == deploymentsUrl ? _self.deploymentsUrl : deploymentsUrl // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as dynamic,downloadsUrl: freezed == downloadsUrl ? _self.downloadsUrl : downloadsUrl // ignore: cast_nullable_to_non_nullable
as String?,eventsUrl: freezed == eventsUrl ? _self.eventsUrl : eventsUrl // ignore: cast_nullable_to_non_nullable
as String?,fork: freezed == fork ? _self.fork : fork // ignore: cast_nullable_to_non_nullable
as bool?,archiveUrl: freezed == archiveUrl ? _self.archiveUrl : archiveUrl // ignore: cast_nullable_to_non_nullable
as String?,fullName: freezed == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String?,gitCommitsUrl: freezed == gitCommitsUrl ? _self.gitCommitsUrl : gitCommitsUrl // ignore: cast_nullable_to_non_nullable
as String?,gitRefsUrl: freezed == gitRefsUrl ? _self.gitRefsUrl : gitRefsUrl // ignore: cast_nullable_to_non_nullable
as String?,gitTagsUrl: freezed == gitTagsUrl ? _self.gitTagsUrl : gitTagsUrl // ignore: cast_nullable_to_non_nullable
as String?,hooksUrl: freezed == hooksUrl ? _self.hooksUrl : hooksUrl // ignore: cast_nullable_to_non_nullable
as String?,htmlUrl: freezed == htmlUrl ? _self.htmlUrl : htmlUrl // ignore: cast_nullable_to_non_nullable
as String?,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,issueCommentUrl: freezed == issueCommentUrl ? _self.issueCommentUrl : issueCommentUrl // ignore: cast_nullable_to_non_nullable
as String?,issueEventsUrl: freezed == issueEventsUrl ? _self.issueEventsUrl : issueEventsUrl // ignore: cast_nullable_to_non_nullable
as String?,issuesUrl: freezed == issuesUrl ? _self.issuesUrl : issuesUrl // ignore: cast_nullable_to_non_nullable
as String?,keysUrl: freezed == keysUrl ? _self.keysUrl : keysUrl // ignore: cast_nullable_to_non_nullable
as String?,labelsUrl: freezed == labelsUrl ? _self.labelsUrl : labelsUrl // ignore: cast_nullable_to_non_nullable
as String?,languagesUrl: freezed == languagesUrl ? _self.languagesUrl : languagesUrl // ignore: cast_nullable_to_non_nullable
as String?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,milestonesUrl: freezed == milestonesUrl ? _self.milestonesUrl : milestonesUrl // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,nodeId: freezed == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as String?,notificationsUrl: freezed == notificationsUrl ? _self.notificationsUrl : notificationsUrl // ignore: cast_nullable_to_non_nullable
as String?,owner: freezed == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as Owner13?,private: freezed == private ? _self.private : private // ignore: cast_nullable_to_non_nullable
as bool?,pullsUrl: freezed == pullsUrl ? _self.pullsUrl : pullsUrl // ignore: cast_nullable_to_non_nullable
as String?,releasesUrl: freezed == releasesUrl ? _self.releasesUrl : releasesUrl // ignore: cast_nullable_to_non_nullable
as String?,stargazersUrl: freezed == stargazersUrl ? _self.stargazersUrl : stargazersUrl // ignore: cast_nullable_to_non_nullable
as String?,statusesUrl: freezed == statusesUrl ? _self.statusesUrl : statusesUrl // ignore: cast_nullable_to_non_nullable
as String?,subscribersUrl: freezed == subscribersUrl ? _self.subscribersUrl : subscribersUrl // ignore: cast_nullable_to_non_nullable
as String?,subscriptionUrl: freezed == subscriptionUrl ? _self.subscriptionUrl : subscriptionUrl // ignore: cast_nullable_to_non_nullable
as String?,tagsUrl: freezed == tagsUrl ? _self.tagsUrl : tagsUrl // ignore: cast_nullable_to_non_nullable
as String?,teamsUrl: freezed == teamsUrl ? _self.teamsUrl : teamsUrl // ignore: cast_nullable_to_non_nullable
as String?,treesUrl: freezed == treesUrl ? _self.treesUrl : treesUrl // ignore: cast_nullable_to_non_nullable
as String?,mergesUrl: freezed == mergesUrl ? _self.mergesUrl : mergesUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Repository
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Owner13CopyWith<$Res>? get owner {
    if (_self.owner == null) {
    return null;
  }

  return $Owner13CopyWith<$Res>(_self.owner!, (value) {
    return _then(_self.copyWith(owner: value));
  });
}
}


/// Adds pattern-matching-related methods to [Repository].
extension RepositoryPatterns on Repository {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Repository value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Repository() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Repository value)  $default,){
final _that = this;
switch (_that) {
case _Repository():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Repository value)?  $default,){
final _that = this;
switch (_that) {
case _Repository() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'forks_url')  String? forksUrl, @JsonKey(name: 'assignees_url')  String? assigneesUrl, @JsonKey(name: 'blobs_url')  String? blobsUrl, @JsonKey(name: 'branches_url')  String? branchesUrl, @JsonKey(name: 'collaborators_url')  String? collaboratorsUrl, @JsonKey(name: 'comments_url')  String? commentsUrl, @JsonKey(name: 'commits_url')  String? commitsUrl, @JsonKey(name: 'compare_url')  String? compareUrl, @JsonKey(name: 'contents_url')  String? contentsUrl, @JsonKey(name: 'contributors_url')  String? contributorsUrl, @JsonKey(name: 'deployments_url')  String? deploymentsUrl,  dynamic description, @JsonKey(name: 'downloads_url')  String? downloadsUrl, @JsonKey(name: 'events_url')  String? eventsUrl,  bool? fork, @JsonKey(name: 'archive_url')  String? archiveUrl, @JsonKey(name: 'full_name')  String? fullName, @JsonKey(name: 'git_commits_url')  String? gitCommitsUrl, @JsonKey(name: 'git_refs_url')  String? gitRefsUrl, @JsonKey(name: 'git_tags_url')  String? gitTagsUrl, @JsonKey(name: 'hooks_url')  String? hooksUrl, @JsonKey(name: 'html_url')  String? htmlUrl,  int? id, @JsonKey(name: 'issue_comment_url')  String? issueCommentUrl, @JsonKey(name: 'issue_events_url')  String? issueEventsUrl, @JsonKey(name: 'issues_url')  String? issuesUrl, @JsonKey(name: 'keys_url')  String? keysUrl, @JsonKey(name: 'labels_url')  String? labelsUrl, @JsonKey(name: 'languages_url')  String? languagesUrl,  String? url, @JsonKey(name: 'milestones_url')  String? milestonesUrl,  String? name, @JsonKey(name: 'node_id')  String? nodeId, @JsonKey(name: 'notifications_url')  String? notificationsUrl,  Owner13? owner,  bool? private, @JsonKey(name: 'pulls_url')  String? pullsUrl, @JsonKey(name: 'releases_url')  String? releasesUrl, @JsonKey(name: 'stargazers_url')  String? stargazersUrl, @JsonKey(name: 'statuses_url')  String? statusesUrl, @JsonKey(name: 'subscribers_url')  String? subscribersUrl, @JsonKey(name: 'subscription_url')  String? subscriptionUrl, @JsonKey(name: 'tags_url')  String? tagsUrl, @JsonKey(name: 'teams_url')  String? teamsUrl, @JsonKey(name: 'trees_url')  String? treesUrl, @JsonKey(name: 'merges_url')  String? mergesUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Repository() when $default != null:
return $default(_that.forksUrl,_that.assigneesUrl,_that.blobsUrl,_that.branchesUrl,_that.collaboratorsUrl,_that.commentsUrl,_that.commitsUrl,_that.compareUrl,_that.contentsUrl,_that.contributorsUrl,_that.deploymentsUrl,_that.description,_that.downloadsUrl,_that.eventsUrl,_that.fork,_that.archiveUrl,_that.fullName,_that.gitCommitsUrl,_that.gitRefsUrl,_that.gitTagsUrl,_that.hooksUrl,_that.htmlUrl,_that.id,_that.issueCommentUrl,_that.issueEventsUrl,_that.issuesUrl,_that.keysUrl,_that.labelsUrl,_that.languagesUrl,_that.url,_that.milestonesUrl,_that.name,_that.nodeId,_that.notificationsUrl,_that.owner,_that.private,_that.pullsUrl,_that.releasesUrl,_that.stargazersUrl,_that.statusesUrl,_that.subscribersUrl,_that.subscriptionUrl,_that.tagsUrl,_that.teamsUrl,_that.treesUrl,_that.mergesUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'forks_url')  String? forksUrl, @JsonKey(name: 'assignees_url')  String? assigneesUrl, @JsonKey(name: 'blobs_url')  String? blobsUrl, @JsonKey(name: 'branches_url')  String? branchesUrl, @JsonKey(name: 'collaborators_url')  String? collaboratorsUrl, @JsonKey(name: 'comments_url')  String? commentsUrl, @JsonKey(name: 'commits_url')  String? commitsUrl, @JsonKey(name: 'compare_url')  String? compareUrl, @JsonKey(name: 'contents_url')  String? contentsUrl, @JsonKey(name: 'contributors_url')  String? contributorsUrl, @JsonKey(name: 'deployments_url')  String? deploymentsUrl,  dynamic description, @JsonKey(name: 'downloads_url')  String? downloadsUrl, @JsonKey(name: 'events_url')  String? eventsUrl,  bool? fork, @JsonKey(name: 'archive_url')  String? archiveUrl, @JsonKey(name: 'full_name')  String? fullName, @JsonKey(name: 'git_commits_url')  String? gitCommitsUrl, @JsonKey(name: 'git_refs_url')  String? gitRefsUrl, @JsonKey(name: 'git_tags_url')  String? gitTagsUrl, @JsonKey(name: 'hooks_url')  String? hooksUrl, @JsonKey(name: 'html_url')  String? htmlUrl,  int? id, @JsonKey(name: 'issue_comment_url')  String? issueCommentUrl, @JsonKey(name: 'issue_events_url')  String? issueEventsUrl, @JsonKey(name: 'issues_url')  String? issuesUrl, @JsonKey(name: 'keys_url')  String? keysUrl, @JsonKey(name: 'labels_url')  String? labelsUrl, @JsonKey(name: 'languages_url')  String? languagesUrl,  String? url, @JsonKey(name: 'milestones_url')  String? milestonesUrl,  String? name, @JsonKey(name: 'node_id')  String? nodeId, @JsonKey(name: 'notifications_url')  String? notificationsUrl,  Owner13? owner,  bool? private, @JsonKey(name: 'pulls_url')  String? pullsUrl, @JsonKey(name: 'releases_url')  String? releasesUrl, @JsonKey(name: 'stargazers_url')  String? stargazersUrl, @JsonKey(name: 'statuses_url')  String? statusesUrl, @JsonKey(name: 'subscribers_url')  String? subscribersUrl, @JsonKey(name: 'subscription_url')  String? subscriptionUrl, @JsonKey(name: 'tags_url')  String? tagsUrl, @JsonKey(name: 'teams_url')  String? teamsUrl, @JsonKey(name: 'trees_url')  String? treesUrl, @JsonKey(name: 'merges_url')  String? mergesUrl)  $default,) {final _that = this;
switch (_that) {
case _Repository():
return $default(_that.forksUrl,_that.assigneesUrl,_that.blobsUrl,_that.branchesUrl,_that.collaboratorsUrl,_that.commentsUrl,_that.commitsUrl,_that.compareUrl,_that.contentsUrl,_that.contributorsUrl,_that.deploymentsUrl,_that.description,_that.downloadsUrl,_that.eventsUrl,_that.fork,_that.archiveUrl,_that.fullName,_that.gitCommitsUrl,_that.gitRefsUrl,_that.gitTagsUrl,_that.hooksUrl,_that.htmlUrl,_that.id,_that.issueCommentUrl,_that.issueEventsUrl,_that.issuesUrl,_that.keysUrl,_that.labelsUrl,_that.languagesUrl,_that.url,_that.milestonesUrl,_that.name,_that.nodeId,_that.notificationsUrl,_that.owner,_that.private,_that.pullsUrl,_that.releasesUrl,_that.stargazersUrl,_that.statusesUrl,_that.subscribersUrl,_that.subscriptionUrl,_that.tagsUrl,_that.teamsUrl,_that.treesUrl,_that.mergesUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'forks_url')  String? forksUrl, @JsonKey(name: 'assignees_url')  String? assigneesUrl, @JsonKey(name: 'blobs_url')  String? blobsUrl, @JsonKey(name: 'branches_url')  String? branchesUrl, @JsonKey(name: 'collaborators_url')  String? collaboratorsUrl, @JsonKey(name: 'comments_url')  String? commentsUrl, @JsonKey(name: 'commits_url')  String? commitsUrl, @JsonKey(name: 'compare_url')  String? compareUrl, @JsonKey(name: 'contents_url')  String? contentsUrl, @JsonKey(name: 'contributors_url')  String? contributorsUrl, @JsonKey(name: 'deployments_url')  String? deploymentsUrl,  dynamic description, @JsonKey(name: 'downloads_url')  String? downloadsUrl, @JsonKey(name: 'events_url')  String? eventsUrl,  bool? fork, @JsonKey(name: 'archive_url')  String? archiveUrl, @JsonKey(name: 'full_name')  String? fullName, @JsonKey(name: 'git_commits_url')  String? gitCommitsUrl, @JsonKey(name: 'git_refs_url')  String? gitRefsUrl, @JsonKey(name: 'git_tags_url')  String? gitTagsUrl, @JsonKey(name: 'hooks_url')  String? hooksUrl, @JsonKey(name: 'html_url')  String? htmlUrl,  int? id, @JsonKey(name: 'issue_comment_url')  String? issueCommentUrl, @JsonKey(name: 'issue_events_url')  String? issueEventsUrl, @JsonKey(name: 'issues_url')  String? issuesUrl, @JsonKey(name: 'keys_url')  String? keysUrl, @JsonKey(name: 'labels_url')  String? labelsUrl, @JsonKey(name: 'languages_url')  String? languagesUrl,  String? url, @JsonKey(name: 'milestones_url')  String? milestonesUrl,  String? name, @JsonKey(name: 'node_id')  String? nodeId, @JsonKey(name: 'notifications_url')  String? notificationsUrl,  Owner13? owner,  bool? private, @JsonKey(name: 'pulls_url')  String? pullsUrl, @JsonKey(name: 'releases_url')  String? releasesUrl, @JsonKey(name: 'stargazers_url')  String? stargazersUrl, @JsonKey(name: 'statuses_url')  String? statusesUrl, @JsonKey(name: 'subscribers_url')  String? subscribersUrl, @JsonKey(name: 'subscription_url')  String? subscriptionUrl, @JsonKey(name: 'tags_url')  String? tagsUrl, @JsonKey(name: 'teams_url')  String? teamsUrl, @JsonKey(name: 'trees_url')  String? treesUrl, @JsonKey(name: 'merges_url')  String? mergesUrl)?  $default,) {final _that = this;
switch (_that) {
case _Repository() when $default != null:
return $default(_that.forksUrl,_that.assigneesUrl,_that.blobsUrl,_that.branchesUrl,_that.collaboratorsUrl,_that.commentsUrl,_that.commitsUrl,_that.compareUrl,_that.contentsUrl,_that.contributorsUrl,_that.deploymentsUrl,_that.description,_that.downloadsUrl,_that.eventsUrl,_that.fork,_that.archiveUrl,_that.fullName,_that.gitCommitsUrl,_that.gitRefsUrl,_that.gitTagsUrl,_that.hooksUrl,_that.htmlUrl,_that.id,_that.issueCommentUrl,_that.issueEventsUrl,_that.issuesUrl,_that.keysUrl,_that.labelsUrl,_that.languagesUrl,_that.url,_that.milestonesUrl,_that.name,_that.nodeId,_that.notificationsUrl,_that.owner,_that.private,_that.pullsUrl,_that.releasesUrl,_that.stargazersUrl,_that.statusesUrl,_that.subscribersUrl,_that.subscriptionUrl,_that.tagsUrl,_that.teamsUrl,_that.treesUrl,_that.mergesUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Repository implements Repository {
  const _Repository({@JsonKey(name: 'forks_url') this.forksUrl, @JsonKey(name: 'assignees_url') this.assigneesUrl, @JsonKey(name: 'blobs_url') this.blobsUrl, @JsonKey(name: 'branches_url') this.branchesUrl, @JsonKey(name: 'collaborators_url') this.collaboratorsUrl, @JsonKey(name: 'comments_url') this.commentsUrl, @JsonKey(name: 'commits_url') this.commitsUrl, @JsonKey(name: 'compare_url') this.compareUrl, @JsonKey(name: 'contents_url') this.contentsUrl, @JsonKey(name: 'contributors_url') this.contributorsUrl, @JsonKey(name: 'deployments_url') this.deploymentsUrl, this.description, @JsonKey(name: 'downloads_url') this.downloadsUrl, @JsonKey(name: 'events_url') this.eventsUrl, this.fork, @JsonKey(name: 'archive_url') this.archiveUrl, @JsonKey(name: 'full_name') this.fullName, @JsonKey(name: 'git_commits_url') this.gitCommitsUrl, @JsonKey(name: 'git_refs_url') this.gitRefsUrl, @JsonKey(name: 'git_tags_url') this.gitTagsUrl, @JsonKey(name: 'hooks_url') this.hooksUrl, @JsonKey(name: 'html_url') this.htmlUrl, this.id, @JsonKey(name: 'issue_comment_url') this.issueCommentUrl, @JsonKey(name: 'issue_events_url') this.issueEventsUrl, @JsonKey(name: 'issues_url') this.issuesUrl, @JsonKey(name: 'keys_url') this.keysUrl, @JsonKey(name: 'labels_url') this.labelsUrl, @JsonKey(name: 'languages_url') this.languagesUrl, this.url, @JsonKey(name: 'milestones_url') this.milestonesUrl, this.name, @JsonKey(name: 'node_id') this.nodeId, @JsonKey(name: 'notifications_url') this.notificationsUrl, this.owner, this.private, @JsonKey(name: 'pulls_url') this.pullsUrl, @JsonKey(name: 'releases_url') this.releasesUrl, @JsonKey(name: 'stargazers_url') this.stargazersUrl, @JsonKey(name: 'statuses_url') this.statusesUrl, @JsonKey(name: 'subscribers_url') this.subscribersUrl, @JsonKey(name: 'subscription_url') this.subscriptionUrl, @JsonKey(name: 'tags_url') this.tagsUrl, @JsonKey(name: 'teams_url') this.teamsUrl, @JsonKey(name: 'trees_url') this.treesUrl, @JsonKey(name: 'merges_url') this.mergesUrl});
  factory _Repository.fromJson(Map<String, dynamic> json) => _$RepositoryFromJson(json);

@override@JsonKey(name: 'forks_url') final  String? forksUrl;
@override@JsonKey(name: 'assignees_url') final  String? assigneesUrl;
@override@JsonKey(name: 'blobs_url') final  String? blobsUrl;
@override@JsonKey(name: 'branches_url') final  String? branchesUrl;
@override@JsonKey(name: 'collaborators_url') final  String? collaboratorsUrl;
@override@JsonKey(name: 'comments_url') final  String? commentsUrl;
@override@JsonKey(name: 'commits_url') final  String? commitsUrl;
@override@JsonKey(name: 'compare_url') final  String? compareUrl;
@override@JsonKey(name: 'contents_url') final  String? contentsUrl;
@override@JsonKey(name: 'contributors_url') final  String? contributorsUrl;
@override@JsonKey(name: 'deployments_url') final  String? deploymentsUrl;
@override final  dynamic description;
@override@JsonKey(name: 'downloads_url') final  String? downloadsUrl;
@override@JsonKey(name: 'events_url') final  String? eventsUrl;
@override final  bool? fork;
@override@JsonKey(name: 'archive_url') final  String? archiveUrl;
@override@JsonKey(name: 'full_name') final  String? fullName;
@override@JsonKey(name: 'git_commits_url') final  String? gitCommitsUrl;
@override@JsonKey(name: 'git_refs_url') final  String? gitRefsUrl;
@override@JsonKey(name: 'git_tags_url') final  String? gitTagsUrl;
@override@JsonKey(name: 'hooks_url') final  String? hooksUrl;
@override@JsonKey(name: 'html_url') final  String? htmlUrl;
@override final  int? id;
@override@JsonKey(name: 'issue_comment_url') final  String? issueCommentUrl;
@override@JsonKey(name: 'issue_events_url') final  String? issueEventsUrl;
@override@JsonKey(name: 'issues_url') final  String? issuesUrl;
@override@JsonKey(name: 'keys_url') final  String? keysUrl;
@override@JsonKey(name: 'labels_url') final  String? labelsUrl;
@override@JsonKey(name: 'languages_url') final  String? languagesUrl;
@override final  String? url;
@override@JsonKey(name: 'milestones_url') final  String? milestonesUrl;
@override final  String? name;
@override@JsonKey(name: 'node_id') final  String? nodeId;
@override@JsonKey(name: 'notifications_url') final  String? notificationsUrl;
@override final  Owner13? owner;
@override final  bool? private;
@override@JsonKey(name: 'pulls_url') final  String? pullsUrl;
@override@JsonKey(name: 'releases_url') final  String? releasesUrl;
@override@JsonKey(name: 'stargazers_url') final  String? stargazersUrl;
@override@JsonKey(name: 'statuses_url') final  String? statusesUrl;
@override@JsonKey(name: 'subscribers_url') final  String? subscribersUrl;
@override@JsonKey(name: 'subscription_url') final  String? subscriptionUrl;
@override@JsonKey(name: 'tags_url') final  String? tagsUrl;
@override@JsonKey(name: 'teams_url') final  String? teamsUrl;
@override@JsonKey(name: 'trees_url') final  String? treesUrl;
@override@JsonKey(name: 'merges_url') final  String? mergesUrl;

/// Create a copy of Repository
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RepositoryCopyWith<_Repository> get copyWith => __$RepositoryCopyWithImpl<_Repository>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RepositoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Repository&&(identical(other.forksUrl, forksUrl) || other.forksUrl == forksUrl)&&(identical(other.assigneesUrl, assigneesUrl) || other.assigneesUrl == assigneesUrl)&&(identical(other.blobsUrl, blobsUrl) || other.blobsUrl == blobsUrl)&&(identical(other.branchesUrl, branchesUrl) || other.branchesUrl == branchesUrl)&&(identical(other.collaboratorsUrl, collaboratorsUrl) || other.collaboratorsUrl == collaboratorsUrl)&&(identical(other.commentsUrl, commentsUrl) || other.commentsUrl == commentsUrl)&&(identical(other.commitsUrl, commitsUrl) || other.commitsUrl == commitsUrl)&&(identical(other.compareUrl, compareUrl) || other.compareUrl == compareUrl)&&(identical(other.contentsUrl, contentsUrl) || other.contentsUrl == contentsUrl)&&(identical(other.contributorsUrl, contributorsUrl) || other.contributorsUrl == contributorsUrl)&&(identical(other.deploymentsUrl, deploymentsUrl) || other.deploymentsUrl == deploymentsUrl)&&const DeepCollectionEquality().equals(other.description, description)&&(identical(other.downloadsUrl, downloadsUrl) || other.downloadsUrl == downloadsUrl)&&(identical(other.eventsUrl, eventsUrl) || other.eventsUrl == eventsUrl)&&(identical(other.fork, fork) || other.fork == fork)&&(identical(other.archiveUrl, archiveUrl) || other.archiveUrl == archiveUrl)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.gitCommitsUrl, gitCommitsUrl) || other.gitCommitsUrl == gitCommitsUrl)&&(identical(other.gitRefsUrl, gitRefsUrl) || other.gitRefsUrl == gitRefsUrl)&&(identical(other.gitTagsUrl, gitTagsUrl) || other.gitTagsUrl == gitTagsUrl)&&(identical(other.hooksUrl, hooksUrl) || other.hooksUrl == hooksUrl)&&(identical(other.htmlUrl, htmlUrl) || other.htmlUrl == htmlUrl)&&(identical(other.id, id) || other.id == id)&&(identical(other.issueCommentUrl, issueCommentUrl) || other.issueCommentUrl == issueCommentUrl)&&(identical(other.issueEventsUrl, issueEventsUrl) || other.issueEventsUrl == issueEventsUrl)&&(identical(other.issuesUrl, issuesUrl) || other.issuesUrl == issuesUrl)&&(identical(other.keysUrl, keysUrl) || other.keysUrl == keysUrl)&&(identical(other.labelsUrl, labelsUrl) || other.labelsUrl == labelsUrl)&&(identical(other.languagesUrl, languagesUrl) || other.languagesUrl == languagesUrl)&&(identical(other.url, url) || other.url == url)&&(identical(other.milestonesUrl, milestonesUrl) || other.milestonesUrl == milestonesUrl)&&(identical(other.name, name) || other.name == name)&&(identical(other.nodeId, nodeId) || other.nodeId == nodeId)&&(identical(other.notificationsUrl, notificationsUrl) || other.notificationsUrl == notificationsUrl)&&(identical(other.owner, owner) || other.owner == owner)&&(identical(other.private, private) || other.private == private)&&(identical(other.pullsUrl, pullsUrl) || other.pullsUrl == pullsUrl)&&(identical(other.releasesUrl, releasesUrl) || other.releasesUrl == releasesUrl)&&(identical(other.stargazersUrl, stargazersUrl) || other.stargazersUrl == stargazersUrl)&&(identical(other.statusesUrl, statusesUrl) || other.statusesUrl == statusesUrl)&&(identical(other.subscribersUrl, subscribersUrl) || other.subscribersUrl == subscribersUrl)&&(identical(other.subscriptionUrl, subscriptionUrl) || other.subscriptionUrl == subscriptionUrl)&&(identical(other.tagsUrl, tagsUrl) || other.tagsUrl == tagsUrl)&&(identical(other.teamsUrl, teamsUrl) || other.teamsUrl == teamsUrl)&&(identical(other.treesUrl, treesUrl) || other.treesUrl == treesUrl)&&(identical(other.mergesUrl, mergesUrl) || other.mergesUrl == mergesUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,forksUrl,assigneesUrl,blobsUrl,branchesUrl,collaboratorsUrl,commentsUrl,commitsUrl,compareUrl,contentsUrl,contributorsUrl,deploymentsUrl,const DeepCollectionEquality().hash(description),downloadsUrl,eventsUrl,fork,archiveUrl,fullName,gitCommitsUrl,gitRefsUrl,gitTagsUrl,hooksUrl,htmlUrl,id,issueCommentUrl,issueEventsUrl,issuesUrl,keysUrl,labelsUrl,languagesUrl,url,milestonesUrl,name,nodeId,notificationsUrl,owner,private,pullsUrl,releasesUrl,stargazersUrl,statusesUrl,subscribersUrl,subscriptionUrl,tagsUrl,teamsUrl,treesUrl,mergesUrl]);

@override
String toString() {
  return 'Repository(forksUrl: $forksUrl, assigneesUrl: $assigneesUrl, blobsUrl: $blobsUrl, branchesUrl: $branchesUrl, collaboratorsUrl: $collaboratorsUrl, commentsUrl: $commentsUrl, commitsUrl: $commitsUrl, compareUrl: $compareUrl, contentsUrl: $contentsUrl, contributorsUrl: $contributorsUrl, deploymentsUrl: $deploymentsUrl, description: $description, downloadsUrl: $downloadsUrl, eventsUrl: $eventsUrl, fork: $fork, archiveUrl: $archiveUrl, fullName: $fullName, gitCommitsUrl: $gitCommitsUrl, gitRefsUrl: $gitRefsUrl, gitTagsUrl: $gitTagsUrl, hooksUrl: $hooksUrl, htmlUrl: $htmlUrl, id: $id, issueCommentUrl: $issueCommentUrl, issueEventsUrl: $issueEventsUrl, issuesUrl: $issuesUrl, keysUrl: $keysUrl, labelsUrl: $labelsUrl, languagesUrl: $languagesUrl, url: $url, milestonesUrl: $milestonesUrl, name: $name, nodeId: $nodeId, notificationsUrl: $notificationsUrl, owner: $owner, private: $private, pullsUrl: $pullsUrl, releasesUrl: $releasesUrl, stargazersUrl: $stargazersUrl, statusesUrl: $statusesUrl, subscribersUrl: $subscribersUrl, subscriptionUrl: $subscriptionUrl, tagsUrl: $tagsUrl, teamsUrl: $teamsUrl, treesUrl: $treesUrl, mergesUrl: $mergesUrl)';
}


}

/// @nodoc
abstract mixin class _$RepositoryCopyWith<$Res> implements $RepositoryCopyWith<$Res> {
  factory _$RepositoryCopyWith(_Repository value, $Res Function(_Repository) _then) = __$RepositoryCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'forks_url') String? forksUrl,@JsonKey(name: 'assignees_url') String? assigneesUrl,@JsonKey(name: 'blobs_url') String? blobsUrl,@JsonKey(name: 'branches_url') String? branchesUrl,@JsonKey(name: 'collaborators_url') String? collaboratorsUrl,@JsonKey(name: 'comments_url') String? commentsUrl,@JsonKey(name: 'commits_url') String? commitsUrl,@JsonKey(name: 'compare_url') String? compareUrl,@JsonKey(name: 'contents_url') String? contentsUrl,@JsonKey(name: 'contributors_url') String? contributorsUrl,@JsonKey(name: 'deployments_url') String? deploymentsUrl, dynamic description,@JsonKey(name: 'downloads_url') String? downloadsUrl,@JsonKey(name: 'events_url') String? eventsUrl, bool? fork,@JsonKey(name: 'archive_url') String? archiveUrl,@JsonKey(name: 'full_name') String? fullName,@JsonKey(name: 'git_commits_url') String? gitCommitsUrl,@JsonKey(name: 'git_refs_url') String? gitRefsUrl,@JsonKey(name: 'git_tags_url') String? gitTagsUrl,@JsonKey(name: 'hooks_url') String? hooksUrl,@JsonKey(name: 'html_url') String? htmlUrl, int? id,@JsonKey(name: 'issue_comment_url') String? issueCommentUrl,@JsonKey(name: 'issue_events_url') String? issueEventsUrl,@JsonKey(name: 'issues_url') String? issuesUrl,@JsonKey(name: 'keys_url') String? keysUrl,@JsonKey(name: 'labels_url') String? labelsUrl,@JsonKey(name: 'languages_url') String? languagesUrl, String? url,@JsonKey(name: 'milestones_url') String? milestonesUrl, String? name,@JsonKey(name: 'node_id') String? nodeId,@JsonKey(name: 'notifications_url') String? notificationsUrl, Owner13? owner, bool? private,@JsonKey(name: 'pulls_url') String? pullsUrl,@JsonKey(name: 'releases_url') String? releasesUrl,@JsonKey(name: 'stargazers_url') String? stargazersUrl,@JsonKey(name: 'statuses_url') String? statusesUrl,@JsonKey(name: 'subscribers_url') String? subscribersUrl,@JsonKey(name: 'subscription_url') String? subscriptionUrl,@JsonKey(name: 'tags_url') String? tagsUrl,@JsonKey(name: 'teams_url') String? teamsUrl,@JsonKey(name: 'trees_url') String? treesUrl,@JsonKey(name: 'merges_url') String? mergesUrl
});


@override $Owner13CopyWith<$Res>? get owner;

}
/// @nodoc
class __$RepositoryCopyWithImpl<$Res>
    implements _$RepositoryCopyWith<$Res> {
  __$RepositoryCopyWithImpl(this._self, this._then);

  final _Repository _self;
  final $Res Function(_Repository) _then;

/// Create a copy of Repository
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? forksUrl = freezed,Object? assigneesUrl = freezed,Object? blobsUrl = freezed,Object? branchesUrl = freezed,Object? collaboratorsUrl = freezed,Object? commentsUrl = freezed,Object? commitsUrl = freezed,Object? compareUrl = freezed,Object? contentsUrl = freezed,Object? contributorsUrl = freezed,Object? deploymentsUrl = freezed,Object? description = freezed,Object? downloadsUrl = freezed,Object? eventsUrl = freezed,Object? fork = freezed,Object? archiveUrl = freezed,Object? fullName = freezed,Object? gitCommitsUrl = freezed,Object? gitRefsUrl = freezed,Object? gitTagsUrl = freezed,Object? hooksUrl = freezed,Object? htmlUrl = freezed,Object? id = freezed,Object? issueCommentUrl = freezed,Object? issueEventsUrl = freezed,Object? issuesUrl = freezed,Object? keysUrl = freezed,Object? labelsUrl = freezed,Object? languagesUrl = freezed,Object? url = freezed,Object? milestonesUrl = freezed,Object? name = freezed,Object? nodeId = freezed,Object? notificationsUrl = freezed,Object? owner = freezed,Object? private = freezed,Object? pullsUrl = freezed,Object? releasesUrl = freezed,Object? stargazersUrl = freezed,Object? statusesUrl = freezed,Object? subscribersUrl = freezed,Object? subscriptionUrl = freezed,Object? tagsUrl = freezed,Object? teamsUrl = freezed,Object? treesUrl = freezed,Object? mergesUrl = freezed,}) {
  return _then(_Repository(
forksUrl: freezed == forksUrl ? _self.forksUrl : forksUrl // ignore: cast_nullable_to_non_nullable
as String?,assigneesUrl: freezed == assigneesUrl ? _self.assigneesUrl : assigneesUrl // ignore: cast_nullable_to_non_nullable
as String?,blobsUrl: freezed == blobsUrl ? _self.blobsUrl : blobsUrl // ignore: cast_nullable_to_non_nullable
as String?,branchesUrl: freezed == branchesUrl ? _self.branchesUrl : branchesUrl // ignore: cast_nullable_to_non_nullable
as String?,collaboratorsUrl: freezed == collaboratorsUrl ? _self.collaboratorsUrl : collaboratorsUrl // ignore: cast_nullable_to_non_nullable
as String?,commentsUrl: freezed == commentsUrl ? _self.commentsUrl : commentsUrl // ignore: cast_nullable_to_non_nullable
as String?,commitsUrl: freezed == commitsUrl ? _self.commitsUrl : commitsUrl // ignore: cast_nullable_to_non_nullable
as String?,compareUrl: freezed == compareUrl ? _self.compareUrl : compareUrl // ignore: cast_nullable_to_non_nullable
as String?,contentsUrl: freezed == contentsUrl ? _self.contentsUrl : contentsUrl // ignore: cast_nullable_to_non_nullable
as String?,contributorsUrl: freezed == contributorsUrl ? _self.contributorsUrl : contributorsUrl // ignore: cast_nullable_to_non_nullable
as String?,deploymentsUrl: freezed == deploymentsUrl ? _self.deploymentsUrl : deploymentsUrl // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as dynamic,downloadsUrl: freezed == downloadsUrl ? _self.downloadsUrl : downloadsUrl // ignore: cast_nullable_to_non_nullable
as String?,eventsUrl: freezed == eventsUrl ? _self.eventsUrl : eventsUrl // ignore: cast_nullable_to_non_nullable
as String?,fork: freezed == fork ? _self.fork : fork // ignore: cast_nullable_to_non_nullable
as bool?,archiveUrl: freezed == archiveUrl ? _self.archiveUrl : archiveUrl // ignore: cast_nullable_to_non_nullable
as String?,fullName: freezed == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String?,gitCommitsUrl: freezed == gitCommitsUrl ? _self.gitCommitsUrl : gitCommitsUrl // ignore: cast_nullable_to_non_nullable
as String?,gitRefsUrl: freezed == gitRefsUrl ? _self.gitRefsUrl : gitRefsUrl // ignore: cast_nullable_to_non_nullable
as String?,gitTagsUrl: freezed == gitTagsUrl ? _self.gitTagsUrl : gitTagsUrl // ignore: cast_nullable_to_non_nullable
as String?,hooksUrl: freezed == hooksUrl ? _self.hooksUrl : hooksUrl // ignore: cast_nullable_to_non_nullable
as String?,htmlUrl: freezed == htmlUrl ? _self.htmlUrl : htmlUrl // ignore: cast_nullable_to_non_nullable
as String?,id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,issueCommentUrl: freezed == issueCommentUrl ? _self.issueCommentUrl : issueCommentUrl // ignore: cast_nullable_to_non_nullable
as String?,issueEventsUrl: freezed == issueEventsUrl ? _self.issueEventsUrl : issueEventsUrl // ignore: cast_nullable_to_non_nullable
as String?,issuesUrl: freezed == issuesUrl ? _self.issuesUrl : issuesUrl // ignore: cast_nullable_to_non_nullable
as String?,keysUrl: freezed == keysUrl ? _self.keysUrl : keysUrl // ignore: cast_nullable_to_non_nullable
as String?,labelsUrl: freezed == labelsUrl ? _self.labelsUrl : labelsUrl // ignore: cast_nullable_to_non_nullable
as String?,languagesUrl: freezed == languagesUrl ? _self.languagesUrl : languagesUrl // ignore: cast_nullable_to_non_nullable
as String?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,milestonesUrl: freezed == milestonesUrl ? _self.milestonesUrl : milestonesUrl // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,nodeId: freezed == nodeId ? _self.nodeId : nodeId // ignore: cast_nullable_to_non_nullable
as String?,notificationsUrl: freezed == notificationsUrl ? _self.notificationsUrl : notificationsUrl // ignore: cast_nullable_to_non_nullable
as String?,owner: freezed == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as Owner13?,private: freezed == private ? _self.private : private // ignore: cast_nullable_to_non_nullable
as bool?,pullsUrl: freezed == pullsUrl ? _self.pullsUrl : pullsUrl // ignore: cast_nullable_to_non_nullable
as String?,releasesUrl: freezed == releasesUrl ? _self.releasesUrl : releasesUrl // ignore: cast_nullable_to_non_nullable
as String?,stargazersUrl: freezed == stargazersUrl ? _self.stargazersUrl : stargazersUrl // ignore: cast_nullable_to_non_nullable
as String?,statusesUrl: freezed == statusesUrl ? _self.statusesUrl : statusesUrl // ignore: cast_nullable_to_non_nullable
as String?,subscribersUrl: freezed == subscribersUrl ? _self.subscribersUrl : subscribersUrl // ignore: cast_nullable_to_non_nullable
as String?,subscriptionUrl: freezed == subscriptionUrl ? _self.subscriptionUrl : subscriptionUrl // ignore: cast_nullable_to_non_nullable
as String?,tagsUrl: freezed == tagsUrl ? _self.tagsUrl : tagsUrl // ignore: cast_nullable_to_non_nullable
as String?,teamsUrl: freezed == teamsUrl ? _self.teamsUrl : teamsUrl // ignore: cast_nullable_to_non_nullable
as String?,treesUrl: freezed == treesUrl ? _self.treesUrl : treesUrl // ignore: cast_nullable_to_non_nullable
as String?,mergesUrl: freezed == mergesUrl ? _self.mergesUrl : mergesUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Repository
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$Owner13CopyWith<$Res>? get owner {
    if (_self.owner == null) {
    return null;
  }

  return $Owner13CopyWith<$Res>(_self.owner!, (value) {
    return _then(_self.copyWith(owner: value));
  });
}
}

// dart format on
