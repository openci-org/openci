// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/check_run.dart';
import '../models/repos_owner_repo_check_runs_check_run_id_request_body.dart';
import '../models/repos_owner_repo_check_runs_request_body.dart';

part 'checks_client.g.dart';

@RestApi()
abstract class ChecksClient {
  factory ChecksClient(Dio dio, {String? baseUrl}) = _ChecksClient;

  /// Create a check run.
  ///
  /// Creates a new check run for a specific Commit in a repository.
  ///
  /// To create a check run, you must use a GitHub App. OAuth apps and authenticated users are not able to create a check suite.
  ///
  /// In a check suite, GitHub limits the number of check runs with the same name to 1000. Once these check runs exceed 1000, GitHub will start to automatically delete older check runs.
  ///
  /// > [!NOTE].
  /// > The Checks API only looks for pushes in the Repository where the check suite or check run were created. Pushes to a branch in a forked Repository are not detected and return an empty `pull_requests` array.
  ///
  /// [owner] - The account owner of the repository. The name is not case sensitive.
  ///
  /// [repo] - The name of the Repository without the `.git` extension. The name is not case sensitive.
  @POST('/repos/{owner}/{repo}/check-runs')
  Future<CheckRun> checksCreate({
    @Path('owner') required String owner,
    @Path('repo') required String repo,
    @Body() required ReposOwnerRepoCheckRunsRequestBody body,
  });

  /// Get a check run.
  ///
  /// Gets a single check run using its `id`.
  ///
  /// > [!NOTE].
  /// > The Checks API only looks for pushes in the Repository where the check suite or check run were created. Pushes to a branch in a forked Repository are not detected and return an empty `pull_requests` array.
  ///
  /// OAuth app tokens and personal access tokens (classic) need the `repo` scope to use this endpoint on a private repository.
  ///
  /// [owner] - The account owner of the repository. The name is not case sensitive.
  ///
  /// [repo] - The name of the Repository without the `.git` extension. The name is not case sensitive.
  ///
  /// [checkRunId] - The unique identifier of the check run.
  @GET('/repos/{owner}/{repo}/check-runs/{check_run_id}')
  Future<CheckRun> checksGet({
    @Path('owner') required String owner,
    @Path('repo') required String repo,
    @Path('check_run_id') required int checkRunId,
  });

  /// Update a check run.
  ///
  /// Updates a check run for a specific Commit in a repository.
  ///
  /// > [!NOTE].
  /// > The endpoints to manage checks only look for pushes in the Repository where the check suite or check run were created. Pushes to a branch in a forked Repository are not detected and return an empty `pull_requests` array.
  ///
  /// OAuth apps and personal access tokens (classic) cannot use this endpoint.
  ///
  /// [owner] - The account owner of the repository. The name is not case sensitive.
  ///
  /// [repo] - The name of the Repository without the `.git` extension. The name is not case sensitive.
  ///
  /// [checkRunId] - The unique identifier of the check run.
  @PATCH('/repos/{owner}/{repo}/check-runs/{check_run_id}')
  Future<CheckRun> checksUpdate({
    @Path('owner') required String owner,
    @Path('repo') required String repo,
    @Path('check_run_id') required int checkRunId,
    @Body() required ReposOwnerRepoCheckRunsCheckRunIdRequestBody body,
  });
}
