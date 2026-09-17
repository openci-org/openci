import 'package:freezed_annotation/freezed_annotation.dart';

import 'connection_profile.dart';

part 'connection_snapshot.freezed.dart';

@freezed
abstract class ConnectionSnapshot with _$ConnectionSnapshot {
  const factory ConnectionSnapshot({
    required List<ConnectionProfile> profiles,
    required String activeId,
  }) = _ConnectionSnapshot;
}
