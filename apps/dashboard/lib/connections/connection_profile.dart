import 'package:freezed_annotation/freezed_annotation.dart';

import '../firebase/firebase_config_provider.dart';

part 'connection_profile.freezed.dart';
part 'connection_profile.g.dart';

@freezed
abstract class ConnectionProfile with _$ConnectionProfile {
  const ConnectionProfile._();

  // ignore: invalid_annotation_target
  @JsonSerializable(explicitToJson: true)
  const factory ConnectionProfile({
    required String id,
    required String name,
    required String apiUrl,
    required Map<String, SelfHostedConfig> firebase,
  }) = _ConnectionProfile;

  bool get isCloud => id == 'cloud';

  factory ConnectionProfile.fromJson(Map<String, dynamic> json) =>
      _$ConnectionProfileFromJson(json);
}
