import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'connection_profile.dart';
import 'connection_store.dart';

part 'active_connection_profile_provider.g.dart';

@Riverpod(keepAlive: true)
class ActiveConnectionProfile extends _$ActiveConnectionProfile {
  @override
  Future<ConnectionProfile> build(ConnectionStore store) async {
    final snapshot = store.load();
    return snapshot.profiles.firstWhere(
      (profile) => profile.id == snapshot.activeId,
    );
  }

  Future<void> select(String profileId) async {
    if (state.isLoading) return;

    final snapshot = store.load();
    final profile = snapshot.profiles.firstWhere(
      (profile) => profile.id == profileId,
    );
    final previous = state;
    state = const AsyncLoading();
    try {
      await store.save(snapshot.copyWith(activeId: profile.id));
      if (ref.mounted) state = AsyncData(profile);
    } catch (_) {
      if (ref.mounted) state = previous;
      rethrow;
    }
  }
}
