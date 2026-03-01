import 'package:dashboard/users/user_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_provider.g.dart';

@riverpod
class NotificationService extends _$NotificationService {
  @override
  Future<void> build() async => initializeNotifications();

  Future<bool> requestPermission() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  Future<void> registerFcmToken() async {
    try {
      final messaging = FirebaseMessaging.instance;

      String? apnsToken;
      for (var i = 0; i < 5; i++) {
        apnsToken = await messaging.getAPNSToken();
        if (apnsToken != null) break;
        await Future.delayed(const Duration(seconds: 1));
        if (!ref.mounted) return;
      }

      if (apnsToken == null) {
        debugPrint('[FCM] APNS token not available, skipping FCM registration');
        return;
      }

      final token = await messaging.getToken();
      if (!ref.mounted) return;
      if (token != null) {
        final userNotifier = ref.read(userProvider.notifier);
        await userNotifier.addFcmToken(token);
        debugPrint('[FCM] Token registered: ${token.substring(0, 10)}...');
      } else {
        debugPrint('[FCM] FCM token is null');
      }

      messaging.onTokenRefresh.listen((newToken) async {
        if (!ref.mounted) return;
        final userNotifier = ref.read(userProvider.notifier);
        await userNotifier.addFcmToken(newToken);
        debugPrint(
          '[FCM] Token refreshed: ${newToken.substring(0, 10)}...',
        );
      });
    } catch (e) {
      debugPrint('[FCM] Error registering token: $e');
    }
  }

  Future<void> initializeNotifications() async {
    final messaging = FirebaseMessaging.instance;

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final granted = await requestPermission();
    if (!ref.mounted) return;
    if (granted) {
      await registerFcmToken();
    }

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint(
        '[FCM] Foreground message: ${message.notification?.title}',
      );
    });
  }
}
