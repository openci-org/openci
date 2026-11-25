import 'package:json_annotation/json_annotation.dart';

part 'job_summary.g.dart';

@JsonSerializable(
  fieldRename: FieldRename.snake,
  includeIfNull: false,
  createFieldMap: true,
)
class JobSummary {
  const JobSummary({
    required this.id,
    required this.workflowName,
    required this.status,
    this.commitSha,
    this.matrixLabel,
    this.latestRunId,
    this.retryCount,
    this.recentRuns,
  });

  @JsonKey(name: 'job_id')
  final String id;
  @JsonKey(name: 'workflow')
  final String workflowName;
  final String status;
  @JsonKey(includeIfNull: true)
  final String? commitSha;
  final String? matrixLabel;
  final String? latestRunId;
  @JsonKey(fromJson: _readRetryCount)
  final int? retryCount;
  @JsonKey(fromJson: _readRecentRuns)
  final List<Object?>? recentRuns;

  factory JobSummary.fromJson(Map<String, dynamic> json) =>
      _$JobSummaryFromJson(json);

  // GetBuildJobs returns rows keyed by the Dart field names.
  factory JobSummary.fromTeamJob(Map<String, dynamic> row) =>
      JobSummary.fromJson({
        for (final field in _$JobSummaryFieldMap.entries)
          field.value: row[field.key],
      });

  Map<String, dynamic> toJson() => _$JobSummaryToJson(this);

  static int? _readRetryCount(Object? value) =>
      value is int && value >= 0 ? value : null;

  static List<Object?>? _readRecentRuns(Object? value) =>
      value is List<Object?> && value.length > 1 ? value : null;
}
