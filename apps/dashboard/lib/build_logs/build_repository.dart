import 'dart:convert';

import 'package:openci_shared/openci_shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../generated/builds/builds.dart';
import 'builds_connector_provider.dart';

part 'build_repository.g.dart';

abstract interface class BuildRepository {
  Stream<BuildJob?> watchJob(String id);
  Stream<List<BuildJob>> watchJobs(String teamId);
}

@riverpod
Future<BuildRepository> buildRepository(Ref ref) async =>
    FscBuildRepository(await ref.watch(buildsConnectorProvider.future));

class FscBuildRepository implements BuildRepository {
  FscBuildRepository(this.connector);
  final BuildsConnector connector;

  @override
  Stream<BuildJob?> watchJob(String id) =>
      connector.getBuildJob(id: id).ref().subscribe().map((result) {
        final job = result.data.job;
        return job == null ? null : buildJobFromFsc(job.toJson());
      });

  @override
  Stream<List<BuildJob>> watchJobs(String teamId) => connector
      .getBuildJobs(teamId: teamId)
      .limit(100)
      .ref()
      .subscribe()
      .map(
        (result) => result.data.buildJobs
            .map((job) => buildJobFromFsc(job.toJson()))
            .toList(),
      );
}

// FSC preserves the legacy database's Unix seconds and JSON-encoded columns.
BuildJob buildJobFromFsc(Map<String, dynamic> data) {
  final json = Map<String, dynamic>.from(data);
  for (final field in ['createdAt', 'updatedAt', 'completedAt']) {
    if (json[field] != null) {
      json[field] = DateTime.fromMillisecondsSinceEpoch(
        int.parse('${json[field]}') * 1000,
        isUtc: true,
      ).toIso8601String();
    }
  }
  for (final field in ['runCount', 'pullRequestNumber']) {
    if (json[field] != null) json[field] = int.parse('${json[field]}');
  }
  for (final field in ['matrix', 'needs']) {
    if (json[field] != null) json[field] = jsonDecode(json[field] as String);
  }
  return BuildJob.fromJson(json);
}
