import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'user_service.dart';

/// Top-level FCM background handler — must be top-level (Firebase requirement).
/// The system renders the notification automatically; nothing extra needed here.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage _) async {}

class NotificationService {
  final FirebaseMessaging _fcm;
  final UserService _userService;

  NotificationService({FirebaseMessaging? fcm, UserService? userService})
      : _fcm = fcm ?? FirebaseMessaging.instance,
        _userService = userService ?? UserService();

  /// Call once after Firebase.initializeApp().
  /// Requests permission, saves the FCM token + timezone to Firestore, and
  /// wires foreground message display and notification-tap handling.
  ///
  /// [onNotificationTap] is called with the Firestore messageId whenever the
  /// user taps a notification while the app is in background (not terminated).
  /// Terminated-state taps are handled in main() via getInitialMessage().
  Future<void> initialize({
    required String uid,
    required BuildContext context,
    void Function(String messageId)? onNotificationTap,
  }) async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Request OS notification permission (shows dialog on Android 13+).
    await _fcm.requestPermission(alert: true, badge: false, sound: true);

    // Save token + timezone so the Cloud Function knows how to reach this user.
    await _saveTokenAndTimezone(uid);

    // Refresh token if FCM rotates it (rare, but must be handled).
    _fcm.onTokenRefresh.listen(
      (token) => _userService.saveToken(
        uid,
        token,
        DateTime.now().timeZoneOffset.inMinutes,
      ),
    );

    // When app is in foreground, show the message as a SnackBar banner.
    FirebaseMessaging.onMessage.listen((message) {
      final notif = message.notification;
      if (notif == null) return;
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            notif.body ?? notif.title ?? '',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });

    // When app is in background and user taps the notification.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final msgId = message.data['messageId'] as String?;
      if (msgId != null) onNotificationTap?.call(msgId);
    });
  }

  Future<void> _saveTokenAndTimezone(String uid) async {
    final token = await _fcm.getToken();
    if (token == null) return;
    await _userService.saveToken(
      uid,
      token,
      DateTime.now().timeZoneOffset.inMinutes,
    );
  }
}
