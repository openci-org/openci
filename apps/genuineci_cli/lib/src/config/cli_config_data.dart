import 'package:freezed_annotation/freezed_annotation.dart';

part 'cli_config_data.freezed.dart';
part 'cli_config_data.g.dart';

@freezed
abstract class CliConfigData with _$CliConfigData {
  const factory CliConfigData({String? language}) = _CliConfigData;

  factory CliConfigData.fromJson(Map<String, dynamic> json) =>
      _$CliConfigDataFromJson(json);
}
