import 'dart:async';
import 'dart:convert';

import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/openci_server_url_provider.dart';
import 'package:dashboard/users/user_device.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_provider.freezed.dart';
part 'user_provider.g.dart';

@freezed
abstract class OpenCIUser with _$OpenCIUser {
  const factory OpenCIUser({
    required String id,
  }) = _OpenCIUser;

  const OpenCIUser._();

  factory OpenCIUser.fromJson(Map<String, Object?> json) =>
      _$OpenCIUserFromJson(json);
}

@Riverpod(keepAlive: true)
class User extends _$User {
  @override
  Stream<OpenCIUser> build() async* {
    final currentUserId = ref.watch(currentUserIdProvider);
    if (currentUserId == null) return;

    yield OpenCIUser(id: currentUserId);
  }
}

@riverpod
class UserDevices extends _$UserDevices {
  @override
  Stream<List<UserDevice>> build() async* {
    final serverUrl = ref.watch(openciServerUrlProvider);
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) {
      yield const [];
      return;
    }

    final token = await ref.watch(authedFirebaseIdTokenProvider.future);

    yield await _fetchDevices(serverUrl, token);

    yield* Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
      final token = await ref.read(authedFirebaseIdTokenProvider.future);
      return _fetchDevices(serverUrl, token);
    });
  }

  Future<List<UserDevice>> _fetchDevices(
    String serverUrl,
    String token,
  ) async {
    try {
      final url = Uri.parse('$serverUrl/devices');

      final response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return const [];

      final list = jsonDecode(response.body) as List<dynamic>;

      return list.map((item) {
        return UserDevice.fromJson(Map<String, dynamic>.from(item as Map));
      }).toList();
    } catch (e) {
      return const [];
    }
  }
}
