import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'models/daily_w_message.dart';
import 'models/user_profile.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/message_service.dart';
import 'services/notification_service.dart';
import 'services/purchase_service.dart';
import 'services/user_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register background FCM handler as early as possible.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final userService = UserService();
  final messageService = MessageService();

  // Auth + profile load happens before runApp — native splash covers this.
  final profile = await userService.signInAndLoad();

  // Initialize RevenueCat with the Firebase UID so purchases are user-scoped.
  await PurchaseService.initialize(profile.uid);

  // Check if the app was cold-started from a notification tap.
  // If so, show the message that was in that specific notification.
  DailyWMessage? message;
  if (profile.onboardingComplete) {
    final initialFcmMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    final notifMessageId =
        initialFcmMessage?.data['messageId'] as String?;

    if (notifMessageId != null) {
      // Fetch the exact message the user tapped on.
      message = await messageService
          .getMessageById(notifMessageId)
          .catchError((_) => null);
    }

    // Fallback: show today's current-slot message.
    message ??= await messageService
        .getOrAssignTodaysMessage(MessageService.getCurrentSlot(), profile.uid)
        .catchError((_) => null);
  }

  runApp(DailyWApp(profile: profile, initialMessage: message));
}

class DailyWApp extends StatelessWidget {
  final UserProfile profile;
  final DailyWMessage? initialMessage;

  const DailyWApp({
    super.key,
    required this.profile,
    this.initialMessage,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily W',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: profile.onboardingComplete
          ? HomeScreen(initialProfile: profile, preloadedMessage: initialMessage)
          : OnboardingScreen(profile: profile),
    );
  }
}
