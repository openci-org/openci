import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_check_models.freezed.dart';
part 'update_check_models.g.dart';

@freezed
abstract class UpdateCheckState with _$UpdateCheckState {
  const factory UpdateCheckState({
    LatestBuildInfo? latest,
    @Default(false) bool isUpdateAvailable,
  }) = _UpdateCheckState;
}

@freezed
abstract class LatestBuildInfo with _$LatestBuildInfo {
  const factory LatestBuildInfo({
    @Default('') String version,
    @Default('') String sha,
    DateTime? updatedAt,
  }) = _LatestBuildInfo;

  factory LatestBuildInfo.fromJson(Map<String, dynamic> json) =>
      _$LatestBuildInfoFromJson(json);
}
