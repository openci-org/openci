// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:freezed_annotation/freezed_annotation.dart';

import 'owner13.dart';

part 'repository.freezed.dart';
part 'repository.g.dart';

@Freezed()
abstract class Repository with _$Repository {
  const factory Repository({
    @JsonKey(name: 'forks_url')
    String? forksUrl,
    @JsonKey(name: 'assignees_url')
    String? assigneesUrl,
    @JsonKey(name: 'blobs_url')
    String? blobsUrl,
    @JsonKey(name: 'branches_url')
    String? branchesUrl,
    @JsonKey(name: 'collaborators_url')
    String? collaboratorsUrl,
    @JsonKey(name: 'comments_url')
    String? commentsUrl,
    @JsonKey(name: 'commits_url')
    String? commitsUrl,
    @JsonKey(name: 'compare_url')
    String? compareUrl,
    @JsonKey(name: 'contents_url')
    String? contentsUrl,
    @JsonKey(name: 'contributors_url')
    String? contributorsUrl,
    @JsonKey(name: 'deployments_url')
    String? deploymentsUrl,
    dynamic description,
    @JsonKey(name: 'downloads_url')
    String? downloadsUrl,
    @JsonKey(name: 'events_url')
    String? eventsUrl,
    bool? fork,
    @JsonKey(name: 'archive_url')
    String? archiveUrl,
    @JsonKey(name: 'full_name')
    String? fullName,
    @JsonKey(name: 'git_commits_url')
    String? gitCommitsUrl,
    @JsonKey(name: 'git_refs_url')
    String? gitRefsUrl,
    @JsonKey(name: 'git_tags_url')
    String? gitTagsUrl,
    @JsonKey(name: 'hooks_url')
    String? hooksUrl,
    @JsonKey(name: 'html_url')
    String? htmlUrl,
    int? id,
    @JsonKey(name: 'issue_comment_url')
    String? issueCommentUrl,
    @JsonKey(name: 'issue_events_url')
    String? issueEventsUrl,
    @JsonKey(name: 'issues_url')
    String? issuesUrl,
    @JsonKey(name: 'keys_url')
    String? keysUrl,
    @JsonKey(name: 'labels_url')
    String? labelsUrl,
    @JsonKey(name: 'languages_url')
    String? languagesUrl,
    String? url,
    @JsonKey(name: 'milestones_url')
    String? milestonesUrl,
    String? name,
    @JsonKey(name: 'node_id')
    String? nodeId,
    @JsonKey(name: 'notifications_url')
    String? notificationsUrl,
    Owner13? owner,
    bool? private,
    @JsonKey(name: 'pulls_url')
    String? pullsUrl,
    @JsonKey(name: 'releases_url')
    String? releasesUrl,
    @JsonKey(name: 'stargazers_url')
    String? stargazersUrl,
    @JsonKey(name: 'statuses_url')
    String? statusesUrl,
    @JsonKey(name: 'subscribers_url')
    String? subscribersUrl,
    @JsonKey(name: 'subscription_url')
    String? subscriptionUrl,
    @JsonKey(name: 'tags_url')
    String? tagsUrl,
    @JsonKey(name: 'teams_url')
    String? teamsUrl,
    @JsonKey(name: 'trees_url')
    String? treesUrl,
    @JsonKey(name: 'merges_url')
    String? mergesUrl,
  }) = _Repository;
  
  factory Repository.fromJson(Map<String, Object?> json) => _$RepositoryFromJson(json);
}
