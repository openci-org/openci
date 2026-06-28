import 'dart:convert';

import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/firebase/firestore.dart';
import 'package:dashboard/firebase/functions.dart';
import 'package:dashboard/openci_server_url_provider.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'github_repository_provider.freezed.dart';
part 'github_repository_provider.g.dart';

@freezed
abstract class GitHubRepo with _$GitHubRepo {
  const factory GitHubRepo({
    required String fullName,
    required String name,
    required String owner,
    required bool private,
    required String defaultBranch,
  }) = _GitHubRepo;

  factory GitHubRepo.fromJson(Map<String, Object?> json) =>
      _$GitHubRepoFromJson(json);
}

@riverpod
Future<List<GitHubRepo>> gitHubRepositories(Ref ref) async {
  final team = ref.watch(teamStateProvider).value;
  if (team == null) return [];

  final serverUrl = ref.watch(openciServerUrlProvider);
  final token = await ref.watch(authedFirebaseIdTokenProvider.future);

  final url = Uri.parse('$serverUrl/teams/${team.id}/github/repositories');
  final response = await http
      .get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      )
      .timeout(const Duration(seconds: 15));

  if (response.statusCode != 200) {
    throw StateError(
      'Failed to load repositories: ${response.statusCode} ${response.body}',
    );
  }

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final repos = (data['repositories'] as List<dynamic>?)
      ?.map(
        (e) => GitHubRepo.fromJson(Map<String, Object?>.from(e as Map)),
      )
      .toList();

  return repos ?? const [];
}

@riverpod
Stream<List<String>> gitHubBranches(Ref ref, String repoFullName) {
  final team = ref.watch(teamStateProvider).value;
  if (team == null) return Stream.value(const []);

  final repositoryId = repoFullName.replaceAll('/', ':');
  final docRef = firestore
      .collection(teamsCollection)
      .doc(team.id)
      .collection('repositories_v0')
      .doc(repositoryId);

  return docRef.snapshots().asyncMap((snapshot) async {
    if (!snapshot.exists) {
      final functions = firebaseFunctions;
      try {
        await functions.httpsCallable('listBranches').call({
          'teamId': team.id,
          'repository': repoFullName,
        });
      } catch (_) {
        // Ignore initialization error since it will be retried or shown as error
      }
      return const [];
    }

    final data = snapshot.data();
    if (data == null) return const [];
    final branches = (data['branches'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList();
    return branches ?? const [];
  });
}
