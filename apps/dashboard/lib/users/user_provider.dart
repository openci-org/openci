import 'dart:async';

import 'package:dashboard/api/openci_api_client.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openci_shared/openci_shared.dart';
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
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) {
      yield const [];
      return;
    }

    yield await _fetchDevices();

    yield* Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
      return _fetchDevices();
    });
  }

  Future<List<UserDevice>> _fetchDevices() async {
    try {
      final apiService = ref.read(openciApiServiceProvider);
      final response = await apiService.getDevices();

      if (!response.isSuccessful) return const [];

      return response.body ?? const [];
    } catch (e) {
      return const [];
    }
  }
}
