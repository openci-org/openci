import 'package:freezed_annotation/freezed_annotation.dart';

import '../utilities/date_time_converter.dart';

part 'team.freezed.dart';
part 'team.g.dart';

@freezed
abstract class Team with _$Team {
  const factory Team({
    required String id,
    required String name,
    required List<String> members,
    @Default([]) List<int> installationIds,
    @Default(1) int runNumber,
    @Default(true) bool aiEnabled,
    String? githubBaseUrl,
    @DateTimeConverter() required DateTime createdAt,
    @DateTimeConverter() required DateTime updatedAt,
  }) = _Team;

  factory Team.fromJson(Map<String, Object?> json) => _$TeamFromJson(json);
}
