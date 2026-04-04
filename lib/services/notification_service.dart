import 'package:firebase_messaging/firebase_messaging.dart';

/// Handles push notifications via Firebase Cloud Messaging.
/// Free users subscribe to 'morning'; premium users subscribe to all three slots.
class NotificationService {
  final FirebaseMessaging _fcm;

  NotificationService({FirebaseMessaging? fcm})
      : _fcm = fcm ?? FirebaseMessaging.instance;

  static const List<String> allSlots = ['morning', 'afternoon', 'evening'];

  /// Requests OS-level notification permission. Returns true if granted.
  Future<bool> requestPermission() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Returns the FCM registration token for this device.
  Future<String?> getToken() => _fcm.getToken();

  /// Subscribes to a time-slot topic so the device receives that slot's push.
  Future<void> subscribeToSlot(String slot) =>
      _fcm.subscribeToTopic(slot);

  /// Unsubscribes from a time-slot topic.
  Future<void> unsubscribeFromSlot(String slot) =>
      _fcm.unsubscribeFromTopic(slot);

  /// Convenience: subscribe to all 3 slots (premium).
  Future<void> subscribeToAll() async {
    for (final slot in allSlots) {
      await subscribeToSlot(slot);
    }
  }

  /// Convenience: downgrade to morning-only (free tier).
  Future<void> downgradeToFree() async {
    await subscribeToSlot('morning');
    for (final slot in ['afternoon', 'evening']) {
      await unsubscribeFromSlot(slot);
    }
  }

  /// Listen for foreground messages and invoke [onMessage].
  void onForegroundMessage(void Function(RemoteMessage) onMessage) {
    FirebaseMessaging.onMessage.listen(onMessage);
  }

  /// Listen for notification-tap when app is in background.
  void onNotificationTap(void Function(RemoteMessage) onTap) {
    FirebaseMessaging.onMessageOpenedApp.listen(onTap);
  }
}
