// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/commit.dart';
import '../models/full_repository.dart';
import '../models/repos_owner_repo_request_body.dart';

part 'repos_client.g.dart';

@RestApi()
abstract class ReposClient {
  factory ReposClient(Dio dio, {String? baseUrl}) = _ReposClient;

  /// Get a Repository.
  ///
  /// The `parent` and `source` objects are present when the Repository is a fork. `parent` is the Repository this Repository was forked from, `source` is the ultimate source for the network.
  ///
  /// > [!NOTE].
  /// > - In order to see the `security_and_analysis` block for a Repository you must have admin permissions for the Repository or be an owner or security manager for the organization that owns the repository. For more information, see "[Managing security managers in your organization](https://docs.github.com/organizations/managing-peoples-access-to-your-organization-with-roles/managing-security-managers-in-your-organization).".
  /// > - To view merge-related settings, you must have the `contents:read` and `contents:write` permissions.
  ///
  /// [owner] - The account owner of the repository. The name is not case sensitive.
  ///
  /// [repo] - The name of the Repository without the `.git` extension. The name is not case sensitive.
  @GET('/repos/{owner}/{repo}')
  Future<FullRepository> reposGet({
    @Path('owner') required String owner,
    @Path('repo') required String repo,
  });

  /// Update a Repository.
  ///
  /// **Note**: To edit a Repository's topics, use the [Replace all Repository topics](https://docs.github.com/rest/repos/repos#replace-all-repository-topics) endpoint.
  ///
  /// [owner] - The account owner of the repository. The name is not case sensitive.
  ///
  /// [repo] - The name of the Repository without the `.git` extension. The name is not case sensitive.
  @PATCH('/repos/{owner}/{repo}')
  Future<FullRepository> reposUpdate({
    @Path('owner') required String owner,
    @Path('repo') required String repo,
    @Body() ReposOwnerRepoRequestBody? body,
  });

  /// Delete a Repository.
  ///
  /// Deleting a Repository requires admin access.
  ///
  /// If an organization owner has configured the organization to prevent members from deleting organization-owned.
  /// repositories, you will get a `403 Forbidden` response.
  ///
  /// OAuth app tokens and personal access tokens (classic) need the `delete_repo` scope to use this endpoint.
  ///
  /// [owner] - The account owner of the repository. The name is not case sensitive.
  ///
  /// [repo] - The name of the Repository without the `.git` extension. The name is not case sensitive.
  @DELETE('/repos/{owner}/{repo}')
  Future<void> reposDelete({
    @Path('owner') required String owner,
    @Path('repo') required String repo,
  });

  /// Get a Commit.
  ///
  /// Returns the contents of a single Commit reference. You must have `read` access for the Repository to use this endpoint.
  ///
  /// > [!NOTE].
  /// > If there are more than 300 files in the Commit diff and the default JSON media type is requested, the response will include pagination Link headers for the remaining files, up to a limit of 3000 files. Each Page contains the static Commit information, and the only changes are to the file listing.
  ///
  /// This endpoint supports the following custom media types. For more information, see "[Media types](https://docs.github.com/rest/using-the-rest-api/getting-started-with-the-rest-api#media-types)." Pagination query parameters are not supported for these media types.
  ///
  /// - **`application/vnd.github.diff`**: Returns the diff of the commit. Larger diffs may time out and return a 5xx Status code.
  /// - **`application/vnd.github.patch`**: Returns the patch of the commit. Diffs with binary data will have no `patch` property. Larger diffs may time out and return a 5xx Status code.
  /// - **`application/vnd.github.sha`**: Returns the Commit's SHA-1 hash. You can use this endpoint to check if a remote reference's SHA-1 hash is the same as your local reference's SHA-1 hash by providing the local SHA-1 reference as the ETag.
  ///
  /// **Signature Verification object**.
  ///
  /// The response will include a `verification` object that describes the result of verifying the Commit's signature. The following fields are included in the `verification` object:.
  ///
  /// | Name | Type | Description |.
  /// | ---- | ---- | ----------- |.
  /// | `verified` | `boolean` | Indicates whether GitHub considers the signature in this Commit to be verified. |.
  /// | `reason` | `string` | The reason for verified value. Possible values and their meanings are enumerated in table below. |.
  /// | `signature` | `string` | The signature that was extracted from the commit. |.
  /// | `payload` | `string` | The value that was signed. |.
  /// | `verified_at` | `string` | The date the signature was verified by GitHub. |.
  ///
  /// These are the possible values for `reason` in the `verification` object:.
  ///
  /// | Value | Description |.
  /// | ----- | ----------- |.
  /// | `expired_key` | The Key that made the signature is expired. |.
  /// | `not_signing_key` | The "signing" flag is not among the usage flags in the GPG Key that made the signature. |.
  /// | `gpgverify_error` | There was an error communicating with the signature Verification service. |.
  /// | `gpgverify_unavailable` | The signature Verification service is currently unavailable. |.
  /// | `unsigned` | The object does not include a signature. |.
  /// | `unknown_signature_type` | A non-PGP signature was found in the commit. |.
  /// | `no_user` | No user was associated with the `committer` Email address in the commit. |.
  /// | `unverified_email` | The `committer` Email address in the Commit was associated with a user, but the Email address is not verified on their account. |.
  /// | `bad_email` | The `committer` Email address in the Commit is not included in the identities of the PGP Key that made the signature. |.
  /// | `unknown_key` | The Key that made the signature has not been registered with any user's account. |.
  /// | `malformed_signature` | There was an error parsing the signature. |.
  /// | `invalid` | The signature could not be cryptographically verified using the Key whose key-id was found in the signature. |.
  /// | `valid` | None of the above errors applied, so the signature is considered to be verified. |.
  ///
  /// [owner] - The account owner of the repository. The name is not case sensitive.
  ///
  /// [repo] - The name of the Repository without the `.git` extension. The name is not case sensitive.
  ///
  /// [page] - The Page number of the results to fetch. For more information, see "[Using pagination in the REST API](https://docs.github.com/rest/using-the-rest-api/using-pagination-in-the-rest-api).".
  ///
  /// [perPage] - The number of results per Page (max 100). For more information, see "[Using pagination in the REST API](https://docs.github.com/rest/using-the-rest-api/using-pagination-in-the-rest-api).".
  ///
  /// [ref] - The Commit reference. Can be a Commit SHA, branch name (`heads/BRANCH_NAME`), or Tag name (`tags/TAG_NAME`). For more information, see "[Git References](https://git-scm.com/book/en/v2/Git-Internals-Git-References)" in the Git documentation.
  @GET('/repos/{owner}/{repo}/commits/{ref}')
  Future<Commit> reposGetCommit({
    @Path('owner') required String owner,
    @Path('repo') required String repo,
    @Path('ref') required String ref,
    @Query('Page') int? page = 1,
    @Query('per_page') int? perPage = 30,
  });
}
