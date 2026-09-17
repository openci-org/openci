import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'connection_profile.dart';
import 'connection_snapshot.dart';

class ConnectionStore {
  ConnectionStore(this.prefs, this.cloud);

  final SharedPreferences prefs;
  final ConnectionProfile cloud;
  static const storageKey = 'connection_profiles_v1';

  ConnectionSnapshot load() {
    final raw = prefs.getString(storageKey);
    if (raw == null) {
      return ConnectionSnapshot(profiles: [cloud], activeId: cloud.id);
    }

    final data = jsonDecode(raw) as Map<String, dynamic>;
    final profiles = (data['profiles'] as List<dynamic>)
        .map((json) => ConnectionProfile.fromJson(json as Map<String, dynamic>))
        .where((profile) => !profile.isCloud);
    return ConnectionSnapshot(
      profiles: [cloud, ...profiles],
      activeId: data['activeId'] as String,
    );
  }

  Future<void> save(ConnectionSnapshot snapshot) async {
    final json = jsonEncode({
      'activeId': snapshot.activeId,
      'profiles': snapshot.profiles
          .where((profile) => !profile.isCloud)
          .map((profile) => profile.toJson())
          .toList(),
    });
    if (!await prefs.setString(storageKey, json)) {
      throw StateError('接続設定を保存できませんでした。');
    }
  }
}
